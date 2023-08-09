module DRAMagent #(
  parameter DATA_WIDTH = 512,
  parameter NUM_WORDS = 268435456,
  parameter MAX_BURST = 32) (
  input wire clk,
  input wire reset, 
  input wire start, 
  input wire start_ff,
  output logic done,

  input logic result_ready,
  input logic [27 : 0] mat_address0, mat_address1, mat_res_address,
  input logic [27 : 0] mat_mem_len,
  input logic[DATA_WIDTH-1:0]    data_sum,
  output logic [DATA_WIDTH-1:0]  read_data0, read_data1,
  output logic read_data_ready,

  input logic [27:0] burst_setting,

  output logic [27 : 0] address,
  output logic  read,
  output logic  write,
  output logic [DATA_WIDTH - 1 : 0]  writedata,
  output logic [6:0]  burstcount,

  input wire [DATA_WIDTH - 1 : 0]  readdata,
  input wire  waitrequest,
  input wire  readdatavalid

);
  
  logic [31:0] count_read_req, count_read_valid;
  logic mat_to_read;
  logic mat_been_read;
  
  logic write_req, read_req, stop;
  logic stop0, stop1;

  logic [27 : 0] read_address0, read_address1, write_address, end_address, end_address0, end_address1; 
  assign end_address = mat_res_address + mat_mem_len;
  assign end_address0 = mat_address0 + mat_mem_len;
  assign end_address1 = mat_address1 + mat_mem_len;

  logic sending_read;
  logic [7:0] max_entries, expected_entries;
  assign max_entries = 8'd192;

  logic enq,deq,empty, full, fifo_clr, block_deq;
  logic [DATA_WIDTH-1:0] data_in,data_out;
  logic assert_write;
  logic [7:0] fifo_amount;

  assign fifo_clr = reset || start;
  
  write_buffer_fifo write_buffer (
		.data  (data_in),              //   input,  width = 512,  fifo_input.datain
		.wrreq (enq),                  //   input,    width = 1,            .wrreq
		.rdreq (deq),                  //   input,    width = 1,            .rdreq
		.clock (clk),                  //   input,    width = 1,            .clk
		.sclr  (fifo_clr),             //   input,    width = 1,            .sclr
		.q     (data_out),             //  output,  width = 512, fifo_output.dataout
		.usedw (fifo_amount),          //  output,    width = 8,            .usedw
		.full  (full),                 //  output,    width = 1,            .full
		.empty (empty)                 //  output,    width = 1,            .empty
	);
  assign data_in = data_sum;

  always_ff @(posedge clk) begin
    if (reset || start)begin
      enq <= 0;
      block_deq <= 0;
      
    end else begin
      if (readdatavalid && (mat_been_read == 1)) begin
        enq <= 1;
        
      end else begin
        enq <= 0;
      end
      // deque after enque OR finish off left over writes  
      block_deq <= (write && waitrequest);
    end 
  end

  
  assign deq = (!block_deq) && (!sending_read) && (!empty);

  logic [511:0] data_to_write, write_buffer_out_delay;
  
  always_ff @(posedge clk) begin 
    if (reset || start) begin
      write_buffer_out_delay <= 'h0;
    end else if (deq) begin
      write_buffer_out_delay <= data_out;
    end
  end

  //assign data_to_write = (deq) ? data_out : write_buffer_out_delay;
  assign data_to_write = (hold_write) ? write_buffer_out_delay : data_out;
  
  logic hold_write;
  always_ff @(posedge clk) begin
    if (reset || start) begin
      hold_write <= 0;
    end else if (deq && (write && waitrequest)) begin 
      hold_write <= 1;
    end else if (write_req) begin
      hold_write <= 0;
    end
  end

  assign assert_write = deq || hold_write;
  

  
  always_ff @(posedge clk) begin
    if (reset || start)begin
      read_address0 <= mat_address0;
      read_address1 <= mat_address1;
      write_address <= mat_res_address;
      
    end 
    /*
    else if (write_req) begin
      if (read_address0 <= end_address0) begin
        read_address0 <= read_address0 + 'h1;
        read_address1 <= read_address1 + 'h1;
        write_address <= write_address + 'h1;
      end
    end*/

    else if (read_req && !write) begin
      if (mat_to_read == 0) begin
        read_address0 <= read_address0 + burst_setting;
      end else begin
        read_address1 <= read_address1 + burst_setting;
      end
    end else if (write_req) begin
      write_address <= write_address + 'h1;
    end 
  end

  

  // valid read request when read is asserted and waitrequest deasserted 
  assign read_req =  read && ! waitrequest;

  // counter read requests
  always_ff @(posedge clk) begin 
    if (reset || start) begin
      count_read_req <= 0;
      mat_to_read <= 0;
    end
    else if (read_req && !write) begin
      count_read_req <= count_read_req + 2'b01; 
      mat_to_read <= ~mat_to_read;
    end
  end 

  
  logic [6:0] burst_buffer_rdaddr, burst_buffer_wtaddr;
  logic burst_buffer_write;
  logic [511:0] burst_buffer_in, burst_buffer_out;
  
  //assign burst_setting = 'h4;
  read_buffer burst_buffer(.data_in(burst_buffer_in),
                           .write_en(burst_buffer_write),
                           .write_addr(burst_buffer_wtaddr),
                           .read_addr(burst_buffer_rdaddr),
                           .data_out(burst_buffer_out),
                           .clk(clk));

  assign burst_buffer_write = readdatavalid && (mat_been_read == 0);
  assign burst_buffer_in = readdata;

  // count readdatavalids
    always_ff @(posedge clk) begin
    if (reset || start) begin
      burst_buffer_rdaddr <= 0; 
      burst_buffer_wtaddr <= 0;
      mat_been_read <= 0;
      read_data0 <= 0;
      read_data1 <= 0;
      read_data_ready <= 0;
    end else if (readdatavalid) begin
      if (mat_been_read == 0) begin
        if (burst_buffer_wtaddr == burst_setting - 1 )begin
          burst_buffer_wtaddr <= 0;
          mat_been_read <= 1;
        end else begin
          burst_buffer_wtaddr <= burst_buffer_wtaddr + 'h1;
        end
      end else begin  //mat_been_read = 1
        if (burst_buffer_rdaddr == burst_setting - 1 )begin
          burst_buffer_rdaddr <= 0;
          mat_been_read <= 0;
          read_data1 <= readdata;
          read_data0 <= burst_buffer_out;
          //result_ready <= 0;
        end else begin
          burst_buffer_rdaddr <= burst_buffer_rdaddr + 'h1;
          read_data1 <= readdata;
          read_data0 <= burst_buffer_out;
          //result_ready <= 1;
        end
      end
    end 
  end

  // similarly, valid write request when write is asserted and waitrequest deasserted
  assign write_req =  write && ! waitrequest;

  // this module is done after the write request
  always_ff @(posedge clk) begin 
    if ( reset || start) begin
      stop <= 0;
    end else if (write_address >= end_address) begin 
      stop <= 1;
    end 
  end

  always_ff @(posedge clk) begin 
    if ( reset || start) begin
      stop0 <= 0;
    end else if (read_address0 >= end_address0) begin 
      stop0 <= 1;
    end 
  end  

  always_ff @(posedge clk) begin 
    if ( reset || start) begin
      stop1 <= 0;
    end else if (read_address1 >= end_address1) begin 
      stop1 <= 1;
    end 
  end

  /* actual done signal*/
  always_ff @(posedge clk) begin
    if (reset || start)
      done <= 0;
    else if (stop) begin
      if (readdatavalid)
        done <= 1;
    end
  end 
  
  /*
  always_ff @(posedge clk) begin
    if (reset || start) begin 
      sending_read <= 0;
    end else if (start_ff && (expected_entries < max_entries) && (!stop1)) begin
      sending_read <= 1;
    end else begin
      sending_read <= 0;
    end
  end
  */

  assign sending_read = start_ff && (expected_entries < (max_entries)) && (!stop1);

  always_ff @(posedge clk) begin
    if (reset || start) begin
      expected_entries <= 'h0;
    end else if ((mat_to_read == 1) && read_req && !write) begin
      expected_entries <= expected_entries + burst_setting[6:0];
    end else if (write_req) begin
      expected_entries <= expected_entries - 'h1;
    end 
  end
  
  

  // use counter values to assert avalon-mm signals
  always_comb begin 
    burstcount = 0;
    writedata = 0;
    address = 0;
    write = 0;
    read = 0;
    if (start_ff && !start) begin
      if (assert_write && (!stop) && (!done)) begin
        burstcount = 1;
        writedata = data_to_write; // write the sum of a + b
        address = write_address; // address of third word
        write = 1;
        read = 0;
      end 
      else if ((mat_to_read == 0) &&(!done) && (!stop0)) begin 
        burstcount = burst_setting[6:0];
        writedata = 0;
        address = read_address0; // emif is word addressed (512 bits), address of first word
        write = 0;
        read = 1;
      end 
      else if ((mat_to_read == 1) &&(!done) && (!stop1)) begin 
        burstcount = burst_setting[6:0];
        writedata = 0;
        address = read_address1; // address of second word
        write = 0;
        read = 1;
      end else if (stop) begin
        burstcount = 1;
        writedata = 0;
        address = mat_address0;
        write = 0;
        read = 1;
      end 
    end 
  end 

endmodule