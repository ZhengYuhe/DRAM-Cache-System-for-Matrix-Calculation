module myModule(
  input clk,
  input reset, 

  // avalon memory mapped master interface
  // EMIF avalon slave is 512 bits wide and word addressed (a word is 512 bits)
  input logic            dram_waitrequest,
  input logic [511:0]    dram_readdata,
  input logic            dram_readdatavalid,
  output  logic [6:0]    dram_burstcount,
  output  logic [511:0]  dram_writedata,
  output  logic [27:0]   dram_address,
  output  logic          dram_write,
  output  logic          dram_read,

  // avalon memory mapped master interface for control registers (CSR)
  output logic           csr_waitrequest,
  output logic [31:0]    csr_readdata,
  output logic           csr_readdatavalid,
  input  logic           csr_burstcount,
  input  logic [31:0]    csr_writedata,
  input  logic [9:0]     csr_address,
  input  logic           csr_write,
  input  logic           csr_read,
  input  logic [3:0]     csr_byteenable


);

  // control status registers (CSR) logic - don't touch
  
  // the following signals define 3 CSR registers 
  // these registers can be read/written by JTAG or this module 
  // this provides a way to communicate between host and FPGA
  
  // note CSR[0] is predefined as a reset signal, so don't use it for any other purpose
  // use CSR[1] for start signal (read-only by FPGA, written by host)
  // use CSR[2] for done signal (read-only by host, written by FPGA)
  
  logic [31 : 0] val_out [0 : 5]; // read a register
  logic [31 : 0] val_in [0 : 5];  // write a value to a register
  logic [5:0] val_en;             // write enable for a register
  
  avalon_if #(.ADDR_WIDTH(10), .DATA_WIDTH(32), .BURST_CNT_WIDTH(1)) jtag_master (.clk(clk), .reset(reset));

  app_csrs csrs();

  csr_mgr #(.DATA_WIDTH(32)) csr (
      .avs        (jtag_master),
      .csrs       (csrs),

      .app_reset  (),
      .val_out    (val_out),

      .val_en (val_en),
      .val_in (val_in)
  );

  always_comb begin 
    csr_waitrequest = jtag_master.waitrequest;
    csr_readdata = jtag_master.readdata;
    csr_readdatavalid = jtag_master.readdatavalid;
    jtag_master.address = csr_address; 
    jtag_master.write = csr_write;
    jtag_master.read = csr_read;
    jtag_master.burstcount = csr_burstcount;
    jtag_master.writedata = csr_writedata;
    jtag_master.byteenable = csr_byteenable;
  end 
  //////////////////////////////////
  
  assign val_in[0] = 0;
  assign val_en[0] = 0;
  assign val_in[1] = 0;
  assign val_en[1] = 0;
  assign val_in[4] = 0;
  assign val_en[4] = 0;
  assign val_in[5] = 0;
  assign val_en[5] = 0;

  // start and done signals

  logic start;
  logic start_ff;
  logic done;
  logic [31:0] count_cycle_msb, count_cycle_lsb;
  logic [27:0] burst_setting;
  logic [10:0] max_entries_d, max_entries;
  logic [31:0] write_buffer_throushold;

  // JTAG sends start signal by writing a 1 to CSR[1] (the signal is cleared after a few cycles, see tcl)
  assign start = val_out[1][0];
  assign write_buffer_throushold  = val_out[4];
  assign burst_setting = val_out[5][27:0];
  assign val_in[2] = done;
  assign val_in[3] = count_cycle_lsb;
  assign val_en[2] = 1;
  assign val_en[3] = 1;
  
  assign max_entries_d = write_buffer_throushold - burst_setting;
  always_ff @(posedge clk) begin
    max_entries <= max_entries_d;
  end


  
  // latch the start signal
  always_ff @(posedge clk) begin 
    if (reset || done)
      start_ff <= 0;
    else if (start)
      start_ff <= 1;
  end 

  always_ff @(posedge clk) begin
    if (reset || start) begin
      count_cycle_lsb <= 0;
      count_cycle_msb <= 0;
    end else if (start_ff && !done) begin
      count_cycle_lsb <= count_cycle_lsb + 'h1;
      if (count_cycle_lsb == 32'hFFFFFFFF)begin
        count_cycle_msb <= count_cycle_msb + 'h1;
      end 
    end
  end

  /*
  logic [5:0] terminate_counter;

  always_ff @(posedge clk) begin
    if (reset || start) begin
      done <= 0;
      terminate_counter <= 0;
    end else begin
      terminate_counter <= terminate_counter + 'h1;
      if (terminate_counter >= 6'b111110) begin
        done <= 1;
      end
    end
  end
  */

  
  



  logic [27 : 0] mat_address0, mat_address1, mat_res_address, mat_mem_len; 
  logic [511 : 0]  read_data0, read_data1,data_sum;
  logic read_data_ready, result_ready;
  //logic dummy_done;

  DRAMagent dramAgent(.address(dram_address),
                      .read(dram_read),
                      .write(dram_write),
                      .writedata(dram_writedata),
                      .burstcount(dram_burstcount),
                      .readdata(dram_readdata),
                      .waitrequest(dram_waitrequest),
                      .readdatavalid(dram_readdatavalid),
                      //.done(dummy_done),
                      .done(done),
                      .*);
                      
  MMA       matrixAdder (.data_A(read_data0), .data_B(read_data1), .*);


/*
  // this module will read a and b from memory and write the result to memory 
  logic [511:0] a, b;

  // this module will send 2 read requests for a and b
  // after sending a read request, the result comes back several cycles after
  logic [1:0] count_read_req, count_read_valid;

  // valid read request when dram_read is asserted and dram_waitrequest deasserted 
  assign read_req = dram_read && !dram_waitrequest;

  // counter read requests
  always_ff @(posedge clk) begin 
    if (reset || start) // notice start signal
      count_read_req <= 0;
    else if (read_req)
      count_read_req <= count_read_req + 2'b01; 
  end 

  // count dram_readdatavalids
  always_ff @(posedge clk) begin 
    if (reset || start)
      count_read_valid <= 0;
    else if (dram_readdatavalid)
      count_read_valid <= count_read_valid + 2'b01; 
  end 

  // store values in a and b 
  always_ff @(posedge clk) begin 
    if (reset || start) begin 
      a <= 0;
      b <= 0;
    end 
    else if (dram_readdatavalid) begin 
      if (count_read_valid == 0)
        a <= dram_readdata;
      else if (count_read_valid == 1)
        b <= dram_readdata;
    end 
  end 

  // similarly, valid write request when dram_write is asserted and dram_waitrequest deasserted
  assign write_req = dram_write && !dram_waitrequest;

  // use counter values to assert avalon-mm signals
  always_comb begin 
    dram_burstcount = 0;
    dram_writedata = 0;
    dram_address = 0;
    dram_write = 0;
    dram_read = 0;
    if (start_ff && !start) begin 
      if (count_read_req == 0) begin 
        dram_burstcount = 1;
        dram_writedata = 0;
        dram_address = 28'h00000000; // emif is word addressed (512 bits), address of first word
        dram_write = 0;
        dram_read = 1;
      end 
      else if (count_read_req == 1) begin 
        dram_burstcount = 1;
        dram_writedata = 0;
        dram_address = 28'h00000001; // address of second word
        dram_write = 0;
        dram_read = 1;
      end 
      else if (count_read_valid == 2 && !done) begin
        dram_burstcount = 1;
        dram_writedata = a + b; // write the sum of a + b
        dram_address = 28'h00000002; // address of third word
        dram_write = 1;
        dram_read = 0;
      end 
    end 
  end 
*/


endmodule