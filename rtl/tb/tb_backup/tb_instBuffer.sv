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
reg			    ifu_idu_pipe_vld	;
reg [1:0]		    dispatch_vld_q	;
reg			dispatcher_detect_exceptions_wfi;
reg [`INST_WIDTH-1:0]		ifu_idu_inst [1:0];
reg [`PC_WIDTH-1:0]		ifu_idu_pc [1:0];
reg [1:0]			ifu_idu_pc_unalign;
//output
wire [`INST_WIDTH-1:0] imem_ifu_inst_1;
wire [`INST_WIDTH-1:0] imem_ifu_inst_2;
wire [1:0]		instBuffer_dispatcher_inst_vld;
wire [`INST_WIDTH-1:0]	instBuffer_instDecode_inst [1:0];
wire [`PC_WIDTH-1:0]	instBuffer_dispatcher_pc [1:0];
wire [1:0]		instBuffer_dispatcher_unalign_pc ;
//interconnections
reg	[`PC_WIDTH-1:0]	     arb_res_pc		;
wire [`PC_WIDTH-1:0]	    arb_res_pc_q	;
wire                         sync_start_pulse         ;
wire [`PC_WIDTH-1:0]         sync_start_pc            ;
wire [`EXCEPTION_NUM-1:0]    sync_core_configuration  ;
wire			     idu_ifu_instBuffer_full;
/*
idu_ifu_detect_exceptions_wfi
iex_ifu_report_exceptions_wfi
core_status
core_status[0] = core_running;
*/
//reg insterconnections updating

//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_idu_instBuffer instBuffer_test (

	//SoC control input
	.clk									(clk),
	.rst_n									(rst_n),
	//IFU control input
	.ifu_idu_fetch_vld						(ifu_idu_pipe_vld),
	//IFU control output
	.idu_ifu_instBuffer_full				(idu_ifu_instBuffer_full),
	//IDU control input
	.dispatch_vld_0							(dispatch_vld_q[0]),
	.dispatch_vld_1							(dispatch_vld_q[1]),
	.dispatcher_detect_exceptions_wfi		(dispatcher_detect_exceptions_wfi),
	.bru_flush							(bru_flush),

	//IDU control output
	.instBuffer_inst_vld_0				(instBuffer_dispatcher_inst_vld[0]),
	.instBuffer_inst_vld_1				(instBuffer_dispatcher_inst_vld[1]),

	//IFU data input
	.inst_in_0								(ifu_idu_inst[0]),
	.inst_in_1								(ifu_idu_inst[1]),
	.pc_in_0								(ifu_idu_pc[0]),
	.pc_in_1								(ifu_idu_pc[1]),
	.unalign_pc_in_0						(ifu_idu_pc_unalign[0]),
	.unalign_pc_in_1						(ifu_idu_pc_unalign[1]),

	//IDU data output
	.inst_out_0						(instBuffer_instDecode_inst[0]),
	.inst_out_1						(instBuffer_instDecode_inst[1]),
	.pc_out_0						(instBuffer_dispatcher_pc[0]),
	.pc_out_1						(instBuffer_dispatcher_pc[1]),
	.unalign_pc_out_0				(instBuffer_dispatcher_unalign_pc[0]),
	.unalign_pc_out_1				(instBuffer_dispatcher_unalign_pc[1])


);
/*
u_ifu ifu(
	.clk							(clk),
	.rst_n							(rst_n),
	.start_pulse					(start_pulse),
	.start_pc						(start_pc),
	.core_configuration				(core_configuration),	
	.core_status					(core_status),
	.idu_ifu_instBuffer_full		(idu_ifu_instBuffer_full),
	.idu_ifu_detect_exceptions_wfi	(idu_ifu_detect_exceptions_wfi),
	.iex_ifu_report_exceptions_wfi	(iex_ifu_report_exceptions_wfi),
	.iex_ifu_bru_flush				(bru_flush),
	.iex_ifu_bru_redir_pc			(bru_redir_pc),
	.ifu_csr_start_pulse			(ifu_csr_start_pulse),
	.ifu_csr_core_configuration		(ifu_csr_core_configuration),
	.ifu_idu_pipe_vld 				(ifu_idu_pipe_vld),
	.ifu_idu_pc_1	 				(ifu_idu_pc_1),
	.ifu_idu_pc_2		 			(ifu_idu_pc_2),
	.ifu_idu_inst_1 				(ifu_idu_inst_1),
	.ifu_idu_inst_2					(ifu_idu_inst_2),
	.ifu_idu_pc_unalign_1 			(ifu_idu_pc_unalign_1),
	.ifu_idu_pc_unalign_2 			(ifu_idu_pc_unalign_2),

);
*/
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
		//imem.mem[i] = i;
	end
end
//modules input value setting
//for submodules including register, be careful with time changing value
initial begin
    //initialize
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    core_running	<=   'b0;
    ifu_idu_pipe_vld	<=   'b0;
    bru_flush	<=	0;
    dispatcher_detect_exceptions_wfi <= 0;
    dispatch_vld_q	<=	2'b0;
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
    //Control flag reset
    bru_flush	<=	0;
    dispatcher_detect_exceptions_wfi <= 0;
    //Dispatch invalid, write until buffer full
    //IDU input
    dispatch_vld_q	<=	2'b0;	//only test 00 01 11, 10 is block
    //ifu input
    ifu_idu_pipe_vld 	<=   'b1;
    for(int i=0; i<2; i++) begin
    	ifu_idu_inst[i]	<=	i;
    	ifu_idu_pc[i]		<=	i;
    	ifu_idu_pc_unalign[i]  <=	0;
    end
    #`FULL_CLOCK_CYCLE;
    for(int i=0; i<2; i++) begin
    	ifu_idu_inst[i]	<=	i+2;
    	ifu_idu_pc[i]		<=	i+2;
    	ifu_idu_pc_unalign[i]  <=	1;
    end
   #`FULL_CLOCK_CYCLE;
    for(int i=0; i<2; i++) begin
    	ifu_idu_inst[i]	<=	i+4;
    	ifu_idu_pc[i]		<=	i+4;
    	ifu_idu_pc_unalign[i]  <=	0;
    end
   #`FULL_CLOCK_CYCLE;
    for(int i=0; i<2; i++) begin
    	ifu_idu_inst[i]	<=	i+6;
    	ifu_idu_pc[i]		<=	i+6;
    	ifu_idu_pc_unalign[i]  <=	1;
    end
   #`FULL_CLOCK_CYCLE;
   //buffer full, fetch_vld down, data will not be written into buffer
   ifu_idu_pipe_vld 	<=   'b0;
    for(int i=0; i<2; i++) begin
    	ifu_idu_inst[i]	<=	i+8;
    	ifu_idu_pc[i]		<=	i+8;
    	ifu_idu_pc_unalign[i]  <=	0;
    end
    #`FULL_CLOCK_CYCLE;
    //Dispatch vaild 1, buffer should be still output full flag
    dispatch_vld_q <= 2'b01; 
    #`FULL_CLOCK_CYCLE;
    //Dispatch valid 2, buffer has 3 free entry(not full) after this cycle
    dispatch_vld_q <= 2'b11; 
    #`FULL_CLOCK_CYCLE;
    //BRU flush clear buffer
    ifu_idu_pipe_vld 	<=   'b1;
    bru_flush <= 1'b1;
    #`FULL_CLOCK_CYCLE;
    //Exceptions should clear buffer
    bru_flush <= 1'b0;
    dispatcher_detect_exceptions_wfi <= 1'b1;

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
