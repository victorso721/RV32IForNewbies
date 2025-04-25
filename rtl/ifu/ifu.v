//Stage definition
//I1: right after clock sync, sync_start_pulse enter IFU / next pc generation
//I2: passing pc to IMEM and reading instruction from IMEM within the same cycle
//I3 / D1: instruction and related data enter IDU (if no stall occured)
//Event priority
//1. reset
//2. start pulse
//3. ALU BRU flush
//4. IDU LOAD/WFI stall 

module u_ifu (
	//SOC input
	input							clk,
	input							rst_n,
	input							start_pulse,
	input	[`PC_WIDTH-1:0]			start_pc,
	input	[`EXCEPTION_NUM-1:0]	core_configuration,	

	//CSR input
	input	[1:0]					core_status,

	//IDU input
	input							idu_ifu_instBuffer_full,
	input							idu_ifu_detect_exceptions_wfi,
	
	//ALU input
	input							iex_ifu_report_exceptions_wfi,
	input							iex_ifu_bru_flush,
	input	[`PC_WIDTH-1:0]			iex_ifu_bru_redir_pc,

	//CSR output
	output							ifu_csr_start_pulse,
	output	[`EXCEPTION_NUM-1:0]	ifu_csr_core_configuration,

	//IDU output
	output 							ifu_idu_pipe_vld,
	output	[`PC_WIDTH-1:0] 		ifu_idu_pc_1,
	output	[`PC_WIDTH-1:0] 		ifu_idu_pc_2,
	output	[`INST_WIDTH-1:0] 		ifu_idu_inst_1,
	output	[`INST_WIDTH-1:0] 		ifu_idu_inst_2,
	output 							ifu_idu_pc_unalign_1,
	output 							ifu_idu_pc_unalign_2

);

//Internal signal
wire							sync_start_pulse;
wire 	[`PC_WIDTH-1:0]			sync_start_pc;
wire	[`EXCEPTION_NUM-1:0]	sync_core_configuration;
wire							bru_flush;
wire							pipe_vld;
wire							core_running;
wire	[`PC_WIDTH-1:0]			arb_res_pc_q;
reg 	[`PC_WIDTH-1:0]			arb_res_pc;
wire							is_pc_unalign;
wire	[`INST_WIDTH-1:0]		imem_ifu_inst_1;
wire	[`INST_WIDTH-1:0]		imem_ifu_inst_2;

//Construct BRU result
//BRU valid without BRU flush -> BRU resolve, IFU prediction correct ( Modify related logic before enabling dynamic prediction)
assign bru_flush = iex_ifu_bru_flush;

//I1
//2 flip flop synchronizer
u_ifu_2ff_synchronizer synchronizer(
	.clk						(clk),
	.rst_n						(rst_n),
	.start_pulse				(start_pulse),
	.start_pc					(start_pc),
	.core_configuration			(core_configuration),
	.sync_start_pulse			(sync_start_pulse),
	.sync_start_pc				(sync_start_pc),
	.sync_core_configuration	(sync_core_configuration)
);

//CSR interface
assign ifu_csr_start_pulse = sync_start_pulse;
assign ifu_csr_core_configuration = sync_core_configuration;

//core running signal generation
assign core_running = core_status[0];

//PC generation
u_ifu_pc_generator pc_generator(
	//Control input
	.start_pulse	(sync_start_pulse),
	.bru_flush		(bru_flush),

	//Data input
	.start_pc		(sync_start_pc),
	.bru_redir_pc	(iex_ifu_bru_redir_pc),
	.arb_res_pc		(arb_res_pc),

	//Control output
	.is_pc_unalign	(is_pc_unalign),

	//Data output
	.arb_res_pc_q	(arb_res_pc_q)
);

//I1 I2 interstage register
//dff_re u_arb_res_pc 
//if start_pulse or bru_flush, pass redir pc
//if pc+4 is passing, check if stalled by IDU AND core is running
always @(posedge clk) begin
	if(sync_start_pulse || bru_flush || (core_running & ~(idu_ifu_instBuffer_full | idu_ifu_detect_exceptions_wfi | iex_ifu_report_exceptions_wfi))) begin
		arb_res_pc <= arb_res_pc_q;
	end
end

//I2
//Instruction memory reading
//IMEM module
u_IMem_256X32_2R1W imem(
	.clk		(clk),
	.addr		(arb_res_pc_q[(`INST_MEM_DEPTH_BIT-1+(`INST_MEM_WIDTH_BIT-3)):(`INST_MEM_WIDTH_BIT-3)]),
	.cen		(core_running | sync_start_pulse),
	.wen		(1'b0),
	.wr_data	(32'b0),
	.rd_data_1	(imem_ifu_inst_1),
	.rd_data_2	(imem_ifu_inst_2)
);

//Post-fetch unconditional branch detecction
//------Unconditional branch detection is not supported in this project------//

//Pipeline valid gernerating
//BRU flush select pc at I1, when redir pc enter I2, bru_flush is 0
//pipe vld handling for stall is done in IDU
assign pipe_vld = ~(bru_flush | idu_ifu_instBuffer_full | idu_ifu_detect_exceptions_wfi | iex_ifu_report_exceptions_wfi) & core_running;

//Superscalar: use instBuffer as inter-stage buffer, IDU output do not need to pass register in IFU
assign ifu_idu_pipe_vld 	= pipe_vld;
assign ifu_idu_pc_1 		= arb_res_pc;
assign ifu_idu_pc_2 		= arb_res_pc + 'd4;
assign ifu_idu_pc_unalign_1	= is_pc_unalign;
assign ifu_idu_pc_unalign_2	= 'b0;				//This project use double fetch, only the first pc unalignment will call exceptions
assign ifu_idu_inst_1		= imem_ifu_inst_1;
assign ifu_idu_inst_2		= imem_ifu_inst_2;

/* 
//dff_r u_ifu_pipe_vld
always @(posedge clk) begin
	if(~rst_n) begin
		ifu_idu_pipe_vld <= pipe_vld;
	end
end

//dffre IFU_IDU en: pipe_vld
always @(posedge clk) begin
	if(~rst_n) begin
		ifu_idu_inst <= 'b0;
		ifu_idu_pc <= 'b0;
		ifu_idu_pc_unalign <= 'b0;
	end
	else if(pipe_vld) begin //Large bus, power control: not updating if not needed
		ifu_idu_inst <= imem_ifu_inst;
		ifu_idu_pc <= arb_res_pc;
		ifu_idu_pc_unalign <= is_pc_unalign;
	end
end
*/
endmodule
