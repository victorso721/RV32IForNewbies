`timescale 1ns/1ps

`define HALF_CLOCK_CYCLE 10  //parameter for clock cycle
`define FULL_CLOCK_CYCLE (`HALF_CLOCK_CYCLE + `HALF_CLOCK_CYCLE)

module tb_top;
//----------------simulated input---------------//
//SoC signal
reg                         clk                 ;
reg                         rst_n               ;

//CPU input
reg                         start_pulse         ;
reg [`PC_WIDTH-1:0]         start_pc            ;
reg [`EXCEPTION_NUM-1:0]    core_configuration  ;

//Signal for submodules
//input
reg [`PC_WIDTH-1:0]	    bru_redir_pc	;
reg			    bru_flush		;
reg			    core_running	;
reg			    wen			;
//output
wire [`INST_WIDTH-1:0] imem_ifu_inst_1;
wire [`INST_WIDTH-1:0] imem_ifu_inst_2;

//interconnections
reg	[`PC_WIDTH-1:0]	     arb_res_pc		;
wire [`PC_WIDTH-1:0]	    arb_res_pc_q	;
wire                         sync_start_pulse         ;
wire [`PC_WIDTH-1:0]         sync_start_pc            ;
wire [`EXCEPTION_NUM-1:0]    sync_core_configuration  ;



//reg insterconnections updating
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		arb_res_pc <= 'b0;
	end
	else begin
		arb_res_pc <= arb_res_pc_q;

	end
end
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_ifu_2ff_synchronizer test_synchornizer
(
    //interface list   
    .clk                        (clk),
    .rst_n                      (rst_n),
    .start_pulse                (start_pulse),
    .start_pc                   (start_pc),
    .core_configuration         (core_configuration),
    .sync_start_pulse           (sync_start_pulse),
    .sync_start_pc              (sync_start_pc),
    .sync_core_configuration    (sync_core_configuration)

);

u_ifu_pc_generator test_pc_generator
(
    .start_pulse                (sync_start_pulse),
    .bru_flush                  (bru_flush),
    .start_pc                   (sync_start_pc),
    .bru_redir_pc               (bru_redir_pc),
    .arb_res_pc                 (arb_res_pc),
    .is_pc_unalign              (is_pc_unalign),
    .arb_res_pc_q               (arb_res_pc_q)
);

u_IMem_256X32_2R1W imem(
	.clk		(clk),
	.addr		(arb_res_pc[(`INST_MEM_DEPTH_BIT-1+(`INST_MEM_WIDTH_BIT-3)):(`INST_MEM_WIDTH_BIT-3)]),
	.cen		(core_running),
	.wen		(wen),
	.wr_data	('bz),
	.rd_data_1	(imem_ifu_inst_1),
	.rd_data_2	(imem_ifu_inst_2)
);
//----------------------end----------------------//

//testbench
//-----------------simulation setting------------//
initial clk = 1'b1;      //define starting condition of clock

always #`HALF_CLOCK_CYCLE clk = ~clk;  //flopping clocks with clock cycle

//reset register before testing
initial begin
    rst_n = 1'b0;     
    #3;
    rst_n = 1'b1;
end
//set imem data
initial begin
	for(int i=0; i<`INST_MEM_DEPTH; i++) begin
		imem.mem[i] = i;
	end
end
//modules input value setting
//for submodules including register, be careful with time changing value
initial begin
    //initialize
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
     wen		<=   'b0;
    core_running	<=   'b0;
    #`FULL_CLOCK_CYCLE;
    #`FULL_CLOCK_CYCLE;
    //input comes at falling edge
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b1;
    start_pc            <=   'b10;
    core_configuration  <=   'b01;
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    //input comes at rising edge
    #`FULL_CLOCK_CYCLE;
    start_pulse         <=   'b1;
    start_pc            <=   'b100;
    core_configuration  <=   'b10;
    fork
	repeat (2) begin @(posedge clk); end
    	core_running	<=   'b1;
    join_none
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`HALF_CLOCK_CYCLE;
    //BRU flush intersect sync start pulse
    bru_flush		<=   'b1;
    bru_redir_pc	<=   'b0100_0001;
    #`FULL_CLOCK_CYCLE;
    bru_flush		<=   'b0;
    //BRU flush
    repeat (4) begin #`FULL_CLOCK_CYCLE; end
    bru_flush		<=   'b1;
    bru_redir_pc	<=   'b1111_1111;
    #`FULL_CLOCK_CYCLE;
    bru_flush		<=   'b0;
    repeat (3) begin #`FULL_CLOCK_CYCLE; end
    wen 		<=   'b1;

end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #1000   //run time before calling finish, need to be long enough for all simulation
        $finish;
    end

    initial begin
        //for different modules waveform, change fsdb file name
        $fsdbDumpfile("{wave form name}.fsdb");
        $fsdbDumpvars("+all");
    end
`endif
//----------------------end----------------------//

endmodule
