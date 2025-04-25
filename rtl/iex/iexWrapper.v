//IEX Wrapper
//1. one-cycle ALU 0,1
//2. AlphaTensor
//3. BRU 0,1 result selector: select which bru result is chosen
//4. BRU flush clear inst_vld if needed (BRU 0 flush inst 1)
//4. All control signal(rf_wen,dmem_load,dmem_store,wfi_vld,exception_vld) will need to check inst_vld after consideration of BRU flush

module u_iex_super_scalar_wrapper (
	//SoC input
	input							clk,
	input							rst_n,

	//---------------------------------------------------------------------------------------------
	//IDU input
	//AlphaTensor
	`ifdef ALPHATENSOR
		input									idu_alphaTensor_matrix_mul_vld,
		input	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs1_idx,
		input	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rs2_idx,
		input	[`MATRIX_MEM_DEPTH_BIT-1:0]	idu_alphaTensor_matrix_mem_rd_idx,
	`endif

	//CSR
	//wfi vld
	input							idu_iex_csr_wfi_vld					[`SUPER_SCALAR_NUM-1:0],
	//exception vld
	input							idu_iex_csr_exception_vld			[`SUPER_SCALAR_NUM-1:0],
	//exception
	input	[`EXCEPTION_NUM-1:0]	idu_iex_csr_exceptions				[`SUPER_SCALAR_NUM-1:0],
	
	//ALU
	input	[`PC_WIDTH-1:0]			idu_iex_pc							[`SUPER_SCALAR_NUM-1:0],
	input	[`DATA_WIDTH-1:0]		idu_iex_rs1_data					[`SUPER_SCALAR_NUM-1:0],
	input	[`DATA_WIDTH-1:0]		idu_iex_rs2_data					[`SUPER_SCALAR_NUM-1:0],
	input	[`DATA_WIDTH-1:0]		idu_iex_imm_data					[`SUPER_SCALAR_NUM-1:0],
	input	[`RF_DEPTH_BIT-1:0]		idu_iex_rd							[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_rd_vld						[`SUPER_SCALAR_NUM-1:0], 
	input							idu_iex_pipe_vld					[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_is_load						[`SUPER_SCALAR_NUM-1:0], 

	//Control
	//Data selection control flag in ALU
	input							idu_iex_flag_adder_sel_src1_pc		[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_adder_sel_src2_rs2		[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_general_sel_src2_rs2	[`SUPER_SCALAR_NUM-1:0],
	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	input							idu_iex_flag_unsigned_data			[`SUPER_SCALAR_NUM-1:0],
	//Adder
	input							idu_iex_flag_adder_vld				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_adder_sub				[`SUPER_SCALAR_NUM-1:0],
	//Comparator
	input							idu_iex_flag_comparator_vld			[`SUPER_SCALAR_NUM-1:0],
	//logical plane
	input							idu_iex_flag_logical_plane_and		[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_logical_plane_or		[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_logical_plane_xor		[`SUPER_SCALAR_NUM-1:0],
	//Shifter
	input							idu_iex_flag_shifter_right_shift	[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_shifter_logical_shift	[`SUPER_SCALAR_NUM-1:0],
	//BRU
	input							idu_iex_flag_bru_jal				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_bru_jalr				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_bru_bge				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_bru_blt				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_bru_beq				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_bru_bne				[`SUPER_SCALAR_NUM-1:0],
	//Memory access flag
	input							idu_iex_flag_dmem_lb				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_dmem_lh				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_dmem_lw				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_dmem_sw				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_dmem_sb				[`SUPER_SCALAR_NUM-1:0],
	input							idu_iex_flag_dmem_sh				[`SUPER_SCALAR_NUM-1:0],
	//Control flag for RF
	input							idu_iex_rf_wen						[`SUPER_SCALAR_NUM-1:0],
	//-------------------------------------------------------------------------------------------

	//-------------------------------------------------------------------------------------------
	//CSR output
	//wfi
	output							iex_csr_wfi_vld,
	//exception
	output							iex_csr_exception_vld,
	output	[`EXCEPTION_NUM-1:0]	iex_csr_exceptions,
	output	[`PC_WIDTH-1:0]			iex_csr_exception_pc,

	//IFU output
	output							iex_ifu_report_exceptions_wfi,
	
	//IDU bypass output
	output							iex_idu_pipe_vld					[`SUPER_SCALAR_NUM-1:0],
	output 							iex_idu_is_load						[`SUPER_SCALAR_NUM-1:0],
	output 							iex_idu_rd_vld						[`SUPER_SCALAR_NUM-1:0],
	output [`RF_DEPTH_BIT-1:0]		iex_idu_rd						[`SUPER_SCALAR_NUM-1:0],
	output [`DATA_WIDTH-1:0] 		iex_idu_byp_data					[`SUPER_SCALAR_NUM-1:0],
	
	//BRU output
	output							iex_bru_vld,
	output							iex_bru_flush,
	output	[`PC_WIDTH-1:0]			iex_bru_redir_pc,

	//LSU output
	output 							iex_lsu_pipe_vld 					[`SUPER_SCALAR_NUM-1:0],
	output	[`PC_WIDTH-1:0]			iex_lsu_pc							[`SUPER_SCALAR_NUM-1:0],
	output	[`RF_DEPTH_BIT-1:0]		iex_lsu_rd							[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_rd_vld						[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_is_load						[`SUPER_SCALAR_NUM-1:0],	
	output	[`DATA_WIDTH-1:0]		iex_lsu_cal_data					[`SUPER_SCALAR_NUM-1:0],
	output	[`DATA_WIDTH-1:0]		iex_lsu_dmem_wr_data				[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output	[`DATA_WIDTH-1:0]		iex_lsu_dmem_addr					[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output							iex_lsu_dmem_ren					[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output							iex_lsu_flag_unsigned_data			[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_flag_dmem_lb				[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_flag_dmem_lh				[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_flag_dmem_lw				[`SUPER_SCALAR_NUM-1:0],
	output							iex_lsu_flag_dmem_sw				[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output							iex_lsu_flag_dmem_sb				[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output							iex_lsu_flag_dmem_sh				[`SUPER_SCALAR_NUM-1:0],	//Not flopped
	output							iex_lsu_rf_wen						[`SUPER_SCALAR_NUM-1:0]

);

//-----------------Internal signal--------------//
//ALU 0,1 output
wire 							alu_iex_bru_vld 						[`SUPER_SCALAR_NUM-1:0];
wire 							alu_iex_bru_flush 						[`SUPER_SCALAR_NUM-1:0];
wire	[`PC_WIDTH-1:0]			alu_iex_bru_redir_pc					[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		alu_iex_cal_data						[`SUPER_SCALAR_NUM-1:0];

//LSU output
wire 							iex_lsu_pipe_vld_q	 					[`SUPER_SCALAR_NUM-1:0];
reg 							iex_lsu_pipe_vld_reg 					[`SUPER_SCALAR_NUM-1:0];
reg		[`PC_WIDTH-1:0]			iex_lsu_pc_reg							[`SUPER_SCALAR_NUM-1:0];
reg		[`RF_DEPTH_BIT-1:0]		iex_lsu_rd_reg							[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_rd_vld_reg						[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_is_load_reg						[`SUPER_SCALAR_NUM-1:0];
reg		[`DATA_WIDTH-1:0]		iex_lsu_cal_data_reg					[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_flag_unsigned_data_reg			[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_flag_dmem_lb_reg				[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_flag_dmem_lh_reg				[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_flag_dmem_lw_reg				[`SUPER_SCALAR_NUM-1:0];
reg								iex_lsu_rf_wen_reg						[`SUPER_SCALAR_NUM-1:0];


//-----------------------end--------------------//

//--------------AlphaTensor--------------//
`ifdef ALPHATENSOR
u_alphaTensor alphaTensor(
	.clk									(clk),
	.rst_n									(rst_n),
	.idu_alphaTensor_rd						(idu_alphaTensor_matrix_mem_rd_idx),
	.idu_alphaTensor_rs1					(idu_alphaTensor_matrix_mem_rs1_idx),
	.idu_alphaTensor_rs2					(idu_alphaTensor_matrix_mem_rs2_idx),
	.idu_alphaTensor_mul_vld				(idu_alphaTensor_matrix_mul_vld),
	.iex_alphaTensor_bru_vld_0				(alu_iex_bru_vld[0]),
	.iex_alphaTensor_bru_flush_0			(alu_iex_bru_flush[0])
);
`endif
//-----------------------end--------------------//

//----------------------ALU 0-------------------//
u_alu alu_0(
	.iex_alu_pc									(idu_iex_pc[0]),
	.iex_alu_rs1_data							(idu_iex_rs1_data[0]),
	.iex_alu_rs2_data							(idu_iex_rs2_data[0]),
	.iex_alu_imm_data							(idu_iex_imm_data[0]),
	.iex_alu_pipe_vld							(idu_iex_pipe_vld[0]),
	.iex_alu_flag_adder_sel_src1_pc				(idu_iex_flag_adder_sel_src1_pc[0]),
	.iex_alu_flag_adder_sel_src2_rs2			(idu_iex_flag_adder_sel_src2_rs2[0]),
	.iex_alu_flag_general_sel_src2_rs2			(idu_iex_flag_general_sel_src2_rs2[0]),
	.iex_alu_flag_unsigned_data					(idu_iex_flag_unsigned_data[0]),
	.iex_alu_flag_adder_vld						(idu_iex_flag_adder_vld[0]),
	.iex_alu_flag_adder_sub						(idu_iex_flag_adder_sub[0]),
	.iex_alu_flag_comparator_vld				(idu_iex_flag_comparator_vld[0]),
	.iex_alu_flag_logical_plane_and				(idu_iex_flag_logical_plane_and[0]),
	.iex_alu_flag_logical_plane_or				(idu_iex_flag_logical_plane_or[0]),
	.iex_alu_flag_logical_plane_xor				(idu_iex_flag_logical_plane_xor[0]),
	.iex_alu_flag_shifter_right_shift			(idu_iex_flag_shifter_right_shift[0]),
	.iex_alu_flag_shifter_logical_shift			(idu_iex_flag_shifter_logical_shift[0]),
	.iex_alu_flag_bru_jal						(idu_iex_flag_bru_jal[0]),
	.iex_alu_flag_bru_jalr						(idu_iex_flag_bru_jalr[0]),
	.iex_alu_flag_bru_bge						(idu_iex_flag_bru_bge[0]),
	.iex_alu_flag_bru_blt						(idu_iex_flag_bru_blt[0]),
	.iex_alu_flag_bru_beq						(idu_iex_flag_bru_beq[0]),
	.iex_alu_flag_bru_bne						(idu_iex_flag_bru_bne[0]),
	.alu_iex_bru_vld							(alu_iex_bru_vld[0]),
	.alu_iex_bru_flush							(alu_iex_bru_flush[0]),
	.alu_iex_bru_redir_pc						(alu_iex_bru_redir_pc[0]),
	.alu_iex_cal_data							(alu_iex_cal_data[0])
);

//-----------------------end--------------------//

//----------------------ALU 1-------------------//
u_alu alu_1(
	.iex_alu_pc									(idu_iex_pc[1]),
	.iex_alu_rs1_data							(idu_iex_rs1_data[1]),
	.iex_alu_rs2_data							(idu_iex_rs2_data[1]),
	.iex_alu_imm_data							(idu_iex_imm_data[1]),
	.iex_alu_pipe_vld							(idu_iex_pipe_vld[1]),
	.iex_alu_flag_adder_sel_src1_pc				(idu_iex_flag_adder_sel_src1_pc[1]),
	.iex_alu_flag_adder_sel_src2_rs2			(idu_iex_flag_adder_sel_src2_rs2[1]),
	.iex_alu_flag_general_sel_src2_rs2			(idu_iex_flag_general_sel_src2_rs2[1]),
	.iex_alu_flag_unsigned_data					(idu_iex_flag_unsigned_data[1]),
	.iex_alu_flag_adder_vld						(idu_iex_flag_adder_vld[1]),
	.iex_alu_flag_adder_sub						(idu_iex_flag_adder_sub[1]),
	.iex_alu_flag_comparator_vld				(idu_iex_flag_comparator_vld[1]),
	.iex_alu_flag_logical_plane_and				(idu_iex_flag_logical_plane_and[1]),
	.iex_alu_flag_logical_plane_or				(idu_iex_flag_logical_plane_or[1]),
	.iex_alu_flag_logical_plane_xor				(idu_iex_flag_logical_plane_xor[1]),
	.iex_alu_flag_shifter_right_shift			(idu_iex_flag_shifter_right_shift[1]),
	.iex_alu_flag_shifter_logical_shift			(idu_iex_flag_shifter_logical_shift[1]),
	.iex_alu_flag_bru_jal						(idu_iex_flag_bru_jal[1]),
	.iex_alu_flag_bru_jalr						(idu_iex_flag_bru_jalr[1]),
	.iex_alu_flag_bru_bge						(idu_iex_flag_bru_bge[1]),
	.iex_alu_flag_bru_blt						(idu_iex_flag_bru_blt[1]),
	.iex_alu_flag_bru_beq						(idu_iex_flag_bru_beq[1]),
	.iex_alu_flag_bru_bne						(idu_iex_flag_bru_bne[1]),
	.alu_iex_bru_vld							(alu_iex_bru_vld[1]),
	.alu_iex_bru_flush							(alu_iex_bru_flush[1]),
	.alu_iex_bru_redir_pc						(alu_iex_bru_redir_pc[1]),
	.alu_iex_cal_data							(alu_iex_cal_data[1])
);
//-----------------------end--------------------//

//---------------Inter-stage Register-----------//
assign	iex_lsu_pipe_vld_q[0]	=	idu_iex_pipe_vld[0];
assign	iex_lsu_pipe_vld_q[1]	=	idu_iex_pipe_vld[1] & ~(alu_iex_bru_flush[0] | idu_iex_csr_wfi_vld[0] | idu_iex_csr_exception_vld[0]);	//By design of dispatcher, inst 1 vld must indicate inst 0 vld

//instruction valid passing register
//always enable
for(genvar i=0; i<`SUPER_SCALAR_NUM;i++) begin
always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		iex_lsu_pipe_vld_reg[i]	<=	'b0;
	end
	else begin
		iex_lsu_pipe_vld_reg[i]	<=	iex_lsu_pipe_vld_q[i] & ~(idu_iex_csr_wfi_vld[i] | idu_iex_csr_exception_vld[i]); //if wfi/exception, LSU and RF pipe invalid as no action should be done; For bru flush, jal/jalr will wr RF
	end
end
end
//ALU to LSU output
for(genvar i=0; i<`SUPER_SCALAR_NUM; i++) begin
always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		iex_lsu_pc_reg[i]					<=	'b0;
		iex_lsu_rd_reg[i]					<=	'b0;
		iex_lsu_rd_vld_reg[i]				<=	'b0;
		iex_lsu_is_load_reg[i]		<=	'b0;
		//iex_lsu_cal_data_reg[i]			<=	'b0;	DATA BUS don't need reset
		iex_lsu_flag_unsigned_data_reg[i]	<=	'b0;
		iex_lsu_flag_dmem_lb_reg[i]			<=	'b0;
		iex_lsu_flag_dmem_lh_reg[i]			<=	'b0;
		iex_lsu_flag_dmem_lw_reg[i]			<=	'b0;
		iex_lsu_rf_wen_reg[i]				<=	'b0;
	end
	else if(iex_lsu_pipe_vld_q[i]) begin
		iex_lsu_pc_reg[i]					<=	idu_iex_pc[i];
		iex_lsu_rd_reg[i]					<=	idu_iex_rd[i];
		iex_lsu_rd_vld_reg[i]				<=	idu_iex_rd_vld[i];
		iex_lsu_is_load_reg[i]				<=	idu_iex_is_load[i];
		iex_lsu_cal_data_reg[i]				<=	alu_iex_cal_data[i];
		iex_lsu_flag_unsigned_data_reg[i]	<=	idu_iex_flag_unsigned_data[i];
		iex_lsu_flag_dmem_lb_reg[i]			<=	idu_iex_flag_dmem_lb[i];
		iex_lsu_flag_dmem_lh_reg[i]			<=	idu_iex_flag_dmem_lh[i];
		iex_lsu_flag_dmem_lw_reg[i]			<=	idu_iex_flag_dmem_lw[i];
		iex_lsu_rf_wen_reg[i]				<=	idu_iex_rf_wen[i];	
	end
end
end
//----------------------end-----------------------//

//Interface assignment
//-------------------CSR output----------------//
assign	iex_csr_wfi_vld			=	(iex_lsu_pipe_vld_q[0] & idu_iex_csr_wfi_vld[0]) | (iex_lsu_pipe_vld_q[1] & idu_iex_csr_wfi_vld[1]);
assign	iex_csr_exception_vld	=	(iex_lsu_pipe_vld_q[0] & idu_iex_csr_exception_vld[0]) | (iex_lsu_pipe_vld_q[1] & idu_iex_csr_exception_vld[1]);
assign	iex_csr_exception_pc	=	(idu_iex_csr_exception_vld[0])? idu_iex_pc[0] : idu_iex_pc[1];
assign	iex_csr_exceptions		=	(idu_iex_csr_exception_vld[0])? idu_iex_csr_exceptions[0] : idu_iex_csr_exceptions[1];
//-----------------------end--------------------//

//-------------------IFU output-----------------//
assign iex_ifu_report_exceptions_wfi	=	(idu_iex_csr_wfi_vld[1] | idu_iex_csr_exception_vld[1] | idu_iex_csr_wfi_vld[0] | idu_iex_csr_exception_vld[0]);	//Timing: BRU flush is not considered as it is also pass to IFU to flush pipe
//-----------------------end---------------------//

//-----------------IDU Bypass path--------------//
assign	iex_idu_byp_data 	=	alu_iex_cal_data;
assign	iex_idu_rd			=	idu_iex_rd;
assign	iex_idu_rd_vld		=	idu_iex_rd_vld;
assign	iex_idu_is_load		=	idu_iex_is_load;
assign	iex_idu_pipe_vld	=	idu_iex_pipe_vld;	//Timing: bypass path pipe valid don't need to consider BRU flush as BRU flush also pass to IDU to flush pipe
//-----------------------end-------------------//

//-------------------BRU output------------------//
//To IFU and IDU
//BRU vld is used to mask operation
assign iex_bru_vld	=	alu_iex_bru_vld[0] | alu_iex_bru_vld[1];
assign iex_bru_flush	=	(alu_iex_bru_vld[0] & alu_iex_bru_flush[0]) | (alu_iex_bru_vld[1] & alu_iex_bru_flush[1]);
assign iex_bru_redir_pc	= 	(alu_iex_bru_vld[0] & alu_iex_bru_flush[0])? alu_iex_bru_redir_pc[0] : alu_iex_bru_redir_pc[1];
//-----------------------end---------------------//

//-------------------LSU output------------------//
//Not flopped
//if LOAD inst, ren = 1, addr=cal_data
//For M stage, use cal_data to select read data
//Data extraction is done in LSU
for(genvar i=0; i<`SUPER_SCALAR_NUM;i++) begin
	assign	iex_lsu_dmem_ren[i]			=	idu_iex_is_load[i] & iex_lsu_pipe_vld_q[i];
end
//if STORE inst, wen = 1, addr=cal_data, wr_data=rs2_data_extracted
assign	iex_lsu_dmem_addr					=	alu_iex_cal_data; 		//adder result
assign	iex_lsu_dmem_wr_data				=	idu_iex_rs2_data;
for(genvar i=0; i<`SUPER_SCALAR_NUM; i++) begin
	assign	iex_lsu_flag_dmem_sw[i]			=	idu_iex_flag_dmem_sw[i] & iex_lsu_pipe_vld_q[i];
	assign	iex_lsu_flag_dmem_sb[i]			=	idu_iex_flag_dmem_sb[i] & iex_lsu_pipe_vld_q[i];
	assign	iex_lsu_flag_dmem_sh[i]			=	idu_iex_flag_dmem_sh[i] & iex_lsu_pipe_vld_q[i];
end
//Flopped
assign	iex_lsu_pipe_vld					=	iex_lsu_pipe_vld_reg;
assign	iex_lsu_pc							=	iex_lsu_pc_reg;
assign	iex_lsu_rd							=	iex_lsu_rd_reg;
assign	iex_lsu_rd_vld						=	iex_lsu_rd_vld_reg;
assign	iex_lsu_is_load						=	iex_lsu_is_load_reg;
assign	iex_lsu_cal_data					=	iex_lsu_cal_data_reg;
assign	iex_lsu_flag_unsigned_data			=	iex_lsu_flag_unsigned_data_reg;
assign	iex_lsu_flag_dmem_lb				=	iex_lsu_flag_dmem_lb_reg;
assign	iex_lsu_flag_dmem_lh				=	iex_lsu_flag_dmem_lh_reg;
assign	iex_lsu_flag_dmem_lw				=	iex_lsu_flag_dmem_lw_reg;
assign	iex_lsu_rf_wen						=	iex_lsu_rf_wen_reg;
//-----------------------end---------------------//

endmodule
