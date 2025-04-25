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
	reg	[`EXCEPTION_NUM-1:0]	csr_idu_core_configuration;
	reg							instBuffer_dispatcher_inst_vld				[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_dmem_load					[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_dmem_store					[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_stall_vld					[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_wfi_vld						[`SUPER_SCALAR_NUM-1:0];
	reg							instBuffer_dispatcher_exception_pc_unalign	[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_exception_illegal_inst		[`SUPER_SCALAR_NUM-1:0];
	reg							idu_dispatcher_inst_0_rd_vld;
	reg	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_0_rd;
	reg							idu_dispatcher_inst_1_rs1_vld;
	reg							idu_dispatcher_inst_1_rs2_vld;
	reg	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_1_rs1;
	reg	[`RF_DEPTH_BIT-1:0]		idu_dispatcher_inst_1_rs2;
	wire							dispatcher_detect_exceptions_wfi;
	reg							iex_idu_bru_flush;
	wire							idu_iex_csr_wfi_vld							[`SUPER_SCALAR_NUM-1:0];
	wire							idu_iex_csr_exception_vld					[`SUPER_SCALAR_NUM-1:0];
	wire	[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions						[`SUPER_SCALAR_NUM-1:0];
	wire							idu_iex_dispatch_vld	[`SUPER_SCALAR_NUM-1:0];
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_idu_dispatcher dispatcher_test (
	.csr_idu_core_configuration 				(csr_idu_core_configuration),
	.instBuffer_dispatcher_inst_vld				(instBuffer_dispatcher_inst_vld),
	.idu_dispatcher_dmem_load					(idu_dispatcher_dmem_load),
	.idu_dispatcher_dmem_store					(idu_dispatcher_dmem_store),
	.idu_dispatcher_stall_vld					(idu_dispatcher_stall_vld),
	.idu_dispatcher_wfi_vld						(idu_dispatcher_wfi_vld),
	.instBuffer_dispatcher_exception_pc_unalign	(instBuffer_dispatcher_exception_pc_unalign),
	.idu_dispatcher_exception_illegal_inst		(idu_dispatcher_exception_illegal_inst),
	.idu_dispatcher_inst_0_rd_vld				(idu_dispatcher_inst_0_rd_vld),
	.idu_dispatcher_inst_0_rd					(idu_dispatcher_inst_0_rd),
	.idu_dispatcher_inst_1_rs1_vld				(idu_dispatcher_inst_1_rs1_vld),
	.idu_dispatcher_inst_1_rs2_vld				(idu_dispatcher_inst_1_rs2_vld),
	.idu_dispatcher_inst_1_rs1					(idu_dispatcher_inst_1_rs1),
	.idu_dispatcher_inst_1_rs2					(idu_dispatcher_inst_1_rs2),
	.dispatcher_detect_exceptions_wfi			(dispatcher_detect_exceptions_wfi),
	.iex_idu_bru_flush							(iex_idu_bru_flush),
	.idu_iex_csr_wfi_vld						(idu_iex_csr_wfi_vld),
	.idu_iex_csr_exception_vld					(idu_iex_csr_exception_vld),
	.idu_iex_csr_exceptions						(idu_iex_csr_exceptions),
	.idu_iex_dispatch_vld						(idu_iex_dispatch_vld)
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
//set blackbox data
initial begin
	@(rst_n);
	#`FULL_CLOCK_CYCLE;
	for(int i=0; i<`INST_MEM_DEPTH; i++) begin
		//ifu_test.imem.mem[i] = i;
	end
	for(int i=0; i<`RF_DEPTH; i++) begin
		//rf_test.rf_data_array[i] = i;
	end
end
//modules input value setting
//for submodules including register, be careful with time changing value
initial begin
    //initialize
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`FULL_CLOCK_CYCLE;
    #`FULL_CLOCK_CYCLE;
    //input comes at rising edge
    #`FULL_CLOCK_CYCLE;
    start_pulse         <=   'b1;
    start_pc            <=   'b1000;
    core_configuration  <=   'b10;
    fork
	repeat (2) begin @(posedge clk); end
    join_none
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`HALF_CLOCK_CYCLE;
    //no dispatch, inst 0 vld 1 vld
    //no bru flush, no exceptions, no wfi, no dmem racing, inst 0 stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b1;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 vld 1 vld
    //no bru flush, no exceptions, inst 0 wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b1;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //no dispatch, inst 0 store vld 1 load vld
    //yes bru flush, pc unalign exceptions masked, no wfi, yes dmem racing, inst 1 stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b1;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b1;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b1;
    idu_dispatcher_dmem_store[0]			<= 1'b1;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b1;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b1;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b1;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 store vld 1 load vld
    //no bru flush, no exceptions, no wfi, yes dmem racing, inst 1 stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b1;
    idu_dispatcher_dmem_store[0]			<= 1'b1;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b1;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 store vld 1 load vld
    //no bru flush, no exceptions, no wfi, yes dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b1;
    idu_dispatcher_dmem_store[0]			<= 1'b1;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //2 dispatch, inst 0 vld 1 load vld
    //no bru flush, no exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b1;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 vld 1 rs2 dependency
    //no bru flush, no exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b1;
    idu_dispatcher_inst_0_rd				<= 5'h2;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'h2;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 vld 1 rs1 dependency
    //no bru flush, no exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b1;
    idu_dispatcher_inst_0_rd				<= 5'h3;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'h3;
    idu_dispatcher_inst_1_rs2				<= 5'h0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 vld 1 stall
    //no bru flush, no exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b1;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b1;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //No dispatch, inst 0 stall 1 vld
    //no bru flush, no exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b1;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 exceptions vld 1 vld
    //no bru flush, inst 0 two exceptions, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b1;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b1;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //1 dispatch, inst 0 exceptions vld 1 vld
    //no bru flush, inst 0 two exceptions pc unalign masked, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    csr_idu_core_configuration[0]			<= 1'b1;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b1;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b1;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //2 dispatch, inst 0 exceptions vld 1 vld
    //no bru flush, inst 0 two exceptions all masked, no wfi, no dmem racing, no stall
    #`FULL_CLOCK_CYCLE;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b1;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b1;
    csr_idu_core_configuration[0]			<= 1'b1;
    csr_idu_core_configuration[1]			<= 1'b1;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b1;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b1;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;
    //reset
    #`FULL_CLOCK_CYCLE;
    iex_idu_bru_flush					<= 1'b0;
    instBuffer_dispatcher_inst_vld[0]			<= 1'b0;
    idu_dispatcher_inst_0_rd_vld			<= 1'b0;
    idu_dispatcher_inst_0_rd				<= 5'b0;
    instBuffer_dispatcher_inst_vld[1]			<= 1'b0;
    idu_dispatcher_inst_1_rs1_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs2_vld			<= 1'b0;
    idu_dispatcher_inst_1_rs1				<= 5'b0;
    idu_dispatcher_inst_1_rs2				<= 5'b0;
    idu_dispatcher_dmem_load[0]				<= 1'b0;
    idu_dispatcher_dmem_load[1]				<= 1'b0;
    idu_dispatcher_dmem_store[0]			<= 1'b0;
    idu_dispatcher_dmem_store[1]			<= 1'b0;
    idu_dispatcher_stall_vld[0]				<= 1'b0;
    idu_dispatcher_stall_vld[1]				<= 1'b0;
    idu_dispatcher_wfi_vld[0]				<= 1'b0;
    idu_dispatcher_wfi_vld[1]				<= 1'b0;
    csr_idu_core_configuration[0]			<= 1'b0;
    csr_idu_core_configuration[1]			<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[0]	<= 1'b0;
    instBuffer_dispatcher_exception_pc_unalign[1]	<= 1'b0;
    idu_dispatcher_exception_illegal_inst[0]		<= 1'b0;
    idu_dispatcher_exception_illegal_inst[1]		<= 1'b0;


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
