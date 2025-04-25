module u_idu (

	//IFU input
	input [`INST_WIDTH-1:0] 	instBuffer_idu_inst_in,

	//ALU input
	input						iex_idu_pipe_vld	[`SUPER_SCALAR_NUM-1:0],
	input 						iex_idu_is_load		[`SUPER_SCALAR_NUM-1:0],
	input 						iex_idu_rd_vld		[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]	iex_idu_byp_rd		[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 	iex_idu_byp_data	[`SUPER_SCALAR_NUM-1:0],
	
	//LSU input 
	input						lsu_idu_pipe_vld	[`SUPER_SCALAR_NUM-1:0],
	input 						lsu_idu_is_load		[`SUPER_SCALAR_NUM-1:0],
	input						lsu_idu_rd_vld		[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]	lsu_idu_byp_rd		[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 	lsu_idu_byp_data	[`SUPER_SCALAR_NUM-1:0],
	
	//RF input
	input						rf_idu_pipe_vld		[`SUPER_SCALAR_NUM-1:0],
	input						rf_idu_rd_vld		[`SUPER_SCALAR_NUM-1:0],
	input [`RF_DEPTH_BIT-1:0]	rf_idu_byp_rd		[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 	rf_idu_byp_data		[`SUPER_SCALAR_NUM-1:0],
	input [`DATA_WIDTH-1:0] 	rf_idu_rs1_data		,
	input [`DATA_WIDTH-1:0] 	rf_idu_rs2_data		,
	
	//IDU Dispatcher output
	output						idu_dispatcher_rd_vld,
	output						idu_dispatcher_rs1_vld,
	output						idu_dispatcher_rs2_vld,
	output						idu_dispatcher_wfi_vld,
	output 						idu_dispatcher_stall_vld,
	output						idu_dispatcher_exception_illegal_inst,
	output						idu_dispatcher_dmem_load,
	output						idu_dispatcher_dmem_store,

	//ALU output
	`ifdef ALPHATENSOR
		//AlphaTensor output
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx,
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx,
		output	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx,
		output					idu_alphaTensor_matrix_mul_vld,
	`endif
	//Data output
	output [`DATA_WIDTH-1:0] 	idu_iex_rs1_data	,
	output [`DATA_WIDTH-1:0] 	idu_iex_rs2_data	,
	output [`DATA_WIDTH-1:0] 	idu_iex_imm_data	,
	output [`RF_DEPTH_BIT-1:0] 	idu_iex_rd			,
	//Control output
	//Data selection control flag in ALU
	output						idu_iex_adder_sel_src1_pc,
	output						idu_iex_adder_sel_src2_rs2,
	output						idu_iex_general_sel_src2_rs2,
	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	output						idu_iex_unsigned_data,
	//Adder
	output						idu_iex_adder_vld,
	output						idu_iex_adder_sub,
	//Comparator
	output						idu_iex_comparator_vld,
	//logical plane
	output						idu_iex_logical_plane_and,
	output						idu_iex_logical_plane_or,
	output						idu_iex_logical_plane_xor,
	//Shifter
	output						idu_iex_shifter_right_shift,
	output						idu_iex_shifter_logical_shift,
	//BRU
	output						idu_iex_bru_jal,
	output						idu_iex_bru_jalr,
	output						idu_iex_bru_bge,
	output						idu_iex_bru_blt,
	output						idu_iex_bru_beq,
	output						idu_iex_bru_bne,
	//Memory access flag
	output						idu_iex_lsu_sel_lb,
	output						idu_iex_lsu_sel_lh,
	output						idu_iex_lsu_sel_lw,
	output						idu_iex_lsu_sel_sw,
	output						idu_iex_lsu_sel_sb,
	output						idu_iex_lsu_sel_sh,
	//Control flag for RF
	output						idu_iex_rf_wen,

	//RF output
	output [`RF_DEPTH_BIT-1:0] 	idu_rf_rs1_idx		,
	output [`RF_DEPTH_BIT-1:0] 	idu_rf_rs2_idx		

);

//Internal signal
wire						instDecode_bypassMUX_inst_rs1_vld;
wire						instDecode_bypassMUX_inst_rs2_vld;
assign	idu_dispatcher_rs1_vld	=	instDecode_bypassMUX_inst_rs1_vld;
assign	idu_dispatcher_rs2_vld	=	instDecode_bypassMUX_inst_rs2_vld;
//Instruction decoding
//Grouping instruction into uop
//type of operation in ALU, unsigned integer
//BRU vld, is branch.jump bit
//Memory access vld, is load/store bit
//RF wrtie enable
//choose imm data
//decode

u_idu_instDecode instDecode(

	//Instruction input
	.inst						(instBuffer_idu_inst_in),

	//Decode result
	//Exception result
	.illegal_inst				(idu_dispatcher_exception_illegal_inst),
	
	//SYSTEM instruction
	.wfi						(idu_dispatcher_wfi_vld),
	
	//Imm data output
	.imm_data_out				(idu_iex_imm_data),

	//Data selection control flag within IDU
	.inst_rs1_vld				(instDecode_bypassMUX_inst_rs1_vld),
	.inst_rs2_vld				(instDecode_bypassMUX_inst_rs2_vld),
	.inst_rd_vld				(idu_dispatcher_rd_vld),		//Also pass to ALU LSU for bypass detecting
	.dmem_load					(idu_dispatcher_dmem_load),		//Also pass to ALU LSU for indicating LOAD instruction
	.dmem_store					(idu_dispatcher_dmem_store),		
	
	//Data selection control flag in ALU
	.alu_adder_sel_src1_pc		(idu_iex_adder_sel_src1_pc),
	.alu_adder_sel_src2_rs2		(idu_iex_adder_sel_src2_rs2),
	.alu_general_sel_src2_rs2	(idu_iex_general_sel_src2_rs2),

	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	.unsigned_data				(idu_iex_unsigned_data),
	//Adder
	.adder_vld					(idu_iex_adder_vld),
	.adder_sub					(idu_iex_adder_sub),
	//Comparator
	.comparator_vld				(idu_iex_comparator_vld),
	//logical plane
	.logical_plane_and			(idu_iex_logical_plane_and),
	.logical_plane_or			(idu_iex_logical_plane_or),
	.logical_plane_xor			(idu_iex_logical_plane_xor),
	//Shifter
	.shifter_right_shift		(idu_iex_shifter_right_shift),
	.shifter_logical_shift		(idu_iex_shifter_logical_shift),

	//BRU
	.bru_jal					(idu_iex_bru_jal),
	.bru_jalr					(idu_iex_bru_jalr),
	.bru_bge					(idu_iex_bru_bge),
	.bru_blt					(idu_iex_bru_blt),
	.bru_beq					(idu_iex_bru_beq),
	.bru_bne					(idu_iex_bru_bne),

	//Memory access flag
	.lb						(idu_iex_lsu_sel_lb),
	.lh						(idu_iex_lsu_sel_lh),
	.lw						(idu_iex_lsu_sel_lw),
	.sw						(idu_iex_lsu_sel_sw),
	.sb						(idu_iex_lsu_sel_sb),
	.sh						(idu_iex_lsu_sel_sh),

	//Control flag for RF
	.rf_wen						(idu_iex_rf_wen),

	//Extended rs1, rs2, rd for accelerator
	`ifdef ALPHATENSOR
		.matrix_mem_rs1_idx			(idu_alphaTensor_matrix_mem_rs1_idx),
		.matrix_mem_rs2_idx			(idu_alphaTensor_matrix_mem_rs2_idx),
		.matrix_mem_rd_idx			(idu_alphaTensor_matrix_mem_rd_idx),
		//inst vld for matrix multiplication
		.matrix_mul_vld				(idu_alphaTensor_matrix_mul_vld),
	`endif

	//RS1,RS2 output, for RF
	.rf_rs1_idx					(idu_rf_rs1_idx),
	.rf_rs2_idx					(idu_rf_rs2_idx),

	//RD
	.rf_rd_idx					(idu_iex_rd)
);

//Data forwarding
//Compare rs1/rs2 with rd
//check if it is load operation, give stall signal if data hazard cannot be avoid
//Remarks: no data bypassing from DMEM output to IDU, due to timing concern, MEM stage only has bypassing path from ALU result side to IDU
//select the earliest valid forwarding path
//Stall pipeline: load instruction detecting
u_idu_bypassMUX bypassMUX (
	
	//RF read data
	.rf_idu_rs1_data			(rf_idu_rs1_data),
	.rf_idu_rs2_data			(rf_idu_rs2_data),

	//ALU bypass data 1,2
	.iex_idu_byp_data			(iex_idu_byp_data),

	//LSU bypass data 1,2
	.lsu_idu_byp_data			(lsu_idu_byp_data),

	//RF bypass data 1,2
	.rf_idu_byp_data			(rf_idu_byp_data),

	//Selection control
	.iex_idu_byp_rd				(iex_idu_byp_rd),
	.iex_idu_rd_vld				(iex_idu_rd_vld),
	.iex_idu_pipe_vld			(iex_idu_pipe_vld),
	.iex_idu_is_load			(iex_idu_is_load),

	.lsu_idu_byp_rd				(lsu_idu_byp_rd),
	.lsu_idu_rd_vld				(lsu_idu_rd_vld),
	.lsu_idu_pipe_vld			(lsu_idu_pipe_vld),
	.lsu_idu_is_load			(lsu_idu_is_load),

	.rf_idu_byp_rd				(rf_idu_byp_rd),
	.rf_idu_rd_vld				(rf_idu_rd_vld),
	.rf_idu_pipe_vld			(rf_idu_pipe_vld),

	.inst_rs1_idx				(idu_rf_rs1_idx),
	.inst_rs2_idx				(idu_rf_rs2_idx),
	.inst_rs1_idx_vld			(instDecode_bypassMUX_inst_rs1_vld),
	.inst_rs2_idx_vld			(instDecode_bypassMUX_inst_rs2_vld),
	
	//data output
	.idu_iex_rs1_data			(idu_iex_rs1_data),
	.idu_iex_rs2_data			(idu_iex_rs2_data),

	//Control output to dispatcher
	//stall
	.idu_dispatcher_stall_vld	(idu_dispatcher_stall_vld)

);


endmodule
