module read_buffer #(
  parameter DATA_WIDTH = 512,
  parameter BUFFER_SIZE = 128)(
  input wire clk,
  input wire  reset,

  input logic [DATA_WIDTH - 1 :0] data_in,
  input logic write_en,
  input logic [$clog2(BUFFER_SIZE) - 1:0] write_addr, read_addr,
  output logic [DATA_WIDTH - 1 :0] data_out
);

  logic [DATA_WIDTH-1:0] buffer [BUFFER_SIZE-1:0];

  assign data_out = buffer[read_addr];

  always_ff @(posedge clk) begin
    if (write_en) begin
      buffer[write_addr] <= data_in;
    end
  end
endmodule