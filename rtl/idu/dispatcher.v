module u_idu_dispatcher (

	//dispatcher
	//1.pipe valid generation
	//1.1.Check if iex comes a flush
	//2.check instruction dependency by checking inst 1 rs1/2 == inst 1 rd? if so, inst 1 dispatch invalid, read as inst 1 next cycle by rd ptr increment
	//3.Stall checking: if inst 0 dispatch invalid, inst 1 dispatch invalid as well
	//4.Check if inst 0 exception/wfi, if so, inst 1 dispatch invalid
	//4.0 If wfi instruction call an exception, exception has high priority than wfi
	//4.1 stop the pipeline by?
	//4.1.1 clear instruction Buffer
	//4.1.2 Update csr
	//4.1.3 IFU to IDU pipe valid is include checking of core status: core running
	//5.Memory access checking: if inst 0 and inst 1 both access to memory, inst 1 dispatch invalid

	//CSR input
	input	[`EXCEPTION_NUM-1:0]	csr_idu_core_configuration,

	//IDU 0,1 input
	//inst vld
	input							instBuffer_dispatcher_inst_vld				[`SUPER_SCALAR_NUM-1:0],
	//Mem access inst
	input							idu_dispatcher_dmem_load					[`SUPER_SCALAR_NUM-1:0],
	input							idu_dispatcher_dmem_store					[`SUPER_SCALAR_NUM-1:0],
	//stall vld
	input							idu_dispatcher_stall_vld					[`SUPER_SCALAR_NUM-1:0],
	//wfi vld
	input							idu_dispatcher_wfi_vld						[`SUPER_SCALAR_NUM-1:0],
	//exception vld
	input							instBuffer_dispatcher_exception_pc_unalign	[`SUPER_SCALAR_NUM-1:0],
	input							idu_dispatcher_exception_illegal_inst		[`SUPER_SCALAR_NUM-1:0],
	//inst 0 rd
	input							idu_dispatcher_inst_0_rd_vld,
	input	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_0_rd,
	//inst 1 rs1/rs2
	input							idu_dispatcher_inst_1_rs1_vld,
	input							idu_dispatcher_inst_1_rs2_vld,
	input	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_1_rs1,
	input	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_1_rs2,

	//InstBuffer output
	output							dispatcher_detect_exceptions_wfi,

	//iex input
	//bru flush
	input							iex_idu_bru_flush,

	//iex output
	//Exceptions/WFI reporting signals
	//wfi vld
	output							idu_iex_csr_wfi_vld							[`SUPER_SCALAR_NUM-1:0],
	//exception vld
	output							idu_iex_csr_exception_vld					[`SUPER_SCALAR_NUM-1:0],
	//exception
	output	[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions						[`SUPER_SCALAR_NUM-1:0],
	//dispatch valid act as input of pipe valid of iex
	//dispatch valid also pass to inst buffer for read ptr increment
	//dispatch valid 0
	//dispatch valid 1: invalid if dispatch vld 0 = 0
	output							idu_iex_dispatch_vld						[`SUPER_SCALAR_NUM-1:0]

);

//Internal signal
wire							inst_0_vld;
wire							inst_0_rd_vld;
wire	[`RF_DEPTH_BIT-1:0]		inst_0_rd;

wire							inst_1_vld;
wire							inst_1_rs1_vld;
wire							inst_1_rs2_vld;
wire	[`RF_DEPTH_BIT-1:0]		inst_1_rs1;
wire	[`RF_DEPTH_BIT-1:0]		inst_1_rs2;

wire							inst_0_dmem_access;
wire							inst_0_stall_vld;
wire							inst_0_wfi_vld;
wire							inst_0_exception_vld;
wire	[`EXCEPTION_NUM-1:0]	inst_0_exceptions;

wire							inst_1_dmem_access;
wire							inst_1_stall_vld;
wire							inst_1_wfi_vld;
wire							inst_1_exception_vld;
wire	[`EXCEPTION_NUM-1:0]	inst_1_exceptions;

wire							inst_1_rs1_data_dependency;
wire							inst_1_rs2_data_dependency;

//Internal signal assignment
assign	inst_0_vld					=	instBuffer_dispatcher_inst_vld[0];
assign	inst_0_stall_vld			=	idu_dispatcher_stall_vld[0];
assign	inst_0_rd_vld				=	idu_dispatcher_inst_0_rd_vld;
assign	inst_0_rd					=	idu_dispatcher_inst_0_rd;

assign	inst_1_vld					=	instBuffer_dispatcher_inst_vld[1];
assign	inst_1_stall_vld			=	idu_dispatcher_stall_vld[1];
assign	inst_1_rs1_vld				=	idu_dispatcher_inst_1_rs1_vld;
assign	inst_1_rs2_vld				=	idu_dispatcher_inst_1_rs2_vld;
assign	inst_1_rs1					=	idu_dispatcher_inst_1_rs1;
assign	inst_1_rs2					=	idu_dispatcher_inst_1_rs2;
 
//Memory access detecting
assign	inst_0_dmem_access			=	idu_dispatcher_dmem_load[0] | idu_dispatcher_dmem_store[0];
assign	inst_1_dmem_access			=	idu_dispatcher_dmem_load[1]	| idu_dispatcher_dmem_store[1];

//Data dependency checking
assign	inst_1_rs1_data_dependency	=	inst_0_rd_vld & inst_1_rs1_vld & (inst_0_rd == inst_1_rs1);
assign	inst_1_rs2_data_dependency	=	inst_0_rd_vld & inst_1_rs2_vld & (inst_0_rd == inst_1_rs2);

//wfi detecting
assign	inst_0_wfi_vld				=	~inst_0_exception_vld & idu_dispatcher_wfi_vld[0];
assign	inst_1_wfi_vld				=	~inst_1_exception_vld & idu_dispatcher_wfi_vld[1];

//Exception detecting
//CSR updating cannot be done in IDU, consider case inst 0 branch taken, but inst 1 illegal/wfi inst, illegal/wfi inst needs to be flush
//solution: 
//1.detect exception here, but no reporting(i.e.updating CSR) is done
//2.report exception in EX stage, after bru 1 resolved 
//3.No writing operation is done to instBuffer, instBuffer clearBuffer condition need to consider iex exception_vld/wfi_vld as well
//As instruction buffer remains empty, IDU pipe_vld invalid and create bubbles
//if bru flush vld, CSR will not be updated and fetch will resume
//if bru flush invalid, CSR will be updated in next cycle and fetch_vld will be invalid mask by core_status[0]

//inst 0
assign	inst_0_exception_vld		=	|inst_0_exceptions;
assign	inst_0_exceptions[0]		=	(~csr_idu_core_configuration[0] & instBuffer_dispatcher_exception_pc_unalign[0]);
assign	inst_0_exceptions[1]		=	~inst_0_exceptions[0] & (~csr_idu_core_configuration[1] & idu_dispatcher_exception_illegal_inst[0]);

//inst 1
assign	inst_1_exception_vld		=	|inst_1_exceptions;
assign	inst_1_exceptions[0]		=	(~csr_idu_core_configuration[0] & instBuffer_dispatcher_exception_pc_unalign[1]);
assign	inst_1_exceptions[1]		=	~inst_1_exceptions[0] & (~csr_idu_core_configuration[1] & idu_dispatcher_exception_illegal_inst[1]);

//dispatch vld generation
assign inst_0_dispatch_vld = inst_0_vld & ~(inst_0_stall_vld | iex_idu_bru_flush);
assign inst_1_dispatch_vld = inst_1_vld & ~inst_1_stall_vld & inst_0_dispatch_vld & ~(inst_0_vld & (inst_0_wfi_vld | inst_0_exception_vld)) & ~(inst_1_rs1_data_dependency | inst_1_rs2_data_dependency) & ~(inst_0_dmem_access & inst_1_dmem_access);

//Output interface assignment
assign	dispatcher_detect_exceptions_wfi	=	(inst_0_dispatch_vld & (inst_0_wfi_vld | inst_0_exception_vld)) | (inst_1_dispatch_vld & (inst_1_wfi_vld | inst_1_exception_vld));
assign	idu_iex_dispatch_vld[0]				=	inst_0_dispatch_vld;
assign	idu_iex_dispatch_vld[1]				=	inst_1_dispatch_vld;
assign	idu_iex_csr_wfi_vld[0]				=	inst_0_wfi_vld;
assign	idu_iex_csr_wfi_vld[1]				=	inst_1_wfi_vld;
assign	idu_iex_csr_exception_vld[0]		=	inst_0_exception_vld;
assign	idu_iex_csr_exception_vld[1]		=	inst_1_exception_vld;
assign	idu_iex_csr_exceptions[0]			=	inst_0_exceptions;
assign	idu_iex_csr_exceptions[1]			=	inst_1_exceptions;

endmodule
