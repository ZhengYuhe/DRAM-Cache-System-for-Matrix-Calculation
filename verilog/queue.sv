module Queue #(parameter DATA_WIDTH = 512, parameter QUEUE_DEPTH = 512)
(
  input wire clk,
  input wire reset,
  input wire start,
  input wire enq,
  input wire deq,
  input logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out,
  output logic empty,
  output logic full
);

  // Internal storage for the queue data
  logic [DATA_WIDTH-1:0] queue [QUEUE_DEPTH-1:0];

  // Internal pointers
  logic [$clog2(QUEUE_DEPTH)-1:0] write_ptr;
  logic [$clog2(QUEUE_DEPTH)-1:0] read_ptr;
  

  // Wire to indicate if the queue is empty or full
  logic [$clog2(QUEUE_DEPTH)-1:0] filled_count;
  assign empty = (filled_count == 0);
  assign full = (filled_count == QUEUE_DEPTH);
  

  // Combinational logic to determine the output data
  
  
  

  // Sequential logic for enqueue and dequeue operations
  always @(posedge clk) begin
    if (reset || start) begin
      write_ptr <= 0;
      read_ptr <= 0;
      data_out <= 0;
    end else begin
      if (enq && !full) begin
        queue[write_ptr] <= data_in;
        if (write_ptr < (QUEUE_DEPTH - 1)) begin
          write_ptr <= write_ptr + 1;
        end else begin
          write_ptr <= 0;
        end
      end

      if (deq && !empty) begin
        data_out <= queue[read_ptr];
        if (read_ptr < (QUEUE_DEPTH - 1)) begin
          read_ptr <= read_ptr + 1;
        end else begin
          read_ptr <= 0;
        end
      end
    end
  end

  // Logic to count the number of filled slots in the queue
  always @(posedge clk) begin
    if (reset || start) begin
      filled_count <= 0;
    end else begin
      if (enq && !deq && !full)
        filled_count <= filled_count + 1;
      else if (!enq && deq && !empty)
        filled_count <= filled_count - 1;
    end
  end

endmodule
