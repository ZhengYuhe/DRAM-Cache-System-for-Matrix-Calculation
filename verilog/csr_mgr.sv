`include "csr_mgr.vh"
`include "platform_if.vh"

//
// Application-independent, generic CSR read and write manager.
//
// The CSR manager implements the required device feature header at
// MMIO address 0, including the AFU ID field.  The AFU ID is passed
// in as a value in the app_csrs SystemVerilog interface parameter.
//

module csr_mgr #(
    parameter DATA_WIDTH = 32
) (
    avalon_if.slave avs,
    app_csrs.csr csrs,

    output  logic                                   app_reset,
    output  logic   [DATA_WIDTH - 1 : 0]            val_out [NUM_LOCAL_CSRS],
    input   wire    [NUM_LOCAL_CSRS - 1 : 0]        val_en,
    input   wire    [DATA_WIDTH - 1 : 0]            val_in  [NUM_LOCAL_CSRS]
);

    localparam NUM_TOTAL_CSRS = NUM_LOCAL_CSRS + NUM_APP_CSRS;
    localparam NUM_BYTES = DATA_WIDTH / 8;

    logic clk, rst_n;

    assign clk      = avs.clk;
    assign rst_n    = ~avs.reset;

//    assign app_reset = avs.reset | (val_out[RESET_CSR][15 : 0] != 0);

    logic [$clog2(NUM_TOTAL_CSRS) - 1 : 0] reg_address;
    logic [$clog2(NUM_APP_CSRS) - 1 : 0] app_address;
    logic [$clog2(NUM_LOCAL_CSRS) - 1 : 0] local_address;
    logic [DATA_WIDTH - 1 : 0] mask;

    logic [DATA_WIDTH - 1 : 0]  val_app_out     [NUM_APP_CSRS];
    logic [DATA_WIDTH - 1 : 0]  val_app_next    [NUM_APP_CSRS];
    logic [DATA_WIDTH - 1 : 0]  val_next        [NUM_LOCAL_CSRS];

    logic [DATA_WIDTH - 1 : 0]  readdatanext;
    logic           readdatavalidnext;

    assign reg_address      = avs.address[$clog2(NUM_TOTAL_CSRS * 8) - 1 : $clog2(NUM_BYTES)];
    assign local_address    = reg_address >= NUM_LOCAL_CSRS ? 'x : reg_address;
    assign app_address      = reg_address < NUM_LOCAL_CSRS ? 'x : (reg_address - NUM_LOCAL_CSRS);

    logic local_access, app_access;

    assign local_access = reg_address < NUM_LOCAL_CSRS;
    assign app_access   = ((reg_address >= NUM_LOCAL_CSRS) & (reg_address < NUM_TOTAL_CSRS));

    assign avs.waitrequest  = (avs.write & val_en[local_address] & local_access) | ~rst_n;
    assign readdatanext     = avs.read ? (local_access ? val_out[local_address] :
                                            (app_access ? csrs.cpu_rd_csrs[app_address].data : 'x)) : 'x;
    assign readdatavalidnext = avs.read & (local_access | app_access);

    always_ff @(posedge clk) begin
        for (int i = 0; i < NUM_LOCAL_CSRS; i++) begin
            if (rst_n == 1'b0)
                val_out[i] <= '0;
            else
                val_out[i] <= val_next[i];
        end

        for (int i = 0; i < NUM_APP_CSRS; i++) begin
            if (rst_n == 1'b0)
                val_app_out[i] <= '0;
            else
                val_app_out[i] <= val_app_next[i];
        end

        if (rst_n == 1'b0) begin
            avs.readdata <= '0;
            avs.readdatavalid <= 1'b0;
            app_reset <= 1'b1;
        end
        else begin
            avs.readdata <= readdatanext;
            avs.readdatavalid <= readdatavalidnext;
			app_reset <= (val_out[RESET_CSR][15 : 0] != 0);
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_BYTES; i++) begin
            mask[i * 8 +: 8] = avs.byteenable[i] ? 8'b11111111 : 8'b00000000;
        end

        for (int i = 0; i < NUM_LOCAL_CSRS; i++) begin
            val_next[i] = val_out[i];
            if (val_en[i])
                val_next[i] = val_in[i];
            else if (avs.write && local_access && (local_address == i))
                val_next[i] = (val_out[i] & (~mask)) | (avs.writedata & mask);
            else if (i == RESET_CSR)
                val_next[i] = (val_out[i][15 : 0] == '0) ? '0 : (val_out[i][15 : 0] - 1'b1);
        end

        for (int i = 0; i < NUM_APP_CSRS; i++) begin
            val_app_next[i] = val_app_out[i];
            csrs.cpu_wr_csrs[i].en = 1'b0;
            csrs.cpu_wr_csrs[i].data = 'x;
            if (avs.write && app_access && (app_address == i)) begin
                val_app_next[i] = (val_app_out[i] & (~mask)) | (avs.writedata & mask);
                csrs.cpu_wr_csrs[i].data = (val_app_out[i] & (~mask)) | (avs.writedata & mask);
                csrs.cpu_wr_csrs[i].en = 1'b1;
            end
        end
    end

endmodule: csr_mgr
