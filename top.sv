module top (
    input 	wire				usr_refclk,

    output  logic               mem_ck,
    output  logic               mem_ck_n,
    output  logic   [16 : 0]    mem_a,
    output  logic               mem_act_n,
    output  logic   [1 : 0]     mem_ba,
    output  logic   [1 : 0]     mem_bg,
    output  logic   [0 : 0]     mem_cke,
    output  logic   [0 : 0]     mem_cs_n,
    output  logic   [0 : 0]     mem_odt,
    output  logic               mem_reset_n,
    output  logic               mem_par,
    input   wire                mem_alert_n,
    inout   wire    [17 : 0]    mem_dqs,
    inout   wire    [17 : 0]    mem_dqs_n,
    inout   wire    [71 : 0]    mem_dq,
    input   wire                oct_rzqin,
    input   wire                mem_ref_clk
);

    logic ninit_done, sys_clk, pll_locked, local_reset_req, jtag_reset, start;
    logic emif_clk;
	logic            dram_waitrequest;
    logic [511:0]    dram_readdata;
    logic            dram_readdatavalid;
    logic [6:0]      dram_burstcount;
    logic [511:0]    dram_writedata;
    logic [27:0]     dram_address;
    logic            dram_write;
    logic            dram_read;
	 
	logic           csr_waitrequest;
    logic [31:0]    csr_readdata;
    logic           csr_readdatavalid;
    logic           csr_burstcount;
    logic [31:0]    csr_writedata;
    logic [9:0]     csr_address;
    logic           csr_write;
    logic           csr_read;
    logic [3:0]     csr_byteenable;
    logic           csr_debugaccess;
  
  
  
  
    reset_release rst_inst (
        .ninit_done(ninit_done)                 //  output,  width = 1, ninit_done.ninit_done
    );

    /*
    usr_pll pll_inst (
        .rst      (ninit_done),     //   input,  width = 1,   reset.reset
        .refclk   (usr_refclk),     //   input,  width = 1,  refclk.clk
        .locked   (pll_locked),     //  output,  width = 1,  locked.export
        .outclk_0 (sys_clk)         //  output,  width = 1, outclk0.clk
    );
    */
    memory_system mem_inst (
        .clk_clk                                                         (),             //   input,   width = 1,                                            clk.clk
        .clock_bridge_0_out_clk_clk                                      (emif_clk),
        .emif_local_reset_combiner_0_local_reset_req_local_reset_req     (local_reset_req),     //   input,   width = 1,    emif_local_reset_combiner_0_local_reset_req.local_reset_req
        .emif_local_reset_combiner_0_local_reset_status_local_reset_done (), 					//  output,   width = 1, emif_local_reset_combiner_0_local_reset_status.local_reset_done
        .emif_s10_0_pll_ref_clk_clk                                      (mem_ref_clk),         //   input,   width = 1,                         emif_s10_0_pll_ref_clk.clk
        .emif_s10_0_oct_oct_rzqin                                        (oct_rzqin),           //   input,   width = 1,                                 emif_s10_0_oct.oct_rzqin
        .emif_s10_0_mem_mem_ck                                           (mem_ck),              //  output,   width = 1,                                 emif_s10_0_mem.mem_ck
        .emif_s10_0_mem_mem_ck_n                                         (mem_ck_n),            //  output,   width = 1,                                               .mem_ck_n
        .emif_s10_0_mem_mem_a                                            (mem_a),               //  output,  width = 17,                                               .mem_a
        .emif_s10_0_mem_mem_act_n                                        (mem_act_n),           //  output,   width = 1,                                               .mem_act_n
        .emif_s10_0_mem_mem_ba                                           (mem_ba),              //  output,   width = 2,                                               .mem_ba
        .emif_s10_0_mem_mem_bg                                           (mem_bg),              //  output,   width = 2,                                               .mem_bg
        .emif_s10_0_mem_mem_cke                                          (mem_cke),             //  output,   width = 1,                                               .mem_cke
        .emif_s10_0_mem_mem_cs_n                                         (mem_cs_n),            //  output,   width = 1,                                               .mem_cs_n
        .emif_s10_0_mem_mem_odt                                          (mem_odt),             //  output,   width = 1,                                               .mem_odt
        .emif_s10_0_mem_mem_reset_n                                      (mem_reset_n),         //  output,   width = 1,                                               .mem_reset_n
        .emif_s10_0_mem_mem_par                                          (mem_par),             //  output,   width = 1,                                               .mem_par
        .emif_s10_0_mem_mem_alert_n                                      (mem_alert_n),         //   input,   width = 1,                                               .mem_alert_n
        .emif_s10_0_mem_mem_dqs                                          (mem_dqs),             //   inout,  width = 18,                                               .mem_dqs
        .emif_s10_0_mem_mem_dqs_n                                        (mem_dqs_n),           //   inout,  width = 18,                                               .mem_dqs_n
        .emif_s10_0_mem_mem_dq                                           (mem_dq),              //   inout,  width = 72,                                               .mem_dq
        .emif_s10_0_status_local_cal_success                             (),                    //  output,   width = 1,                              emif_s10_0_status.local_cal_success
        .emif_s10_0_status_local_cal_fail                                (),                    //  output,   width = 1,                                               .local_cal_fail
        .mm_bridge_0_s0_waitrequest                                      (dram_waitrequest),                                      //  output,   width = 1,                                 mm_bridge_0_s0.waitrequest
        .mm_bridge_0_s0_readdata                                         (dram_readdata),                                         //  output,  width = 32,                                               .readdata
        .mm_bridge_0_s0_readdatavalid                                    (dram_readdatavalid),                                    //  output,   width = 1,                                               .readdatavalid
        .mm_bridge_0_s0_burstcount                                       (dram_burstcount),                                       //   input,   width = 1,                                               .burstcount
        .mm_bridge_0_s0_writedata                                        (dram_writedata),                                        //   input,  width = 32,                                               .writedata
        .mm_bridge_0_s0_address                                          (dram_address),                                          //   input,  width = 32,                                               .address
        .mm_bridge_0_s0_write                                            (dram_write),                                            //   input,   width = 1,                                               .write
        .mm_bridge_0_s0_read                                             (dram_read),                                             //   input,   width = 1,                                               .read
        .mm_bridge_0_s0_byteenable                                       (),                                       //   input,   width = 4,                                               .byteenable
        .mm_bridge_0_s0_debugaccess                                      (),                                      //   input,   width = 1,                                               .debugaccess        
		.reset_controller_0_reset_in0_reset                              (ninit_done),          //   input,   width = 1,                   reset_controller_0_reset_in0.reset
        .reset_controller_0_reset_out_reset                              (),                    //  output,   width = 1,                   reset_controller_0_reset_out.reset
        .reset_controller_0_reset_out_reset_req                          (local_reset_req),     //  output,   width = 1,                                               .reset_req
        .reset_reset                                                     (ninit_done),          //   input,   width = 1,                                          reset.reset
		.reset_bridge_0_out_reset_reset                                  (jtag_reset),                                   //  output,   width = 1,                       reset_bridge_0_out_reset.reset

		.csr_waitrequest                                                 (csr_waitrequest),                                                 //   input,    width = 1,                                            csr.waitrequest
        .csr_readdata                                                    (csr_readdata),                                                    //   input,   width = 32,                                               .readdata
        .csr_readdatavalid                                               (csr_readdatavalid),                                               //   input,    width = 1,                                               .readdatavalid
        .csr_burstcount                                                  (csr_burstcount),                                                  //  output,    width = 1,                                               .burstcount
        .csr_writedata                                                   (csr_writedata),                                                   //  output,   width = 32,                                               .writedata
        .csr_address                                                     (csr_address),                                                     //  output,   width = 10,                                               .address
        .csr_write                                                       (csr_write),                                                       //  output,    width = 1,                                               .write
        .csr_read                                                        (csr_read),                                                        //  output,    width = 1,                                               .read
        .csr_byteenable                                                  (csr_byteenable),                                                  //  output,    width = 4,                                               .byteenable
        .csr_debugaccess                                                 (csr_debugaccess)                                                 //  output,    width = 1,                                               .debugaccess  
    );


 
	myModule myModule_inst (
		.clk(emif_clk),
		.reset(jtag_reset), 
		.dram_waitrequest(dram_waitrequest),
		.dram_readdata(dram_readdata),
		.dram_readdatavalid(dram_readdatavalid),
		.dram_burstcount(dram_burstcount),
		.dram_writedata(dram_writedata),
		.dram_address(dram_address), 
		.dram_write(dram_write),
		.dram_read(dram_read),

		
		.csr_waitrequest(csr_waitrequest),
		.csr_readdata(csr_readdata),
		.csr_readdatavalid(csr_readdatavalid),
		.csr_burstcount(csr_burstcount),
		.csr_writedata(csr_writedata),
		.csr_address(csr_address), 
		.csr_write(csr_write),
		.csr_read(csr_read),
		.csr_byteenable(csr_byteenable)

	);
endmodule
