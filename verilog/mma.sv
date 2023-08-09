module MMA #(
  parameter DATA_WIDTH = 512,
  parameter NUM_WORDS = 268435456,
  parameter MAT_SIZE = 1024 )(
  input wire clk,
  input wire reset,
  input logic read_data_ready,
  input logic [DATA_WIDTH-1:0] data_A, data_B,
  output logic [DATA_WIDTH-1:0] data_sum,
  output logic [$clog2(NUM_WORDS) - 1 : 0] mat_address0, mat_address1, mat_res_address,
  output logic [$clog2(NUM_WORDS) -1 :0] mat_mem_len,
  output logic result_ready
  );
  
  logic [31:0]mat_A [3:0][3:0];
  logic [31:0]mat_B [3:0][3:0];
  logic [31:0]mat_sum [3:0][3:0];

  assign mat_address0 = 'd0;
  assign mat_address1 = 'd65536;
  assign mat_res_address = 'd131072;
  assign result_ready = read_data_ready;
  assign mat_mem_len = 'd65536;
  
  dramWord2Mat word2mat(.A(data_A), .B(data_B), .*);
  matAdder     addMat(.*);
  dramMat2word mat2word(.sum(data_sum), .*);
  
  
endmodule

module dramWord2Mat(
  input logic [511:0] A, B,
  output logic [31:0]mat_A [3:0][3:0],
  output logic [31:0]mat_B [3:0][3:0]);

  genvar i, j;
  generate
    for (i = 0; i < 4; i = i + 1)begin
      for (j = 0; j < 4; j = j + 1) begin
        
        assign mat_A[i][j] = A[(i * 128 + j*32 + 31): (i * 128 + j*32)];
        assign mat_B[i][j] = B[(i * 128 + j*32 + 31): (i * 128 + j*32)];
      end 
    end 
  endgenerate
endmodule

module dramMat2word(
  input logic [31:0] mat_sum [3:0][3:0],
  output logic [511:0]  sum);
  genvar i, j;
  generate
    for (i = 0; i < 4; i = i + 1)begin
      for (j = 0; j < 4; j = j + 1) begin
        assign sum[(i * 128 + j*32 + 31): (i * 128 + j*32)] = mat_sum[i][j];
      end 
    end 
  endgenerate
endmodule

module matAdder(
  input logic [31:0] mat_A [3:0][3:0],
  input logic [31:0] mat_B [3:0][3:0],
  output logic [31:0] mat_sum [3:0][3:0]);

  genvar i, j;
  generate
    for (i = 0; i < 4; i = i + 1)begin
      for (j = 0; j < 4; j = j + 1) begin
        
        assign mat_sum[i][j] = mat_A[i][j] + mat_B[i][j];
        
      end 
    end 
  endgenerate

endmodule