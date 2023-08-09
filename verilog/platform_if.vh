`ifndef PLATFORM_IF_VH
`define PLATFORM_IF_VH

interface avalon_if #(
    parameter ADDR_WIDTH = 11,
    parameter DATA_WIDTH = 64,
    parameter BURST_CNT_WIDTH = 1
    ) (
    input  wire clk,
    input  wire reset
    );

    // A hack to work around compilers complaining of circular dependence
    // incorrectly when trying to make a new ofs_plat_local_mem_if from an
    // existing one's parameters.
    localparam ADDR_WIDTH_ = $bits(logic [ADDR_WIDTH:0]) - 1;
    localparam DATA_WIDTH_ = $bits(logic [DATA_WIDTH:0]) - 1;
    localparam BURST_CNT_WIDTH_ = $bits(logic [BURST_CNT_WIDTH:0]) - 1;

    // Number of bytes in a data line
    localparam DATA_N_BYTES = (DATA_WIDTH + 7) / 8;

    // Signals
    logic                       waitrequest;
    logic [DATA_WIDTH-1:0]      readdata;
    logic                       readdatavalid;

    logic [ADDR_WIDTH-1:0]      address;
    logic                       write;
    logic                       read;
    logic [BURST_CNT_WIDTH-1:0] burstcount;
    logic [DATA_WIDTH-1:0]      writedata;
    logic [DATA_N_BYTES-1:0]    byteenable;

    //
    // Master connection
    //
    modport master (
        input  clk,
        input  reset,

        input  waitrequest,
        input  readdata,
        input  readdatavalid,

        output address,
        output write,
        output read,
        output burstcount,
        output writedata,
        output byteenable
    );


    //
    // Slave connection
    //
    modport slave (
        input  clk,
        input  reset,

        output waitrequest,
        output readdata,
        output readdatavalid,

        input  address,
        input  write,
        input  read,
        input  burstcount,
        input  writedata,
        input  byteenable,

        import task read_data(),
        import task write_data()
    );


    //
    // Monitoring port -- all signals are input
    //
    modport monitor (
        input  clk,
        input  reset,

        input  waitrequest,
        input  readdata,
        input  readdatavalid,

        input  burstcount,
        input  writedata,
        input  address,
        input  write,
        input  read,
        input  byteenable
    );

    // synthesis translate_off
    task write_data (
        input [DATA_WIDTH-1:0] data,
        input [ADDR_WIDTH-1:0] wraddress,
        input [DATA_N_BYTES-1:0] byteenable_in = '1
    );
        // wait(read == 1'b0);
        // wait(write == 1'b0);

        writedata = data;
        address = wraddress;
        read = 1'b0;
        byteenable = byteenable_in;
        write = 1'b1;

        @(posedge clk);
        wait(waitrequest == 1'b0);
        @(posedge clk);
        write = 1'b0;
    endtask

    task read_data (
        output [DATA_WIDTH-1:0] data,
        input [ADDR_WIDTH-1:0] rdaddress
    );
        if(read == 1'b1)
            @(posedge readdatavalid);
        // wait(write == 1'b0);

        address = rdaddress;
        write = 1'b0;
        byteenable = '1;

        read = 1'b1;
        wait(waitrequest == 1'b0);

        @(posedge clk);
        read = 1'b0;

        @(posedge readdatavalid);
        @(negedge clk);
        // $display("###################################################################################");
        // $display("%d", readdata);
        // $display("###################################################################################");
        data = readdata;
    endtask
    // synthesis translate_on

endinterface // avalon_if

`endif // PLATFORM_IF_VH
