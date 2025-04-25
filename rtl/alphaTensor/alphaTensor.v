module u_alphaTensor (
	//SOC input
	input clk,
	input rst_n,

	//IDU input
	// rd,rs1,rs2 is extended to 8-bit for 256 depth reg-like matrix memory in this project
	input [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_rd,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_rs1,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_rs2,
	input idu_alphaTensor_mul_vld,

	//ALU input
	input iex_alphaTensor_bru_vld_0,
	input iex_alphaTensor_bru_flush_0
	
);

//wire
wire [`MATRIX_MEM_READ_MSB_INDEX:0] dmem_preadder_data_0;
wire [`MATRIX_MEM_READ_MSB_INDEX:0] dmem_preadder_data_1;
wire [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_mul_data_lhs [`MULITIPLICATION_NUM:1];
wire [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_mul_data_rhs [`MULITIPLICATION_NUM:1];
wire [`MATRIX_MEM_DATA_LENGTH-1:0] mul_postadder_data [`MULITIPLICATION_NUM:1];
wire [`MATRIX_MEM_READ_MSB_INDEX:0] postadder_dmem_wr_data;
wire preadder_mul_vld;
wire mul_postadder_vld;
wire postadder_dmem_vld;
wire [`MATRIX_MEM_DEPTH_BIT-1:0] preadder_mul_rd;
wire [`MATRIX_MEM_DEPTH_BIT-1:0] mul_postadder_rd;
wire [`MATRIX_MEM_DEPTH_BIT-1:0] postadder_dmem_rd;
wire iex_alphaTensor_bru_flush;
assign iex_alphaTensor_bru_flush = iex_alphaTensor_bru_flush_0 & iex_alphaTensor_bru_vld_0;

//dmem
u_MatrixMem dmem(
	.clk					(clk),
	.wen					(postadder_dmem_vld),
	.rd_idx					(postadder_dmem_rd),
	.matrix_wr_data				(postadder_dmem_wr_data),
	.rs1_idx				(idu_alphaTensor_rs1),
	.rs2_idx				(idu_alphaTensor_rs2),
	.matrix_rd_data_1			(dmem_preadder_data_0),
	.matrix_rd_data_2			(dmem_preadder_data_1)
);

//preadder 
u_preadder preadder(
	.clk					(clk),
	.rst_n					(rst_n),
	.bru_flush				(iex_alphaTensor_bru_flush),
	.preadder_vld_in		(idu_alphaTensor_mul_vld),
	.rd_in					(idu_alphaTensor_rd),
	.matrix_data_in_1		(dmem_preadder_data_0),
	.matrix_data_in_2 		(dmem_preadder_data_1),
	.preadder_vld_out		(preadder_mul_vld),
	.rd_out					(preadder_mul_rd),
	.preadder_data_out_lhs	(preadder_mul_data_lhs),
	.preadder_data_out_rhs	(preadder_mul_data_rhs)
);

//multiplier
u_multiplier multiplier(
	.clk					(clk),
	.rst_n					(rst_n),
	.mul_vld_in				(preadder_mul_vld),
	.rd_in					(preadder_mul_rd),
	.mul_data_in_lhs		(preadder_mul_data_lhs),
	.mul_data_in_rhs 		(preadder_mul_data_rhs),
	.mul_vld_out			(mul_postadder_vld),		
	.rd_out					(mul_postadder_rd),
	.mul_data_out			(mul_postadder_data)
);

//postadder
u_postadder postadder(
	.clk					(clk),
	.rst_n					(rst_n),
	.postadder_vld_in		(mul_postadder_vld),
	.rd_in					(mul_postadder_rd),
	.postadder_data_in		(mul_postadder_data),
	.postadder_vld_out		(postadder_dmem_vld),
	.rd_out					(postadder_dmem_rd),
	.matrix_out				(postadder_dmem_wr_data)
);

endmodule
