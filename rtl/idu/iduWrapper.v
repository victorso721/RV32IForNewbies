//IDU Wrapper
//1. Read instruction from instruction buffer
//2. Decode instruction and prepare data needed in IDU 1,2
//3. Dependency checking in dispatcher
//4. Pass control signal and data to EX stage

module u_idu_super_scalar_wrapper (
	//SoC input
	input							clk,
	input							rst_n,
	
	//CSR input
	input	[`EXCEPTION_NUM-1:0]	csr_idu_core_configuration,

	//IFU input
	input					sync_start_pulse,
	input 							ifu_idu_pipe_vld,
	input [`PC_WIDTH-1:0] 			ifu_idu_pc 							[`SUPER_SCALAR_NUM-1:0],
	input [`INST_WIDTH-1:0] 		ifu_idu_inst 						[`SUPER_SCALAR_NUM-1:0],
	input 							ifu_idu_pc_unalign					[`SUPER_SCALAR_NUM-1:0],

	//ALU input
	input							iex_idu_bru_flush,
	input							iex_idu_pipe_vld					[`SUPER_SCALAR_NUM-1:0],
	input 							iex_idu_is_load						[`SUPER_SCALAR_NUM-1:0],
	input 							iex_idu_rd_vld						[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]		iex_idu_byp_rd						[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 		iex_idu_byp_data					[`SUPER_SCALAR_NUM-1:0],

	//LSU input
	input							lsu_idu_pipe_vld					[`SUPER_SCALAR_NUM-1:0],
	input 							lsu_idu_is_load						[`SUPER_SCALAR_NUM-1:0],
	input							lsu_idu_rd_vld						[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]		lsu_idu_byp_rd						[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 		lsu_idu_byp_data					[`SUPER_SCALAR_NUM-1:0],
	
	//RF input
	input							rf_idu_pipe_vld						[`SUPER_SCALAR_NUM-1:0],
	input							rf_idu_rd_vld						[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]		rf_idu_byp_rd						[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 		rf_idu_byp_data						[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 		rf_idu_rs1_data						[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 		rf_idu_rs2_data						[`SUPER_SCALAR_NUM-1:0],

	//IFU output
	output							idu_ifu_instBuffer_full,
	output							idu_ifu_detect_exceptions_wfi,

	//AlphaTensor output
	`ifdef ALPHATENSOR
		output									idu_alphaTensor_matrix_mul_vld,
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx,
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx,
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx,
	`endif

	//CSR output
	//wfi vld
	output							idu_iex_csr_wfi_vld					[`SUPER_SCALAR_NUM-1:0],
	//exception vld
	output							idu_iex_csr_exception_vld			[`SUPER_SCALAR_NUM-1:0],
	//exception
	output	[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions				[`SUPER_SCALAR_NUM-1:0],
	
	//ALU output
	output	[`PC_WIDTH-1:0]			idu_iex_pc							[`SUPER_SCALAR_NUM-1:0],
	output	[`DATA_WIDTH-1:0]		idu_iex_rs1_data					[`SUPER_SCALAR_NUM-1:0],
	output	[`DATA_WIDTH-1:0]		idu_iex_rs2_data					[`SUPER_SCALAR_NUM-1:0],
	output	[`DATA_WIDTH-1:0]		idu_iex_imm_data					[`SUPER_SCALAR_NUM-1:0],
	output	[`RF_DEPTH_BIT-1:0]		idu_iex_rd							[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_rd_vld						[`SUPER_SCALAR_NUM-1:0], 
	output							idu_iex_pipe_vld					[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_is_load						[`SUPER_SCALAR_NUM-1:0], 

	//Control output
	//Data selection control flag in ALU
	output							idu_iex_flag_adder_sel_src1_pc		[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_adder_sel_src2_rs2		[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_general_sel_src2_rs2	[`SUPER_SCALAR_NUM-1:0],
	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	output							idu_iex_flag_unsigned_data			[`SUPER_SCALAR_NUM-1:0],
	//Adder
	output							idu_iex_flag_adder_vld				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_adder_sub				[`SUPER_SCALAR_NUM-1:0],
	//Comparator
	output							idu_iex_flag_comparator_vld			[`SUPER_SCALAR_NUM-1:0],
	//logical plane
	output							idu_iex_flag_logical_plane_and		[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_logical_plane_or		[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_logical_plane_xor		[`SUPER_SCALAR_NUM-1:0],
	//Shifter
	output							idu_iex_flag_shifter_right_shift	[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_shifter_logical_shift	[`SUPER_SCALAR_NUM-1:0],
	//BRU
	output							idu_iex_flag_bru_jal				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_bru_jalr				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_bru_bge				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_bru_blt				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_bru_beq				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_bru_bne				[`SUPER_SCALAR_NUM-1:0],
	//Memory access flag
	output							idu_iex_flag_dmem_lb				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_dmem_lh				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_dmem_lw				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_dmem_sw				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_dmem_sb				[`SUPER_SCALAR_NUM-1:0],
	output							idu_iex_flag_dmem_sh				[`SUPER_SCALAR_NUM-1:0],
	//Control flag for RF
	output							idu_iex_rf_wen						[`SUPER_SCALAR_NUM-1:0],

	//RF output
	output [`RF_DEPTH_BIT-1:0] 		idu_rf_rs1_idx						[`SUPER_SCALAR_NUM-1:0],
	output [`RF_DEPTH_BIT-1:0] 		idu_rf_rs2_idx						[`SUPER_SCALAR_NUM-1:0]	

);

//-----------------Internal signal--------------//
wire							dispatcher_detect_exceptions_wfi;

wire	[`INST_WIDTH-1:0]		instBuffer_instDecode_inst				[`SUPER_SCALAR_NUM-1:0];
wire							instBuffer_dispatcher_inst_vld			[`SUPER_SCALAR_NUM-1:0];
wire							instBuffer_dispatcher_unalign_pc		[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_rd_vld					[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_rs1_vld					[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_rs2_vld					[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_wfi_vld					[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_stall_vld				[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_exception_illegal_inst	[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_dmem_load				[`SUPER_SCALAR_NUM-1:0];
wire							idu_dispatcher_dmem_store				[`SUPER_SCALAR_NUM-1:0];

wire	[`PC_WIDTH-1:0] 		idu_iex_pc_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_csr_wfi_vld_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_csr_exception_vld_q				[`SUPER_SCALAR_NUM-1:0];
wire	[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions_q				[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_rs1_data_q						[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_rs2_data_q						[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_imm_data_q						[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		idu_iex_rd_q							[`SUPER_SCALAR_NUM-1:0];
wire							dispatch_vld_q							[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_adder_sel_src1_pc_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_adder_sel_src2_rs2_q			[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_general_sel_src2_rs2_q			[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_unsigned_data_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_adder_vld_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_adder_sub_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_comparator_vld_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_logical_plane_and_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_logical_plane_or_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_logical_plane_xor_q				[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_shifter_right_shift_q			[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_shifter_logical_shift_q			[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_jal_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_jalr_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_bge_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_blt_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_beq_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_bru_bne_q						[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_lb_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_lh_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_lw_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_sw_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_sb_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_lsu_sel_sh_q					[`SUPER_SCALAR_NUM-1:0];
wire							idu_iex_rf_wen_q						[`SUPER_SCALAR_NUM-1:0];

reg	[`PC_WIDTH-1:0] 		idu_iex_pc_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_csr_wfi_vld_reg					[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_csr_exception_vld_reg			[`SUPER_SCALAR_NUM-1:0];
reg		[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions_reg				[`SUPER_SCALAR_NUM-1:0];
reg		[`DATA_WIDTH-1:0]		idu_iex_rs1_data_reg					[`SUPER_SCALAR_NUM-1:0];
reg		[`DATA_WIDTH-1:0]		idu_iex_rs2_data_reg					[`SUPER_SCALAR_NUM-1:0];
reg		[`DATA_WIDTH-1:0]		idu_iex_imm_data_reg					[`SUPER_SCALAR_NUM-1:0];
reg		[`RF_DEPTH_BIT-1:0]		idu_iex_rd_reg							[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_rd_vld_reg						[`SUPER_SCALAR_NUM-1:0]; 
reg								idu_iex_pipe_vld_reg					[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_is_load_reg						[`SUPER_SCALAR_NUM-1:0]; 
reg								idu_iex_flag_adder_sel_src1_pc_reg		[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_adder_sel_src2_rs2_reg		[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_general_sel_src2_rs2_reg	[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_unsigned_data_reg			[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_adder_vld_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_adder_sub_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_comparator_vld_reg			[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_logical_plane_and_reg		[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_logical_plane_or_reg		[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_logical_plane_xor_reg		[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_shifter_right_shift_reg	[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_shifter_logical_shift_reg	[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_jal_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_jalr_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_bge_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_blt_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_beq_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_bru_bne_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_lb_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_lh_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_lw_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_sw_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_sb_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_flag_dmem_sh_reg				[`SUPER_SCALAR_NUM-1:0];
reg								idu_iex_rf_wen_reg						[`SUPER_SCALAR_NUM-1:0];

`ifdef ALPHATENSOR
wire									idu_alphaTensor_matrix_mul_vld_q	[`SUPER_SCALAR_NUM-1:0];
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx_q				[`SUPER_SCALAR_NUM-1:0];
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx_q			[`SUPER_SCALAR_NUM-1:0];
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx_q			[`SUPER_SCALAR_NUM-1:0];
reg										idu_alphaTensor_matrix_mul_vld_reg;
reg		[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx_reg;
reg		[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx_reg;
reg		[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx_reg;
`endif

//-----------------------end--------------------//

//--------------Instruction Buffer--------------//

u_idu_instBuffer instBuffer(

	//SoC control input
	.clk									(clk),
	.rst_n									(rst_n),

	//IFU control input
	.sync_start_pulse						(sync_start_pulse),
	.ifu_idu_fetch_vld						(ifu_idu_pipe_vld),

	//IFU control output
	.idu_ifu_instBuffer_full				(idu_ifu_instBuffer_full),

	//IDU control input
	.dispatch_vld_0							(dispatch_vld_q[0]),
	.dispatch_vld_1							(dispatch_vld_q[1]),
	.dispatcher_detect_exceptions_wfi		(dispatcher_detect_exceptions_wfi),
	.bru_flush								(iex_idu_bru_flush),

	//IDU control output
	.instBuffer_inst_vld_0					(instBuffer_dispatcher_inst_vld[0]),
	.instBuffer_inst_vld_1					(instBuffer_dispatcher_inst_vld[1]),

	//IFU data input
	.inst_in_0								(ifu_idu_inst[0]),
	.inst_in_1								(ifu_idu_inst[1]),
	.pc_in_0								(ifu_idu_pc[0]),
	.pc_in_1								(ifu_idu_pc[1]),
	.unalign_pc_in_0						(ifu_idu_pc_unalign[0]),
	.unalign_pc_in_1						(ifu_idu_pc_unalign[1]),

	//IDU data output
	.inst_out_0								(instBuffer_instDecode_inst[0]),
	.inst_out_1								(instBuffer_instDecode_inst[1]),
	.pc_out_0								(idu_iex_pc_q[0]),
	.pc_out_1								(idu_iex_pc_q[1]),
	.unalign_pc_out_0						(instBuffer_dispatcher_unalign_pc[0]),
	.unalign_pc_out_1						(instBuffer_dispatcher_unalign_pc[1])
);

//-----------------------end--------------------//

//----------------------IDU 0-------------------//
u_idu idu_0(
	
	.instBuffer_idu_inst_in					(instBuffer_instDecode_inst[0]),
	.iex_idu_pipe_vld						(iex_idu_pipe_vld),
	.iex_idu_is_load						(iex_idu_is_load),
	.iex_idu_rd_vld							(iex_idu_rd_vld),
	.iex_idu_byp_rd							(iex_idu_byp_rd),
	.iex_idu_byp_data						(iex_idu_byp_data),
	.lsu_idu_pipe_vld						(lsu_idu_pipe_vld),
	.lsu_idu_is_load						(lsu_idu_is_load),
	.lsu_idu_rd_vld							(lsu_idu_rd_vld),
	.lsu_idu_byp_rd							(lsu_idu_byp_rd),
	.lsu_idu_byp_data						(lsu_idu_byp_data),
	.rf_idu_pipe_vld						(rf_idu_pipe_vld),
	.rf_idu_rd_vld							(rf_idu_rd_vld),
	.rf_idu_byp_rd							(rf_idu_byp_rd),
	.rf_idu_byp_data						(rf_idu_byp_data),
	.rf_idu_rs1_data						(rf_idu_rs1_data[0]),
	.rf_idu_rs2_data						(rf_idu_rs2_data[0]),
	.idu_dispatcher_rd_vld					(idu_dispatcher_rd_vld[0]),
	.idu_dispatcher_rs1_vld					(idu_dispatcher_rs1_vld[0]),
	.idu_dispatcher_rs2_vld					(idu_dispatcher_rs2_vld[0]),
	.idu_dispatcher_wfi_vld					(idu_dispatcher_wfi_vld[0]),
	.idu_dispatcher_stall_vld				(idu_dispatcher_stall_vld[0]),
	.idu_dispatcher_exception_illegal_inst	(idu_dispatcher_exception_illegal_inst[0]),
	.idu_dispatcher_dmem_load				(idu_dispatcher_dmem_load[0]),
	.idu_dispatcher_dmem_store				(idu_dispatcher_dmem_store[0]),

	//ALU output
	`ifdef ALPHATENSOR
		.idu_alphaTensor_matrix_mem_rs1_idx		(idu_alphaTensor_matrix_mem_rs1_idx_q[0]),
		.idu_alphaTensor_matrix_mem_rs2_idx		(idu_alphaTensor_matrix_mem_rs2_idx_q[0]),
		.idu_alphaTensor_matrix_mem_rd_idx		(idu_alphaTensor_matrix_mem_rd_idx_q[0]),
		.idu_alphaTensor_matrix_mul_vld			(idu_alphaTensor_matrix_mul_vld_q[0]),
	`endif

	//Data output
	.idu_iex_rs1_data						(idu_iex_rs1_data_q[0]),
	.idu_iex_rs2_data						(idu_iex_rs2_data_q[0]),
	.idu_iex_imm_data						(idu_iex_imm_data_q[0]),
	.idu_iex_rd								(idu_iex_rd_q[0]),

	//Control output
	//Data selection control flag in ALU
	.idu_iex_adder_sel_src1_pc				(idu_iex_adder_sel_src1_pc_q[0]),
	.idu_iex_adder_sel_src2_rs2				(idu_iex_adder_sel_src2_rs2_q[0]),
	.idu_iex_general_sel_src2_rs2			(idu_iex_general_sel_src2_rs2_q[0]),

	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	.idu_iex_unsigned_data					(idu_iex_unsigned_data_q[0]),
	//Adder
	.idu_iex_adder_vld						(idu_iex_adder_vld_q[0]),
	.idu_iex_adder_sub						(idu_iex_adder_sub_q[0]),
	//Comparator
	.idu_iex_comparator_vld					(idu_iex_comparator_vld_q[0]),
	//logical plane
	.idu_iex_logical_plane_and				(idu_iex_logical_plane_and_q[0]),
	.idu_iex_logical_plane_or				(idu_iex_logical_plane_or_q[0]),
	.idu_iex_logical_plane_xor				(idu_iex_logical_plane_xor_q[0]),
	//Shifter
	.idu_iex_shifter_right_shift			(idu_iex_shifter_right_shift_q[0]),
	.idu_iex_shifter_logical_shift			(idu_iex_shifter_logical_shift_q[0]),
	//BRU
	.idu_iex_bru_jal						(idu_iex_bru_jal_q[0]),
	.idu_iex_bru_jalr						(idu_iex_bru_jalr_q[0]),
	.idu_iex_bru_bge						(idu_iex_bru_bge_q[0]),
	.idu_iex_bru_blt						(idu_iex_bru_blt_q[0]),
	.idu_iex_bru_beq						(idu_iex_bru_beq_q[0]),
	.idu_iex_bru_bne						(idu_iex_bru_bne_q[0]),
	//Memory access flag
	.idu_iex_lsu_sel_lb						(idu_iex_lsu_sel_lb_q[0]),
	.idu_iex_lsu_sel_lh						(idu_iex_lsu_sel_lh_q[0]),
	.idu_iex_lsu_sel_lw						(idu_iex_lsu_sel_lw_q[0]),
	.idu_iex_lsu_sel_sw						(idu_iex_lsu_sel_sw_q[0]),
	.idu_iex_lsu_sel_sb						(idu_iex_lsu_sel_sb_q[0]),
	.idu_iex_lsu_sel_sh						(idu_iex_lsu_sel_sh_q[0]),
	//Control flag for RF
	.idu_iex_rf_wen							(idu_iex_rf_wen_q[0]),

	//RF output
	.idu_rf_rs1_idx							(idu_rf_rs1_idx[0]),
	.idu_rf_rs2_idx							(idu_rf_rs2_idx[0])

);

//-----------------------end--------------------//

//----------------------IDU 1-------------------//
u_idu idu_1(
	.instBuffer_idu_inst_in					(instBuffer_instDecode_inst[1]),
	.iex_idu_pipe_vld						(iex_idu_pipe_vld),
	.iex_idu_is_load						(iex_idu_is_load),
	.iex_idu_rd_vld							(iex_idu_rd_vld),
	.iex_idu_byp_rd							(iex_idu_byp_rd),
	.iex_idu_byp_data						(iex_idu_byp_data),
	.lsu_idu_pipe_vld						(lsu_idu_pipe_vld),
	.lsu_idu_is_load						(lsu_idu_is_load),
	.lsu_idu_rd_vld							(lsu_idu_rd_vld),
	.lsu_idu_byp_rd							(lsu_idu_byp_rd),
	.lsu_idu_byp_data						(lsu_idu_byp_data),
	.rf_idu_pipe_vld						(rf_idu_pipe_vld),
	.rf_idu_rd_vld							(rf_idu_rd_vld),
	.rf_idu_byp_rd							(rf_idu_byp_rd),
	.rf_idu_byp_data						(rf_idu_byp_data),
	.rf_idu_rs1_data						(rf_idu_rs1_data[1]),
	.rf_idu_rs2_data						(rf_idu_rs2_data[1]),
	.idu_dispatcher_rd_vld					(idu_dispatcher_rd_vld[1]),
	.idu_dispatcher_rs1_vld					(idu_dispatcher_rs1_vld[1]),
	.idu_dispatcher_rs2_vld					(idu_dispatcher_rs2_vld[1]),
	.idu_dispatcher_wfi_vld					(idu_dispatcher_wfi_vld[1]),
	.idu_dispatcher_stall_vld				(idu_dispatcher_stall_vld[1]),
	.idu_dispatcher_exception_illegal_inst	(idu_dispatcher_exception_illegal_inst[1]),
	.idu_dispatcher_dmem_load				(idu_dispatcher_dmem_load[1]),
	.idu_dispatcher_dmem_store				(idu_dispatcher_dmem_store[1]),

	`ifdef ALPHATENSOR
		//AlphaTensor output
		.idu_alphaTensor_matrix_mem_rs1_idx		(idu_alphaTensor_matrix_mem_rs1_idx_q[1]),
		.idu_alphaTensor_matrix_mem_rs2_idx		(idu_alphaTensor_matrix_mem_rs2_idx_q[1]),
		.idu_alphaTensor_matrix_mem_rd_idx		(idu_alphaTensor_matrix_mem_rd_idx_q[1]),
		.idu_alphaTensor_matrix_mul_vld			(idu_alphaTensor_matrix_mul_vld_q[1]),
	`endif

	.idu_iex_rs1_data						(idu_iex_rs1_data_q[1]),
	.idu_iex_rs2_data						(idu_iex_rs2_data_q[1]),
	.idu_iex_imm_data						(idu_iex_imm_data_q[1]),
	.idu_iex_rd								(idu_iex_rd_q[1]),
	.idu_iex_adder_sel_src1_pc				(idu_iex_adder_sel_src1_pc_q[1]),
	.idu_iex_adder_sel_src2_rs2				(idu_iex_adder_sel_src2_rs2_q[1]),
	.idu_iex_general_sel_src2_rs2			(idu_iex_general_sel_src2_rs2_q[1]),
	.idu_iex_unsigned_data					(idu_iex_unsigned_data_q[1]),
	.idu_iex_adder_vld						(idu_iex_adder_vld_q[1]),
	.idu_iex_adder_sub						(idu_iex_adder_sub_q[1]),
	.idu_iex_comparator_vld					(idu_iex_comparator_vld_q[1]),
	.idu_iex_logical_plane_and				(idu_iex_logical_plane_and_q[1]),
	.idu_iex_logical_plane_or				(idu_iex_logical_plane_or_q[1]),
	.idu_iex_logical_plane_xor				(idu_iex_logical_plane_xor_q[1]),
	.idu_iex_shifter_right_shift			(idu_iex_shifter_right_shift_q[1]),
	.idu_iex_shifter_logical_shift			(idu_iex_shifter_logical_shift_q[1]),
	.idu_iex_bru_jal						(idu_iex_bru_jal_q[1]),
	.idu_iex_bru_jalr						(idu_iex_bru_jalr_q[1]),
	.idu_iex_bru_bge						(idu_iex_bru_bge_q[1]),
	.idu_iex_bru_blt						(idu_iex_bru_blt_q[1]),
	.idu_iex_bru_beq						(idu_iex_bru_beq_q[1]),
	.idu_iex_bru_bne						(idu_iex_bru_bne_q[1]),
	.idu_iex_lsu_sel_lb						(idu_iex_lsu_sel_lb_q[1]),
	.idu_iex_lsu_sel_lh						(idu_iex_lsu_sel_lh_q[1]),
	.idu_iex_lsu_sel_lw						(idu_iex_lsu_sel_lw_q[1]),
	.idu_iex_lsu_sel_sw						(idu_iex_lsu_sel_sw_q[1]),
	.idu_iex_lsu_sel_sb						(idu_iex_lsu_sel_sb_q[1]),
	.idu_iex_lsu_sel_sh						(idu_iex_lsu_sel_sh_q[1]),
	.idu_iex_rf_wen							(idu_iex_rf_wen_q[1]),

	//RF output
	.idu_rf_rs1_idx							(idu_rf_rs1_idx[1]),
	.idu_rf_rs2_idx							(idu_rf_rs2_idx[1])
);
//-----------------------end--------------------//

//--------------------Dispatcher----------------//
u_idu_dispatcher dispatcher (

	.csr_idu_core_configuration					(csr_idu_core_configuration),
	.instBuffer_dispatcher_inst_vld				(instBuffer_dispatcher_inst_vld),
	.idu_dispatcher_dmem_load					(idu_dispatcher_dmem_load),
	.idu_dispatcher_dmem_store					(idu_dispatcher_dmem_store),
	.idu_dispatcher_stall_vld					(idu_dispatcher_stall_vld),
	.idu_dispatcher_wfi_vld						(idu_dispatcher_wfi_vld),
	.instBuffer_dispatcher_exception_pc_unalign	(instBuffer_dispatcher_unalign_pc),
	.idu_dispatcher_exception_illegal_inst		(idu_dispatcher_exception_illegal_inst),


	.idu_dispatcher_inst_0_rd_vld				(idu_dispatcher_rd_vld[0]),
	.idu_dispatcher_inst_0_rd					(idu_iex_rd_q[0]),

	.idu_dispatcher_inst_1_rs1_vld				(idu_dispatcher_rs1_vld[1]),
	.idu_dispatcher_inst_1_rs2_vld				(idu_dispatcher_rs2_vld[1]),
	.idu_dispatcher_inst_1_rs1					(idu_rf_rs1_idx[1]),
	.idu_dispatcher_inst_1_rs2					(idu_rf_rs2_idx[1]),

	.dispatcher_detect_exceptions_wfi			(dispatcher_detect_exceptions_wfi),
	.iex_idu_bru_flush							(iex_idu_bru_flush),

	.idu_iex_csr_wfi_vld						(idu_iex_csr_wfi_vld_q),

	.idu_iex_csr_exception_vld					(idu_iex_csr_exception_vld_q),
	
	.idu_iex_csr_exceptions						(idu_iex_csr_exceptions_q),

	.idu_iex_dispatch_vld						(dispatch_vld_q)

);
//-----------------------end--------------------//

//---------------Inter-stage Register-----------//
//instruction valid passing register
//always enable
always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for(int i=0; i<`SUPER_SCALAR_NUM;i++) begin
		idu_iex_pipe_vld_reg[i]	<=	'b0;
		end
	end
	else begin
		idu_iex_pipe_vld_reg	<=	dispatch_vld_q;
	end
end

//IDU to ALU output
for(genvar i=0; i<`SUPER_SCALAR_NUM; i++) begin
always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		idu_iex_pc_reg[i]						<=	'b0;
		idu_iex_csr_wfi_vld_reg[i]					<=	'b0;
		idu_iex_csr_exception_vld_reg[i]			<=	'b0;
		idu_iex_csr_exceptions_reg[i]				<=	'b0;
		idu_iex_rs1_data_reg[i]						<=	'b0;
		idu_iex_rs2_data_reg[i]						<=	'b0;
		idu_iex_imm_data_reg[i]						<=	'b0;
		idu_iex_rd_reg[i]							<=	'b0;
		idu_iex_rd_vld_reg[i]						<=	'b0;
		idu_iex_is_load_reg[i]						<=	'b0;
		idu_iex_flag_adder_sel_src1_pc_reg[i]		<=	'b0;
		idu_iex_flag_adder_sel_src2_rs2_reg[i]		<=	'b0;
		idu_iex_flag_general_sel_src2_rs2_reg[i]	<=	'b0;
		idu_iex_flag_unsigned_data_reg[i]			<=	'b0;
		idu_iex_flag_adder_vld_reg[i]				<=	'b0;
		idu_iex_flag_adder_sub_reg[i]				<=	'b0;
		idu_iex_flag_comparator_vld_reg[i]			<=	'b0;
		idu_iex_flag_logical_plane_and_reg[i]		<=	'b0;
		idu_iex_flag_logical_plane_or_reg[i]		<=	'b0;
		idu_iex_flag_logical_plane_xor_reg[i]		<=	'b0;
		idu_iex_flag_shifter_right_shift_reg[i]		<=	'b0;
		idu_iex_flag_shifter_logical_shift_reg[i]	<=	'b0;
		idu_iex_flag_bru_jal_reg[i]				<=	'b0;
		idu_iex_flag_bru_jalr_reg[i]				<=	'b0;
		idu_iex_flag_bru_bge_reg[i]					<=	'b0;
		idu_iex_flag_bru_blt_reg[i]					<=	'b0;
		idu_iex_flag_bru_beq_reg[i]					<=	'b0;
		idu_iex_flag_bru_bne_reg[i]					<=	'b0;
		idu_iex_flag_dmem_lb_reg[i]					<=	'b0;
		idu_iex_flag_dmem_lh_reg[i]					<=	'b0;
		idu_iex_flag_dmem_lw_reg[i]					<=	'b0;
		idu_iex_flag_dmem_sw_reg[i]					<=	'b0;
		idu_iex_flag_dmem_sb_reg[i]					<=	'b0;
		idu_iex_flag_dmem_sh_reg[i]					<=	'b0;
		idu_iex_rf_wen_reg[i]						<=	'b0;
	end
	else if(dispatch_vld_q[i]) begin
		idu_iex_pc_reg[i]						<=	idu_iex_pc_q[i];
		idu_iex_csr_wfi_vld_reg[i]					<=	idu_iex_csr_wfi_vld_q[i];
		idu_iex_csr_exception_vld_reg[i]			<=	idu_iex_csr_exception_vld_q[i];
		idu_iex_csr_exceptions_reg[i]				<=	idu_iex_csr_exceptions_q[i];
		idu_iex_rs1_data_reg[i]						<=	idu_iex_rs1_data_q[i];
		idu_iex_rs2_data_reg[i]						<=	idu_iex_rs2_data_q[i];
		idu_iex_imm_data_reg[i]						<=	idu_iex_imm_data_q[i];
		idu_iex_rd_reg[i]							<=	idu_iex_rd_q[i];
		idu_iex_rd_vld_reg[i]						<=	idu_dispatcher_rd_vld[i];
		idu_iex_is_load_reg[i]						<=	idu_dispatcher_dmem_load[i];
		idu_iex_flag_adder_sel_src1_pc_reg[i]		<=	idu_iex_adder_sel_src1_pc_q[i];
		idu_iex_flag_adder_sel_src2_rs2_reg[i]		<=	idu_iex_adder_sel_src2_rs2_q[i];	
		idu_iex_flag_general_sel_src2_rs2_reg[i]	<=	idu_iex_general_sel_src2_rs2_q[i];
		idu_iex_flag_unsigned_data_reg[i]			<=	idu_iex_unsigned_data_q[i];
		idu_iex_flag_adder_vld_reg[i]				<=	idu_iex_adder_vld_q[i];
		idu_iex_flag_adder_sub_reg[i]				<=	idu_iex_adder_sub_q[i];
		idu_iex_flag_comparator_vld_reg[i]			<=	idu_iex_comparator_vld_q[i];
		idu_iex_flag_logical_plane_and_reg[i]		<=	idu_iex_logical_plane_and_q[i];
		idu_iex_flag_logical_plane_or_reg[i]		<=	idu_iex_logical_plane_or_q[i];
		idu_iex_flag_logical_plane_xor_reg[i]		<=	idu_iex_logical_plane_xor_q[i];
		idu_iex_flag_shifter_right_shift_reg[i]		<=	idu_iex_shifter_right_shift_q[i];
		idu_iex_flag_shifter_logical_shift_reg[i]	<=	idu_iex_shifter_logical_shift_q[i];
		idu_iex_flag_bru_jal_reg[i]				<=	idu_iex_bru_jal_q[i];
		idu_iex_flag_bru_jalr_reg[i]				<=	idu_iex_bru_jalr_q[i];
		idu_iex_flag_bru_bge_reg[i]					<=	idu_iex_bru_bge_q[i];
		idu_iex_flag_bru_blt_reg[i]					<=	idu_iex_bru_blt_q[i];
		idu_iex_flag_bru_beq_reg[i]					<=	idu_iex_bru_beq_q[i];
		idu_iex_flag_bru_bne_reg[i]					<=	idu_iex_bru_bne_q[i];
		idu_iex_flag_dmem_lb_reg[i]					<=	idu_iex_lsu_sel_lb_q[i];
		idu_iex_flag_dmem_lh_reg[i]					<=	idu_iex_lsu_sel_lh_q[i];
		idu_iex_flag_dmem_lw_reg[i]					<=	idu_iex_lsu_sel_lw_q[i];
		idu_iex_flag_dmem_sw_reg[i]					<=	idu_iex_lsu_sel_sw_q[i];
		idu_iex_flag_dmem_sb_reg[i]					<=	idu_iex_lsu_sel_sb_q[i];
		idu_iex_flag_dmem_sh_reg[i]					<=	idu_iex_lsu_sel_sh_q[i];
		idu_iex_rf_wen_reg[i]						<=	idu_iex_rf_wen_q[i];
	end
end
end
//ALU output interface assignment
assign	idu_iex_pc						=	idu_iex_pc_reg;
assign	idu_iex_csr_wfi_vld							=	idu_iex_csr_wfi_vld_reg;
assign	idu_iex_csr_exception_vld					=	idu_iex_csr_exception_vld_reg;
assign	idu_iex_csr_exceptions						=	idu_iex_csr_exceptions_reg;
assign	idu_iex_rs1_data							=	idu_iex_rs1_data_reg;
assign	idu_iex_rs2_data							=	idu_iex_rs2_data_reg;
assign	idu_iex_imm_data							=	idu_iex_imm_data_reg;
assign	idu_iex_rd									=	idu_iex_rd_reg;
assign	idu_iex_rd_vld								=	idu_iex_rd_vld_reg;
assign	idu_iex_pipe_vld							=	idu_iex_pipe_vld_reg;
assign	idu_iex_is_load								=	idu_iex_is_load_reg;
assign	idu_iex_flag_adder_sel_src1_pc				=	idu_iex_flag_adder_sel_src1_pc_reg;
assign	idu_iex_flag_adder_sel_src2_rs2				=	idu_iex_flag_adder_sel_src2_rs2_reg;
assign	idu_iex_flag_general_sel_src2_rs2			=	idu_iex_flag_general_sel_src2_rs2_reg;
assign	idu_iex_flag_unsigned_data					=	idu_iex_flag_unsigned_data_reg;
assign	idu_iex_flag_adder_vld						=	idu_iex_flag_adder_vld_reg;
assign	idu_iex_flag_adder_sub						=	idu_iex_flag_adder_sub_reg;
assign	idu_iex_flag_comparator_vld					=	idu_iex_flag_comparator_vld_reg;
assign	idu_iex_flag_logical_plane_and				=	idu_iex_flag_logical_plane_and_reg;
assign	idu_iex_flag_logical_plane_or				=	idu_iex_flag_logical_plane_or_reg;
assign	idu_iex_flag_logical_plane_xor				=	idu_iex_flag_logical_plane_xor_reg;
assign	idu_iex_flag_shifter_right_shift			=	idu_iex_flag_shifter_right_shift_reg;
assign	idu_iex_flag_shifter_logical_shift			=	idu_iex_flag_shifter_logical_shift_reg;
assign	idu_iex_flag_bru_jal						=	idu_iex_flag_bru_jal_reg;
assign	idu_iex_flag_bru_jalr						=	idu_iex_flag_bru_jalr_reg;
assign	idu_iex_flag_bru_bge						=	idu_iex_flag_bru_bge_reg;
assign	idu_iex_flag_bru_blt						=	idu_iex_flag_bru_blt_reg;
assign	idu_iex_flag_bru_beq						=	idu_iex_flag_bru_beq_reg;
assign	idu_iex_flag_bru_bne						=	idu_iex_flag_bru_bne_reg;
assign	idu_iex_flag_dmem_lb						=	idu_iex_flag_dmem_lb_reg;
assign	idu_iex_flag_dmem_lh						=	idu_iex_flag_dmem_lh_reg;
assign	idu_iex_flag_dmem_lw						=	idu_iex_flag_dmem_lw_reg;
assign	idu_iex_flag_dmem_sw						=	idu_iex_flag_dmem_sw_reg;
assign	idu_iex_flag_dmem_sb						=	idu_iex_flag_dmem_sb_reg;
assign	idu_iex_flag_dmem_sh						=	idu_iex_flag_dmem_sh_reg;
assign	idu_iex_rf_wen								=	idu_iex_rf_wen_reg;

//Dispatcher IFU output
//Signal to IFU is wire type
assign idu_ifu_detect_exceptions_wfi				=	dispatcher_detect_exceptions_wfi;

`ifdef ALPHATENSOR
//AlphaTensor Output
	assign	idu_alphaTensor_matrix_mul_vld			=	idu_alphaTensor_matrix_mul_vld_reg;
	assign	idu_alphaTensor_matrix_mem_rs1_idx		=	idu_alphaTensor_matrix_mem_rs1_idx_reg;
	assign	idu_alphaTensor_matrix_mem_rs2_idx		=	idu_alphaTensor_matrix_mem_rs2_idx_reg;
	assign	idu_alphaTensor_matrix_mem_rd_idx		=	idu_alphaTensor_matrix_mem_rd_idx_reg;
		always @ (posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			idu_alphaTensor_matrix_mul_vld_reg 		<= 1'b0;
		end
		else begin
			idu_alphaTensor_matrix_mul_vld_reg 		<= (dispatch_vld_q[0] & idu_alphaTensor_matrix_mul_vld_q[0]) | (dispatch_vld_q[1] & idu_alphaTensor_matrix_mul_vld_q[1]);
		end
	end
	always @ (posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			idu_alphaTensor_matrix_mem_rs1_idx_reg	<= 'b0;
			idu_alphaTensor_matrix_mem_rs2_idx_reg	<= 'b0;
			idu_alphaTensor_matrix_mem_rd_idx_reg	<= 'b0;
		end
		else if((dispatch_vld_q[0] & idu_alphaTensor_matrix_mul_vld_q[0]) | (dispatch_vld_q[1] & idu_alphaTensor_matrix_mul_vld_q[1])) begin
			idu_alphaTensor_matrix_mem_rs1_idx_reg	<= (dispatch_vld_q[0] & idu_alphaTensor_matrix_mul_vld_q[0])? idu_alphaTensor_matrix_mem_rs1_idx_q[0] : idu_alphaTensor_matrix_mem_rs1_idx_q[1];
			idu_alphaTensor_matrix_mem_rs2_idx_reg	<= (dispatch_vld_q[0] & idu_alphaTensor_matrix_mul_vld_q[0])? idu_alphaTensor_matrix_mem_rs2_idx_q[0] : idu_alphaTensor_matrix_mem_rs2_idx_q[1];
			idu_alphaTensor_matrix_mem_rd_idx_reg	<= (dispatch_vld_q[0] & idu_alphaTensor_matrix_mul_vld_q[0])? idu_alphaTensor_matrix_mem_rd_idx_q[0] : idu_alphaTensor_matrix_mem_rd_idx_q[1];		
		end
	end
`endif

//-----------------------end--------------------//



endmodule
