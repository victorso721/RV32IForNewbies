module u_riscv (
	input				clk					,
	input				rst_n					,
	input				start_pulse				,
	input	[`PC_WIDTH-1:0]		start_pc				,
	input	[`EXCEPTION_NUM-1:0]	core_configuration			, 
	output 	[1:0] 			core_status				,
	output 	[`EXCEPTION_NUM-1:0] 	core_exceptions				,
	output 	[`PC_WIDTH-1:0]		core_exceptions_pc			


);
//interconnection
//To avoid wire dupilcation, only output is considered
//CSR output
wire 	[1:0] 				csr_core_status				;
wire 	[`EXCEPTION_NUM-1:0]		csr_core_configuration			;
wire 	[`EXCEPTION_NUM-1:0] 		csr_core_exceptions			;
wire 	[`PC_WIDTH-1:0]			csr_core_exceptions_pc			;

//IFU output
wire					ifu_csr_start_pulse			;
wire	[`EXCEPTION_NUM-1:0]		ifu_csr_core_configuration		;
wire 					ifu_idu_pipe_vld			;
wire	[`PC_WIDTH-1:0] 		ifu_idu_pc				[`SUPER_SCALAR_NUM-1:0];
wire	[`INST_WIDTH-1:0] 		ifu_idu_inst				[`SUPER_SCALAR_NUM-1:0];
wire 					ifu_idu_pc_unalign			[`SUPER_SCALAR_NUM-1:0];
//IDU output
wire					idu_ifu_instBuffer_full			;
wire					idu_ifu_detect_exceptions_wfi		;
`ifdef ALPHATENSOR
wire					idu_alphaTensor_matrix_mul_vld		;
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx	;
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx	;
wire	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx	;
`endif
wire					idu_iex_csr_wfi_vld			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_csr_exception_vld		[`SUPER_SCALAR_NUM-1:0];
wire	[`EXCEPTION_NUM-1:0]		idu_iex_csr_exceptions			[`SUPER_SCALAR_NUM-1:0];
wire	[`PC_WIDTH-1:0]			idu_iex_pc				[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_rs1_data			[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_rs2_data			[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		idu_iex_imm_data			[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		idu_iex_rd				[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_rd_vld				[`SUPER_SCALAR_NUM-1:0]; 
wire					idu_iex_pipe_vld			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_is_load				[`SUPER_SCALAR_NUM-1:0]; 
wire					idu_iex_flag_adder_sel_src1_pc		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_adder_sel_src2_rs2		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_general_sel_src2_rs2	[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_unsigned_data		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_adder_vld			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_adder_sub			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_comparator_vld		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_logical_plane_and		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_logical_plane_or		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_logical_plane_xor		[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_shifter_right_shift	[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_shifter_logical_shift	[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_jal			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_jalr			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_bge			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_blt			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_beq			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_bru_bne			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_lb			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_lh			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_lw			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_sw			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_sb			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_flag_dmem_sh			[`SUPER_SCALAR_NUM-1:0];
wire					idu_iex_rf_wen				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0] 		idu_rf_rs1_idx				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0] 		idu_rf_rs2_idx				[`SUPER_SCALAR_NUM-1:0];

//IEX output
wire					iex_csr_wfi_vld				;
wire					iex_csr_exception_vld			;
wire	[`EXCEPTION_NUM-1:0]		iex_csr_exceptions			;
wire	[`PC_WIDTH-1:0]			iex_csr_exception_pc			;
wire					iex_ifu_report_exceptions_wfi		;
wire					iex_idu_pipe_vld			[`SUPER_SCALAR_NUM-1:0];
wire 					iex_idu_is_load				[`SUPER_SCALAR_NUM-1:0];
wire 					iex_idu_rd_vld				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		iex_idu_byp_rd				[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0] 		iex_idu_byp_data			[`SUPER_SCALAR_NUM-1:0];
wire					iex_bru_vld				;	//reserved for dynamic prediction training
wire 					iex_bru_flush				;
wire	[`PC_WIDTH-1:0]			iex_bru_redir_pc			;
wire 					iex_lsu_pipe_vld 			[`SUPER_SCALAR_NUM-1:0];
wire	[`PC_WIDTH-1:0]			iex_lsu_pc				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		iex_lsu_rd				[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_rd_vld				[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_is_load				[`SUPER_SCALAR_NUM-1:0];	
wire	[`DATA_WIDTH-1:0]		iex_lsu_cal_data			[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		iex_lsu_dmem_wr_data			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire	[`DATA_WIDTH-1:0]		iex_lsu_dmem_addr			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire					iex_lsu_dmem_ren			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire					iex_lsu_flag_unsigned_data		[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_flag_dmem_lb			[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_flag_dmem_lh			[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_flag_dmem_lw			[`SUPER_SCALAR_NUM-1:0];
wire					iex_lsu_flag_dmem_sw			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire					iex_lsu_flag_dmem_sb			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire					iex_lsu_flag_dmem_sh			[`SUPER_SCALAR_NUM-1:0];	//Not flopped
wire					iex_lsu_rf_wen				[`SUPER_SCALAR_NUM-1:0];

//LSU output
wire	[`PC_WIDTH-1:0]			lsu_rf_pc				[`SUPER_SCALAR_NUM-1:0];
wire					lsu_rf_pipe_vld				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		lsu_rf_rd				[`SUPER_SCALAR_NUM-1:0];
wire					lsu_rf_wen				[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		lsu_rf_wr_data				[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		lsu_idu_byp_data			[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		lsu_idu_byp_rd				[`SUPER_SCALAR_NUM-1:0];
wire					lsu_idu_pipe_vld			[`SUPER_SCALAR_NUM-1:0];
wire					lsu_idu_rd_vld				[`SUPER_SCALAR_NUM-1:0];
wire					lsu_idu_is_load				[`SUPER_SCALAR_NUM-1:0];

//RF output
wire	[`DATA_WIDTH-1:0]		rf_idu_rs1_data				[`RF_READ_PORT_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		rf_idu_rs2_data				[`RF_READ_PORT_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		rf_idu_byp_data				[`SUPER_SCALAR_NUM-1:0];
wire					rf_idu_pipe_vld				[`SUPER_SCALAR_NUM-1:0];
wire					rf_idu_rd_vld				[`SUPER_SCALAR_NUM-1:0];
wire	[`RF_DEPTH_BIT-1:0]		rf_idu_byp_rd				[`SUPER_SCALAR_NUM-1:0];

//SoC output interface
assign	core_status		=	csr_core_status				;
assign	core_exceptions		=	csr_core_exceptions			;
assign	core_exceptions_pc	=	csr_core_exceptions_pc			;

//Module declaration
//CSR
u_csr csr(
	.clk						(clk),
	.rst_n						(rst_n),
	.sync_start_pulse				(ifu_csr_start_pulse),
	.sync_core_configuration			(ifu_csr_core_configuration),
	.iex_csr_wfi_vld				(iex_csr_wfi_vld),	
	.iex_csr_exception_vld				(iex_csr_exception_vld),
	.iex_csr_exceptions				(iex_csr_exceptions),	
	.iex_csr_exception_pc				(iex_csr_exception_pc), 		
	.core_status					(csr_core_status),
	.core_configuration				(csr_core_configuration),
	.core_exceptions				(csr_core_exceptions),
	.core_exceptions_pc				(csr_core_exceptions_pc)
);
//IFU
u_ifu ifu(
	.clk						(clk),
	.rst_n						(rst_n),
	.start_pulse					(start_pulse),
	.start_pc					(start_pc),
	.core_configuration				(core_configuration),	
	.core_status					(csr_core_status),
	.idu_ifu_instBuffer_full			(idu_ifu_instBuffer_full),
	.idu_ifu_detect_exceptions_wfi			(idu_ifu_detect_exceptions_wfi),
	.iex_ifu_report_exceptions_wfi			(iex_ifu_report_exceptions_wfi),	
	.iex_ifu_bru_flush				(iex_bru_flush),			
	.iex_ifu_bru_redir_pc				(iex_bru_redir_pc),			
	.ifu_csr_start_pulse				(ifu_csr_start_pulse),
	.ifu_csr_core_configuration			(ifu_csr_core_configuration),
	.ifu_idu_pipe_vld 				(ifu_idu_pipe_vld),
	.ifu_idu_pc_1	 				(ifu_idu_pc[0]),
	.ifu_idu_pc_2		 			(ifu_idu_pc[1]),
	.ifu_idu_inst_1 				(ifu_idu_inst[0]),
	.ifu_idu_inst_2					(ifu_idu_inst[1]),
	.ifu_idu_pc_unalign_1 				(ifu_idu_pc_unalign[0]),
	.ifu_idu_pc_unalign_2 				(ifu_idu_pc_unalign[1])
);
//IDU
u_idu_super_scalar_wrapper idu(
	.clk						(clk),
	.rst_n						(rst_n),
	.csr_idu_core_configuration			(csr_core_configuration),
	.sync_start_pulse				(ifu_csr_start_pulse),
	.ifu_idu_pipe_vld				(ifu_idu_pipe_vld),
	.ifu_idu_pc 					(ifu_idu_pc),
	.ifu_idu_inst 					(ifu_idu_inst),
	.ifu_idu_pc_unalign				(ifu_idu_pc_unalign),
	.iex_idu_bru_flush				(iex_bru_flush),		
	.iex_idu_pipe_vld				(iex_idu_pipe_vld),	
	.iex_idu_is_load				(iex_idu_is_load),	
	.iex_idu_rd_vld					(iex_idu_rd_vld),	
	.iex_idu_byp_rd					(iex_idu_byp_rd),	
	.iex_idu_byp_data				(iex_idu_byp_data),	
	.lsu_idu_pipe_vld				(lsu_idu_pipe_vld),	
	.lsu_idu_is_load				(lsu_idu_is_load),	
	.lsu_idu_rd_vld					(lsu_idu_rd_vld),	
	.lsu_idu_byp_rd					(lsu_idu_byp_rd),	
	.lsu_idu_byp_data				(lsu_idu_byp_data),	
	.rf_idu_pipe_vld				(rf_idu_pipe_vld),	
	.rf_idu_rd_vld					(rf_idu_rd_vld),		
	.rf_idu_byp_rd					(rf_idu_byp_rd),		
	.rf_idu_byp_data				(rf_idu_byp_data),	
	.rf_idu_rs1_data				(rf_idu_rs1_data),
	.rf_idu_rs2_data				(rf_idu_rs2_data),
	.idu_ifu_instBuffer_full			(idu_ifu_instBuffer_full),
	.idu_ifu_detect_exceptions_wfi			(idu_ifu_detect_exceptions_wfi),
	`ifdef ALPHATENSOR
	.idu_alphaTensor_matrix_mul_vld			(idu_alphaTensor_matrix_mul_vld),
	.idu_alphaTensor_matrix_mem_rs1_idx		(idu_alphaTensor_matrix_mem_rs1_idx),
	.idu_alphaTensor_matrix_mem_rs2_idx		(idu_alphaTensor_matrix_mem_rs2_idx),
	.idu_alphaTensor_matrix_mem_rd_idx		(idu_alphaTensor_matrix_mem_rd_idx),
	`endif
	.idu_iex_csr_wfi_vld				(idu_iex_csr_wfi_vld),
	.idu_iex_csr_exception_vld			(idu_iex_csr_exception_vld),
	.idu_iex_csr_exceptions				(idu_iex_csr_exceptions),
	.idu_iex_pc					(idu_iex_pc),
	.idu_iex_rs1_data				(idu_iex_rs1_data),
	.idu_iex_rs2_data				(idu_iex_rs2_data),
	.idu_iex_imm_data				(idu_iex_imm_data),
	.idu_iex_rd					(idu_iex_rd),
	.idu_iex_rd_vld					(idu_iex_rd_vld), 
	.idu_iex_pipe_vld				(idu_iex_pipe_vld),
	.idu_iex_is_load				(idu_iex_is_load), 
	.idu_iex_flag_adder_sel_src1_pc			(idu_iex_flag_adder_sel_src1_pc),
	.idu_iex_flag_adder_sel_src2_rs2		(idu_iex_flag_adder_sel_src2_rs2),
	.idu_iex_flag_general_sel_src2_rs2		(idu_iex_flag_general_sel_src2_rs2),
	.idu_iex_flag_unsigned_data			(idu_iex_flag_unsigned_data),
	.idu_iex_flag_adder_vld				(idu_iex_flag_adder_vld),
	.idu_iex_flag_adder_sub				(idu_iex_flag_adder_sub),
	.idu_iex_flag_comparator_vld			(idu_iex_flag_comparator_vld),
	.idu_iex_flag_logical_plane_and			(idu_iex_flag_logical_plane_and),
	.idu_iex_flag_logical_plane_or			(idu_iex_flag_logical_plane_or),
	.idu_iex_flag_logical_plane_xor			(idu_iex_flag_logical_plane_xor),
	.idu_iex_flag_shifter_right_shift		(idu_iex_flag_shifter_right_shift),
	.idu_iex_flag_shifter_logical_shift		(idu_iex_flag_shifter_logical_shift),
	.idu_iex_flag_bru_jal				(idu_iex_flag_bru_jal),
	.idu_iex_flag_bru_jalr				(idu_iex_flag_bru_jalr),
	.idu_iex_flag_bru_bge				(idu_iex_flag_bru_bge),
	.idu_iex_flag_bru_blt				(idu_iex_flag_bru_blt),
	.idu_iex_flag_bru_beq				(idu_iex_flag_bru_beq),
	.idu_iex_flag_bru_bne				(idu_iex_flag_bru_bne),
	.idu_iex_flag_dmem_lb				(idu_iex_flag_dmem_lb),
	.idu_iex_flag_dmem_lh				(idu_iex_flag_dmem_lh),
	.idu_iex_flag_dmem_lw				(idu_iex_flag_dmem_lw),
	.idu_iex_flag_dmem_sw				(idu_iex_flag_dmem_sw),
	.idu_iex_flag_dmem_sb				(idu_iex_flag_dmem_sb),
	.idu_iex_flag_dmem_sh				(idu_iex_flag_dmem_sh),
	.idu_iex_rf_wen					(idu_iex_rf_wen),
	.idu_rf_rs1_idx					(idu_rf_rs1_idx),
	.idu_rf_rs2_idx					(idu_rf_rs2_idx)
);
//IEX

u_iex_super_scalar_wrapper iex (
	.clk						(clk),
	.rst_n						(rst_n),
	`ifdef ALPHATENSOR
	.idu_alphaTensor_matrix_mul_vld			(idu_alphaTensor_matrix_mul_vld),
	.idu_alphaTensor_matrix_mem_rs1_idx		(idu_alphaTensor_matrix_mem_rs1_idx),
	.idu_alphaTensor_matrix_mem_rs2_idx		(idu_alphaTensor_matrix_mem_rs2_idx),
	.idu_alphaTensor_matrix_mem_rd_idx		(idu_alphaTensor_matrix_mem_rd_idx),
	`endif
	.idu_iex_csr_wfi_vld				(idu_iex_csr_wfi_vld),
	.idu_iex_csr_exception_vld			(idu_iex_csr_exception_vld),
	.idu_iex_csr_exceptions				(idu_iex_csr_exceptions),
	.idu_iex_pc					(idu_iex_pc),
	.idu_iex_rs1_data				(idu_iex_rs1_data),
	.idu_iex_rs2_data				(idu_iex_rs2_data),
	.idu_iex_imm_data				(idu_iex_imm_data),
	.idu_iex_rd					(idu_iex_rd),
	.idu_iex_rd_vld					(idu_iex_rd_vld),
	.idu_iex_pipe_vld				(idu_iex_pipe_vld),
	.idu_iex_is_load				(idu_iex_is_load),
	.idu_iex_flag_adder_sel_src1_pc			(idu_iex_flag_adder_sel_src1_pc),
	.idu_iex_flag_adder_sel_src2_rs2		(idu_iex_flag_adder_sel_src2_rs2),
	.idu_iex_flag_general_sel_src2_rs2		(idu_iex_flag_general_sel_src2_rs2),
	.idu_iex_flag_unsigned_data			(idu_iex_flag_unsigned_data),
	.idu_iex_flag_adder_vld				(idu_iex_flag_adder_vld),
	.idu_iex_flag_adder_sub				(idu_iex_flag_adder_sub),
	.idu_iex_flag_comparator_vld			(idu_iex_flag_comparator_vld),
	.idu_iex_flag_logical_plane_and			(idu_iex_flag_logical_plane_and),
	.idu_iex_flag_logical_plane_or			(idu_iex_flag_logical_plane_or),
	.idu_iex_flag_logical_plane_xor			(idu_iex_flag_logical_plane_xor),
	.idu_iex_flag_shifter_right_shift		(idu_iex_flag_shifter_right_shift),
	.idu_iex_flag_shifter_logical_shift		(idu_iex_flag_shifter_logical_shift),
	.idu_iex_flag_bru_jal				(idu_iex_flag_bru_jal),
	.idu_iex_flag_bru_jalr				(idu_iex_flag_bru_jalr),
	.idu_iex_flag_bru_bge				(idu_iex_flag_bru_bge),
	.idu_iex_flag_bru_blt				(idu_iex_flag_bru_blt),
	.idu_iex_flag_bru_beq				(idu_iex_flag_bru_beq),
	.idu_iex_flag_bru_bne				(idu_iex_flag_bru_bne),
	.idu_iex_flag_dmem_lb				(idu_iex_flag_dmem_lb),
	.idu_iex_flag_dmem_lh				(idu_iex_flag_dmem_lh),
	.idu_iex_flag_dmem_lw				(idu_iex_flag_dmem_lw),
	.idu_iex_flag_dmem_sw				(idu_iex_flag_dmem_sw),
	.idu_iex_flag_dmem_sb				(idu_iex_flag_dmem_sb),
	.idu_iex_flag_dmem_sh				(idu_iex_flag_dmem_sh),
	.idu_iex_rf_wen					(idu_iex_rf_wen),
	.iex_csr_wfi_vld				(iex_csr_wfi_vld),
	.iex_csr_exception_vld				(iex_csr_exception_vld),
	.iex_csr_exceptions				(iex_csr_exceptions),
	.iex_csr_exception_pc				(iex_csr_exception_pc),
	.iex_ifu_report_exceptions_wfi			(iex_ifu_report_exceptions_wfi),
	.iex_idu_pipe_vld				(iex_idu_pipe_vld),
	.iex_idu_is_load				(iex_idu_is_load),
	.iex_idu_rd_vld					(iex_idu_rd_vld),
	.iex_idu_rd					(iex_idu_byp_rd),
	.iex_idu_byp_data				(iex_idu_byp_data),
	.iex_bru_vld					(iex_bru_vld),
	.iex_bru_flush					(iex_bru_flush),
	.iex_bru_redir_pc				(iex_bru_redir_pc),
	.iex_lsu_pipe_vld				(iex_lsu_pipe_vld),
	.iex_lsu_pc					(iex_lsu_pc),
	.iex_lsu_rd					(iex_lsu_rd),
	.iex_lsu_rd_vld					(iex_lsu_rd_vld),
	.iex_lsu_is_load				(iex_lsu_is_load),
	.iex_lsu_cal_data				(iex_lsu_cal_data),
	.iex_lsu_dmem_wr_data				(iex_lsu_dmem_wr_data),
	.iex_lsu_dmem_addr				(iex_lsu_dmem_addr),
	.iex_lsu_dmem_ren				(iex_lsu_dmem_ren),
	.iex_lsu_flag_unsigned_data			(iex_lsu_flag_unsigned_data),
	.iex_lsu_flag_dmem_lb				(iex_lsu_flag_dmem_lb),
	.iex_lsu_flag_dmem_lh				(iex_lsu_flag_dmem_lh),
	.iex_lsu_flag_dmem_lw				(iex_lsu_flag_dmem_lw),
	.iex_lsu_flag_dmem_sw				(iex_lsu_flag_dmem_sw),
	.iex_lsu_flag_dmem_sb				(iex_lsu_flag_dmem_sb),
	.iex_lsu_flag_dmem_sh				(iex_lsu_flag_dmem_sh),
	.iex_lsu_rf_wen					(iex_lsu_rf_wen)
);

//LSU

u_lsu_super_scalar_wrapper lsu (
	.clk						(clk),
	.rst_n						(rst_n),
	.iex_lsu_pipe_vld				(iex_lsu_pipe_vld),
	.iex_lsu_pc					(iex_lsu_pc),
	.iex_lsu_rd					(iex_lsu_rd),
	.iex_lsu_is_load				(iex_lsu_is_load),
	.iex_lsu_rd_vld					(iex_lsu_rd_vld),
	.iex_lsu_rf_wen					(iex_lsu_rf_wen),
	.iex_lsu_cal_data				(iex_lsu_cal_data),
	.iex_lsu_dmem_wr_data				(iex_lsu_dmem_wr_data),
	.iex_lsu_dmem_addr				(iex_lsu_dmem_addr),
	.iex_lsu_dmem_ren				(iex_lsu_dmem_ren),
	.iex_lsu_flag_unsigned_data			(iex_lsu_flag_unsigned_data),
	.iex_lsu_flag_dmem_lb				(iex_lsu_flag_dmem_lb),
	.iex_lsu_flag_dmem_lh				(iex_lsu_flag_dmem_lh),
	.iex_lsu_flag_dmem_lw				(iex_lsu_flag_dmem_lw),
	.iex_lsu_flag_dmem_sw				(iex_lsu_flag_dmem_sw),
	.iex_lsu_flag_dmem_sb				(iex_lsu_flag_dmem_sb),
	.iex_lsu_flag_dmem_sh				(iex_lsu_flag_dmem_sh),
	.lsu_rf_pc					(lsu_rf_pc),
	.lsu_rf_pipe_vld				(lsu_rf_pipe_vld),
	.lsu_rf_wen					(lsu_rf_wen),			
	.lsu_rf_rd					(lsu_rf_rd),
	.lsu_rf_wr_data					(lsu_rf_wr_data),
	.lsu_idu_pipe_vld				(lsu_idu_pipe_vld),
	.lsu_idu_is_load				(lsu_idu_is_load),
	.lsu_idu_rd_vld					(lsu_idu_rd_vld),
	.lsu_idu_rd					(lsu_idu_byp_rd),
	.lsu_idu_byp_data				(lsu_idu_byp_data)
);

//RF
u_rf rf (
	.clk						(clk),
	.rst_n						(rst_n),
	.lsu_rf_pc					(lsu_rf_pc),		
	.lsu_rf_pipe_vld				(lsu_rf_pipe_vld),	
	.lsu_rf_wen					(lsu_rf_wen),				
	.lsu_rf_rd					(lsu_rf_rd),		
	.lsu_rf_wr_data					(lsu_rf_wr_data),	
	.idu_rf_rs1_idx					(idu_rf_rs1_idx),
	.idu_rf_rs2_idx					(idu_rf_rs2_idx),
	.rf_idu_rs1_data				(rf_idu_rs1_data),
	.rf_idu_rs2_data				(rf_idu_rs2_data),
	.rf_idu_byp_data				(rf_idu_byp_data),		
	.rf_idu_pipe_vld				(rf_idu_pipe_vld),		
	.rf_idu_rd_vld					(rf_idu_rd_vld),
	.rf_idu_rd					(rf_idu_byp_rd)			
);
endmodule
