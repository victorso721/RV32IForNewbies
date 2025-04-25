//special arrangment on starting index for 2D array: start from 1 for eaiser counting
module u_preadder(
	//SOC input
	input clk,
	input rst_n,

	//ALU input
	input bru_flush,

	//Top module input
	input preadder_vld_in,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rd_in,
	input [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_data_in_1,
	input [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_data_in_2,

	//Multiplier output
	output preadder_vld_out,
	output [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out,
	output [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_data_out_lhs [`MULITIPLICATION_NUM:1],
	output [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_data_out_rhs [`MULITIPLICATION_NUM:1]
);

//internal signal
wire [`MATRIX_MEM_DATA_LENGTH-1:0] matrix_1 [`ROW_NUM:1][`COL_NUM:1];
wire [`MATRIX_MEM_DATA_LENGTH-1:0] matrix_2 [`ROW_NUM:1][`COL_NUM:1];
reg [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_mul_data_lhs_reg [`MULITIPLICATION_NUM:1];
reg [`MATRIX_MEM_DATA_LENGTH-1:0] preadder_mul_data_rhs_reg [`MULITIPLICATION_NUM:1];
reg preadder_vld_out_reg;
reg [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out_reg;

//Matrix element slicing
for(genvar i=0; i<(`ROW_NUM*`COL_NUM); i++) begin
	assign matrix_1[(i/`COL_NUM)+1][(i%`COL_NUM)+1] = matrix_data_in_1[i*`MATRIX_MEM_DATA_LENGTH+(`MATRIX_MEM_DATA_LENGTH-1):i*`MATRIX_MEM_DATA_LENGTH];
	assign matrix_2[(i/`COL_NUM)+1][(i%`COL_NUM)+1] = matrix_data_in_2[i*`MATRIX_MEM_DATA_LENGTH+(`MATRIX_MEM_DATA_LENGTH-1):i*`MATRIX_MEM_DATA_LENGTH];

end
//Modulo 2 addition performed by bitwise XOR 
//preadding LHS
always @(posedge clk) begin
	if(preadder_vld_in & !bru_flush) begin
		preadder_mul_data_lhs_reg[1]  <= matrix_1[1][1];
		preadder_mul_data_lhs_reg[2]  <= matrix_1[1][1] ^ matrix_1[3][1] ^ matrix_1[3][3];
		preadder_mul_data_lhs_reg[3]  <= matrix_1[1][1] ^ matrix_1[3][1] ^ matrix_1[3][4];
		preadder_mul_data_lhs_reg[4]  <= matrix_1[1][3] ^ matrix_1[2][1] ^ matrix_1[2][3];
		preadder_mul_data_lhs_reg[5]  <= matrix_1[1][1] ^ matrix_1[3][1];
		preadder_mul_data_lhs_reg[6]  <= matrix_1[1][3] ^ matrix_1[2][3];
		preadder_mul_data_lhs_reg[7]  <= matrix_1[1][4] ^ matrix_1[4][3] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[8]  <= matrix_1[1][4] ^ matrix_1[4][1] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[9]  <= matrix_1[1][3] ^ matrix_1[2][3] ^ matrix_1[2][4];
		preadder_mul_data_lhs_reg[10] <= matrix_1[1][4] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[11] <= matrix_1[3][3];
		preadder_mul_data_lhs_reg[12] <= matrix_1[1][2] ^ matrix_1[3][2] ^ matrix_1[3][3];
		preadder_mul_data_lhs_reg[13] <= matrix_1[3][4];
		preadder_mul_data_lhs_reg[14] <= matrix_1[1][2] ^ matrix_1[3][2];
		preadder_mul_data_lhs_reg[15] <= matrix_1[1][2] ^ matrix_1[3][2] ^ matrix_1[3][4];
		preadder_mul_data_lhs_reg[16] <= matrix_1[2][1];
		preadder_mul_data_lhs_reg[17] <= matrix_1[1][2] ^ matrix_1[2][1] ^ matrix_1[2][2];
		preadder_mul_data_lhs_reg[18] <= matrix_1[1][2] ^ matrix_1[2][2];
		preadder_mul_data_lhs_reg[19] <= matrix_1[2][4];
		preadder_mul_data_lhs_reg[20] <= matrix_1[1][2] ^ matrix_1[2][3] ^ matrix_1[2][4] ^ matrix_1[3][2] ^ matrix_1[3][3];
		preadder_mul_data_lhs_reg[21] <= matrix_1[1][2] ^ matrix_1[2][2] ^ matrix_1[2][4];
		preadder_mul_data_lhs_reg[22] <= matrix_1[4][3];
		preadder_mul_data_lhs_reg[23] <= matrix_1[1][1] ^ matrix_1[1][3] ^ matrix_1[1][4] ^ matrix_1[2][3] ^ matrix_1[2][4] ^ matrix_1[3][1] ^ matrix_1[3][4];
		preadder_mul_data_lhs_reg[24] <= matrix_1[1][2] ^ matrix_1[4][2] ^ matrix_1[4][3];
		preadder_mul_data_lhs_reg[25] <= matrix_1[1][2] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[26] <= matrix_1[1][2] ^ matrix_1[4][1] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[27] <= matrix_1[1][4];
		preadder_mul_data_lhs_reg[28] <= matrix_1[1][2] ^ matrix_1[2][1] ^ matrix_1[2][2] ^ matrix_1[3][1] ^ matrix_1[3][4];
		preadder_mul_data_lhs_reg[29] <= matrix_1[1][2] ^ matrix_1[2][1] ^ matrix_1[2][3] ^ matrix_1[4][2] ^ matrix_1[4][3];
		preadder_mul_data_lhs_reg[30] <= matrix_1[1][2] ^ matrix_1[3][1] ^ matrix_1[3][3] ^ matrix_1[4][1] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[31] <= matrix_1[4][1];
		preadder_mul_data_lhs_reg[32] <= matrix_1[1][2] ^ matrix_1[3][2] ^ matrix_1[3][4] ^ matrix_1[4][3] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[33] <= matrix_1[1][2] ^ matrix_1[2][2] ^ matrix_1[2][4] ^ matrix_1[4][1] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[34] <= matrix_1[2][1] ^ matrix_1[3][1] ^ matrix_1[4][1];
		preadder_mul_data_lhs_reg[35] <= matrix_1[1][2] ^ matrix_1[2][1] ^ matrix_1[2][2] ^ matrix_1[3][2] ^ matrix_1[3][3];;
		preadder_mul_data_lhs_reg[36] <= matrix_1[1][2] ^ matrix_1[2][4] ^ matrix_1[3][2] ^ matrix_1[4][3];
		preadder_mul_data_lhs_reg[37] <= matrix_1[1][2] ^ matrix_1[2][1] ^ matrix_1[3][3] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[38] <= matrix_1[2][2] ^ matrix_1[3][2] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[39] <= matrix_1[1][2];
		preadder_mul_data_lhs_reg[40] <= matrix_1[1][3];
		preadder_mul_data_lhs_reg[41] <= matrix_1[1][1] ^ matrix_1[1][3] ^ matrix_1[1][4] ^ matrix_1[2][1] ^ matrix_1[2][3] ^ matrix_1[4][1] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[42] <= matrix_1[1][2] ^ matrix_1[3][2] ^ matrix_1[3][4] ^ matrix_1[4][1] ^ matrix_1[4][2];
		preadder_mul_data_lhs_reg[43] <= matrix_1[2][4] ^ matrix_1[3][4] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[44] <= matrix_1[2][3] ^ matrix_1[3][3] ^ matrix_1[4][3];
		preadder_mul_data_lhs_reg[45] <= matrix_1[1][1] ^ matrix_1[1][3] ^ matrix_1[1][4] ^ matrix_1[3][1] ^ matrix_1[3][3] ^ matrix_1[4][3] ^ matrix_1[4][4];
		preadder_mul_data_lhs_reg[46] <= matrix_1[1][2] ^ matrix_1[2][2] ^ matrix_1[3][4] ^ matrix_1[4][1];
		preadder_mul_data_lhs_reg[47] <= matrix_1[1][2] ^ matrix_1[2][2] ^ matrix_1[2][4] ^ matrix_1[4][2] ^ matrix_1[4][3];

		//preadding RHS
		preadder_mul_data_rhs_reg[1]  <= matrix_2[1][3];
		preadder_mul_data_rhs_reg[2]  <= matrix_2[1][1] ^ matrix_2[3][1] ^ matrix_2[3][3];
		preadder_mul_data_rhs_reg[3]  <= matrix_2[1][2] ^ matrix_2[4][2] ^ matrix_2[4][3];
		preadder_mul_data_rhs_reg[4]  <= matrix_2[1][3] ^ matrix_2[1][4] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[5]  <= matrix_2[1][1] ^ matrix_2[1][2] ^ matrix_2[1][3] ^ matrix_2[3][1] ^ matrix_2[3][3] ^ matrix_2[4][2] ^ matrix_2[4][3];
		preadder_mul_data_rhs_reg[6]  <= matrix_2[1][3] ^ matrix_2[1][4] ^ matrix_2[3][2] ^ matrix_2[3][3] ^ matrix_2[3][4] ^ matrix_2[4][2] ^ matrix_2[4][3];;
		preadder_mul_data_rhs_reg[7]  <= matrix_2[3][1] ^ matrix_2[3][3] ^ matrix_2[4][1];
		preadder_mul_data_rhs_reg[8]  <= matrix_2[1][3] ^ matrix_2[1][4] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[9]  <= matrix_2[3][2] ^ matrix_2[4][2] ^ matrix_2[4][3];
		preadder_mul_data_rhs_reg[10] <= matrix_2[1][3] ^ matrix_2[1][4] ^ matrix_2[3][1] ^ matrix_2[3][3] ^ matrix_2[4][1] ^ matrix_2[4][3] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[11] <= matrix_2[1][1] ^ matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[3][1] ^ matrix_2[3][2];
		preadder_mul_data_rhs_reg[12] <= matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[3][2];
		preadder_mul_data_rhs_reg[13] <= matrix_2[1][2] ^ matrix_2[2][1] ^ matrix_2[2][3] ^ matrix_2[4][1] ^ matrix_2[4][2];
		preadder_mul_data_rhs_reg[14] <= matrix_2[2][1] ^ matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[3][2] ^ matrix_2[4][1];
		preadder_mul_data_rhs_reg[15] <= matrix_2[2][1] ^ matrix_2[2][3] ^ matrix_2[4][1];
		preadder_mul_data_rhs_reg[16] <= matrix_2[1][2] ^ matrix_2[1][4] ^ matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[17] <= matrix_2[1][2] ^ matrix_2[2][2] ^ matrix_2[2][3];
		preadder_mul_data_rhs_reg[18] <= matrix_2[1][2] ^ matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[19] <= matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[3][2] ^ matrix_2[4][2] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[20] <= matrix_2[3][2];
		preadder_mul_data_rhs_reg[21] <= matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[22] <= matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[3][1] ^ matrix_2[3][4] ^ matrix_2[4][1];
		preadder_mul_data_rhs_reg[23] <= matrix_2[4][2] ^ matrix_2[4][3];
		preadder_mul_data_rhs_reg[24] <= matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[25] <= matrix_2[1][1] ^ matrix_2[2][1] ^ matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[26] <= matrix_2[1][1] ^ matrix_2[2][1] ^ matrix_2[2][3];
		preadder_mul_data_rhs_reg[27] <= matrix_2[4][3];
		preadder_mul_data_rhs_reg[28] <= matrix_2[1][2];
		preadder_mul_data_rhs_reg[29] <= matrix_2[3][4];
		preadder_mul_data_rhs_reg[30] <= matrix_2[1][1];
		preadder_mul_data_rhs_reg[31] <= matrix_2[1][1] ^ matrix_2[1][4] ^ matrix_2[2][1] ^ matrix_2[2][3] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[32] <= matrix_2[4][1];
		preadder_mul_data_rhs_reg[33] <= matrix_2[4][4];
		preadder_mul_data_rhs_reg[34] <= matrix_2[1][1] ^ matrix_2[1][2] ^ matrix_2[1][4];
		preadder_mul_data_rhs_reg[35] <= matrix_2[2][2] ^ matrix_2[2][3];
		preadder_mul_data_rhs_reg[36] <= matrix_2[2][3] ^ matrix_2[2][4] ^ matrix_2[3][2] ^ matrix_2[4][1];
		preadder_mul_data_rhs_reg[37] <= matrix_2[1][1] ^ matrix_2[2][2] ^ matrix_2[2][3] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[38] <= matrix_2[2][1] ^ matrix_2[2][2] ^ matrix_2[2][4];
		preadder_mul_data_rhs_reg[39] <= matrix_2[2][3];
		preadder_mul_data_rhs_reg[40] <= matrix_2[3][3];
		preadder_mul_data_rhs_reg[41] <= matrix_2[1][3] ^ matrix_2[1][4];
		preadder_mul_data_rhs_reg[42] <= matrix_2[2][1] ^ matrix_2[2][3];
		preadder_mul_data_rhs_reg[43] <= matrix_2[4][1] ^ matrix_2[4][2] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[44] <= matrix_2[3][1] ^ matrix_2[3][2] ^ matrix_2[3][4];
		preadder_mul_data_rhs_reg[45] <= matrix_2[3][1] ^ matrix_2[3][3];
		preadder_mul_data_rhs_reg[46] <= matrix_2[1][2] ^ matrix_2[2][1] ^ matrix_2[2][3] ^ matrix_2[4][4];
		preadder_mul_data_rhs_reg[47] <= matrix_2[2][3] ^ matrix_2[2][4];
	end
end

/*
always @(posedge clk) begin
	if(preadder_vld_in & !bru_flush) begin
		preadder_mul_data_lhs_reg[1]  <= matrix_1[1][1];
		preadder_mul_data_lhs_reg[2]  <= matrix_1[1][1] + matrix_1[3][1] + matrix_1[3][3];
		preadder_mul_data_lhs_reg[3]  <= matrix_1[1][1] + matrix_1[3][1] + matrix_1[3][4];
		preadder_mul_data_lhs_reg[4]  <= matrix_1[1][3] + matrix_1[2][1] + matrix_1[2][3];
		preadder_mul_data_lhs_reg[5]  <= matrix_1[1][1] + matrix_1[3][1];
		preadder_mul_data_lhs_reg[6]  <= matrix_1[1][3] + matrix_1[2][3];
		preadder_mul_data_lhs_reg[7]  <= matrix_1[1][4] + matrix_1[4][3] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[8]  <= matrix_1[1][4] + matrix_1[4][1] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[9]  <= matrix_1[1][3] + matrix_1[2][3] + matrix_1[2][4];
		preadder_mul_data_lhs_reg[10] <= matrix_1[1][4] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[11] <= matrix_1[3][3];
		preadder_mul_data_lhs_reg[12] <= matrix_1[1][2] + matrix_1[3][2] + matrix_1[3][3];
		preadder_mul_data_lhs_reg[13] <= matrix_1[3][4];
		preadder_mul_data_lhs_reg[14] <= matrix_1[1][2] + matrix_1[3][2];
		preadder_mul_data_lhs_reg[15] <= matrix_1[1][2] + matrix_1[3][2] + matrix_1[3][4];
		preadder_mul_data_lhs_reg[16] <= matrix_1[2][1];
		preadder_mul_data_lhs_reg[17] <= matrix_1[1][2] + matrix_1[2][1] + matrix_1[2][2];
		preadder_mul_data_lhs_reg[18] <= matrix_1[1][2] + matrix_1[2][2];
		preadder_mul_data_lhs_reg[19] <= matrix_1[2][4];
		preadder_mul_data_lhs_reg[20] <= matrix_1[1][2] + matrix_1[2][3] + matrix_1[2][4] + matrix_1[3][2] + matrix_1[3][3];
		preadder_mul_data_lhs_reg[21] <= matrix_1[1][2] + matrix_1[2][2] + matrix_1[2][4];
		preadder_mul_data_lhs_reg[22] <= matrix_1[4][3];
		preadder_mul_data_lhs_reg[23] <= matrix_1[1][1] + matrix_1[1][3] + matrix_1[1][4] + matrix_1[2][3] + matrix_1[2][4] + matrix_1[3][1] + matrix_1[3][4];
		preadder_mul_data_lhs_reg[24] <= matrix_1[1][2] + matrix_1[4][2] + matrix_1[4][3];
		preadder_mul_data_lhs_reg[25] <= matrix_1[1][2] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[26] <= matrix_1[1][2] + matrix_1[4][1] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[27] <= matrix_1[1][4];
		preadder_mul_data_lhs_reg[28] <= matrix_1[1][2] + matrix_1[2][1] + matrix_1[2][2] + matrix_1[3][1] + matrix_1[3][4];
		preadder_mul_data_lhs_reg[29] <= matrix_1[1][2] + matrix_1[2][1] + matrix_1[2][3] + matrix_1[4][2] + matrix_1[4][3];
		preadder_mul_data_lhs_reg[30] <= matrix_1[1][2] + matrix_1[3][1] + matrix_1[3][3] + matrix_1[4][1] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[31] <= matrix_1[4][1];
		preadder_mul_data_lhs_reg[32] <= matrix_1[1][2] + matrix_1[3][2] + matrix_1[3][4] + matrix_1[4][3] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[33] <= matrix_1[1][2] + matrix_1[2][2] + matrix_1[2][4] + matrix_1[4][1] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[34] <= matrix_1[2][1] + matrix_1[3][1] + matrix_1[4][1];
		preadder_mul_data_lhs_reg[35] <= matrix_1[1][2] + matrix_1[2][1] + matrix_1[2][2] + matrix_1[3][2] + matrix_1[3][3];;
		preadder_mul_data_lhs_reg[36] <= matrix_1[1][2] + matrix_1[2][4] + matrix_1[3][2] + matrix_1[4][3];
		preadder_mul_data_lhs_reg[37] <= matrix_1[1][2] + matrix_1[2][1] + matrix_1[3][3] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[38] <= matrix_1[2][2] + matrix_1[3][2] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[39] <= matrix_1[1][2];
		preadder_mul_data_lhs_reg[40] <= matrix_1[1][3];
		preadder_mul_data_lhs_reg[41] <= matrix_1[1][1] + matrix_1[1][3] + matrix_1[1][4] + matrix_1[2][1] + matrix_1[2][3] + matrix_1[4][1] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[42] <= matrix_1[1][2] + matrix_1[3][2] + matrix_1[3][4] + matrix_1[4][1] + matrix_1[4][2];
		preadder_mul_data_lhs_reg[43] <= matrix_1[2][4] + matrix_1[3][4] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[44] <= matrix_1[2][3] + matrix_1[3][3] + matrix_1[4][3];
		preadder_mul_data_lhs_reg[45] <= matrix_1[1][1] + matrix_1[1][3] + matrix_1[1][4] + matrix_1[3][1] + matrix_1[3][3] + matrix_1[4][3] + matrix_1[4][4];
		preadder_mul_data_lhs_reg[46] <= matrix_1[1][2] + matrix_1[2][2] + matrix_1[3][4] + matrix_1[4][1];
		preadder_mul_data_lhs_reg[47] <= matrix_1[1][2] + matrix_1[2][2] + matrix_1[2][4] + matrix_1[4][2] + matrix_1[4][3];

		//preadding RHS
		preadder_mul_data_rhs_reg[1]  <= matrix_2[1][3];
		preadder_mul_data_rhs_reg[2]  <= matrix_2[1][1] + matrix_2[3][1] + matrix_2[3][3];
		preadder_mul_data_rhs_reg[3]  <= matrix_2[1][2] + matrix_2[4][2] + matrix_2[4][3];
		preadder_mul_data_rhs_reg[4]  <= matrix_2[1][3] + matrix_2[1][4] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[5]  <= matrix_2[1][1] + matrix_2[1][2] + matrix_2[1][3] + matrix_2[3][1] + matrix_2[3][3] + matrix_2[4][2] + matrix_2[4][3];
		preadder_mul_data_rhs_reg[6]  <= matrix_2[1][3] + matrix_2[1][4] + matrix_2[3][2] + matrix_2[3][3] + matrix_2[3][4] + matrix_2[4][2] + matrix_2[4][3];;
		preadder_mul_data_rhs_reg[7]  <= matrix_2[3][1] + matrix_2[3][3] + matrix_2[4][1];
		preadder_mul_data_rhs_reg[8]  <= matrix_2[1][3] + matrix_2[1][4] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[9]  <= matrix_2[3][2] + matrix_2[4][2] + matrix_2[4][3];
		preadder_mul_data_rhs_reg[10] <= matrix_2[1][3] + matrix_2[1][4] + matrix_2[3][1] + matrix_2[3][3] + matrix_2[4][1] + matrix_2[4][3] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[11] <= matrix_2[1][1] + matrix_2[2][2] + matrix_2[2][3] + matrix_2[3][1] + matrix_2[3][2];
		preadder_mul_data_rhs_reg[12] <= matrix_2[2][2] + matrix_2[2][3] + matrix_2[3][2];
		preadder_mul_data_rhs_reg[13] <= matrix_2[1][2] + matrix_2[2][1] + matrix_2[2][3] + matrix_2[4][1] + matrix_2[4][2];
		preadder_mul_data_rhs_reg[14] <= matrix_2[2][1] + matrix_2[2][2] + matrix_2[2][3] + matrix_2[3][2] + matrix_2[4][1];
		preadder_mul_data_rhs_reg[15] <= matrix_2[2][1] + matrix_2[2][3] + matrix_2[4][1];
		preadder_mul_data_rhs_reg[16] <= matrix_2[1][2] + matrix_2[1][4] + matrix_2[2][2] + matrix_2[2][3] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[17] <= matrix_2[1][2] + matrix_2[2][2] + matrix_2[2][3];
		preadder_mul_data_rhs_reg[18] <= matrix_2[1][2] + matrix_2[2][2] + matrix_2[2][3] + matrix_2[2][4] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[19] <= matrix_2[2][3] + matrix_2[2][4] + matrix_2[3][2] + matrix_2[4][2] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[20] <= matrix_2[3][2];
		preadder_mul_data_rhs_reg[21] <= matrix_2[2][3] + matrix_2[2][4] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[22] <= matrix_2[2][3] + matrix_2[2][4] + matrix_2[3][1] + matrix_2[3][4] + matrix_2[4][1];
		preadder_mul_data_rhs_reg[23] <= matrix_2[4][2] + matrix_2[4][3];
		preadder_mul_data_rhs_reg[24] <= matrix_2[2][3] + matrix_2[2][4] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[25] <= matrix_2[1][1] + matrix_2[2][1] + matrix_2[2][3] + matrix_2[2][4] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[26] <= matrix_2[1][1] + matrix_2[2][1] + matrix_2[2][3];
		preadder_mul_data_rhs_reg[27] <= matrix_2[4][3];
		preadder_mul_data_rhs_reg[28] <= matrix_2[1][2];
		preadder_mul_data_rhs_reg[29] <= matrix_2[3][4];
		preadder_mul_data_rhs_reg[30] <= matrix_2[1][1];
		preadder_mul_data_rhs_reg[31] <= matrix_2[1][1] + matrix_2[1][4] + matrix_2[2][1] + matrix_2[2][3] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[32] <= matrix_2[4][1];
		preadder_mul_data_rhs_reg[33] <= matrix_2[4][4];
		preadder_mul_data_rhs_reg[34] <= matrix_2[1][1] + matrix_2[1][2] + matrix_2[1][4];
		preadder_mul_data_rhs_reg[35] <= matrix_2[2][2] + matrix_2[2][3];
		preadder_mul_data_rhs_reg[36] <= matrix_2[2][3] + matrix_2[2][4] + matrix_2[3][2] + matrix_2[4][1];
		preadder_mul_data_rhs_reg[37] <= matrix_2[1][1] + matrix_2[2][2] + matrix_2[2][3] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[38] <= matrix_2[2][1] + matrix_2[2][2] + matrix_2[2][4];
		preadder_mul_data_rhs_reg[39] <= matrix_2[2][3];
		preadder_mul_data_rhs_reg[40] <= matrix_2[3][3];
		preadder_mul_data_rhs_reg[41] <= matrix_2[1][3] + matrix_2[1][4];

		preadder_mul_data_rhs_reg[42] <= matrix_2[2][1] + matrix_2[2][3];
		preadder_mul_data_rhs_reg[43] <= matrix_2[4][1] + matrix_2[4][2] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[44] <= matrix_2[3][1] + matrix_2[3][2] + matrix_2[3][4];
		preadder_mul_data_rhs_reg[45] <= matrix_2[3][1] + matrix_2[3][3];
		preadder_mul_data_rhs_reg[46] <= matrix_2[1][2] + matrix_2[2][1] + matrix_2[2][3] + matrix_2[4][4];
		preadder_mul_data_rhs_reg[47] <= matrix_2[2][3] + matrix_2[2][4];
	end
end
*/
assign preadder_data_out_lhs = preadder_mul_data_lhs_reg;
assign preadder_data_out_rhs = preadder_mul_data_rhs_reg;

//stage vld checking
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		preadder_vld_out_reg <= 'b0;
  	end
  	else begin
		preadder_vld_out_reg <= preadder_vld_in & !bru_flush;
  	end
end

assign preadder_vld_out = preadder_vld_out_reg;

//rd passing
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		rd_out_reg <= 'b0;
  	end
  	else begin
		rd_out_reg <= rd_in;
  	end
end

assign rd_out = rd_out_reg;

endmodule
