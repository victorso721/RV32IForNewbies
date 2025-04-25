//special arrangment on starting index for 2D array: start from 1 for eaiser counting
module u_postadder(
	//SOC input
	input clk,
	input rst_n,

	//Multiplier input
	input postadder_vld_in,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rd_in,
	input [`MATRIX_MEM_DATA_LENGTH-1:0] postadder_data_in [`MULITIPLICATION_NUM:1],	//h1 to h47

	//Data memory output
	output postadder_vld_out,
	output [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out,
	output [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_out
);

//internal signal
wire [`MATRIX_MEM_DATA_LENGTH-1:0] h [`MULITIPLICATION_NUM:1];	//h1 to h47
wire [`MATRIX_MEM_DATA_LENGTH-1:0] matrix [`ROW_NUM:1][`COL_NUM:1];
wire [`MATRIX_MEM_READ_MSB_INDEX:0] postadder_dmem_data_reg_q;
reg [`MATRIX_MEM_READ_MSB_INDEX:0] postadder_dmem_data_reg;
reg postadder_vld_out_reg;
reg [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out_reg;

//Matrix element regrouping
for(genvar i=0; i<(`ROW_NUM*`COL_NUM); i++) begin
	assign postadder_dmem_data_reg_q[i*`MATRIX_MEM_DATA_LENGTH+(`MATRIX_MEM_DATA_LENGTH-1):i*`MATRIX_MEM_DATA_LENGTH] = matrix[(i/`COL_NUM)+1][(i%`COL_NUM)+1];
end

always @(posedge clk) begin
	postadder_dmem_data_reg <= postadder_dmem_data_reg_q;
end

assign matrix_out = postadder_dmem_data_reg;

//Matrix element postadding
//Modulo 2 addition performed by bitwise XOR 
assign h = postadder_data_in;
assign matrix[1][1] = h[15] ^ h[26] ^ h[2] ^ h[30] ^ h[32] ^ h[39] ^ h[40] ^ h[42] ^ h[45] ^ h[7];
assign matrix[2][1] = h[11] ^ h[12] ^ h[14] ^ h[20] ^ h[22] ^ h[24] ^ h[25] ^ h[29] ^ h[35] ^ h[36] ^ h[37] ^ h[38] ^ h[44] ^ h[47];
assign matrix[3][1] = h[11] ^ h[12] ^ h[14] ^ h[15] ^ h[26] ^ h[30] ^ h[39] ^ h[42];
assign matrix[4][1] = h[15] ^ h[22] ^ h[24] ^ h[25] ^ h[26] ^ h[32] ^ h[39] ^ h[42];
assign matrix[1][2] = h[12] ^ h[17] ^ h[20] ^ h[23] ^ h[27] ^ h[28] ^ h[35] ^ h[39] ^ h[3] ^ h[9];
assign matrix[2][2] = h[12] ^ h[17] ^ h[18] ^ h[19] ^ h[20] ^ h[21] ^ h[35] ^ h[39];
assign matrix[3][2] = h[12] ^ h[13] ^ h[14] ^ h[15] ^ h[17] ^ h[28] ^ h[35] ^ h[39];
assign matrix[4][2] = h[13] ^ h[14] ^ h[15] ^ h[18] ^ h[19] ^ h[21] ^ h[32] ^ h[33] ^ h[36] ^ h[38] ^ h[42] ^ h[43] ^ h[46] ^ h[47];
assign matrix[1][3] = h[1] ^ h[27] ^ h[39] ^ h[40];
assign matrix[2][3] = h[16] ^ h[17] ^ h[18] ^ h[19] ^ h[21] ^ h[39] ^ h[40] ^ h[4] ^ h[6] ^ h[9];
assign matrix[3][3] = h[11] ^ h[12] ^ h[13] ^ h[14] ^ h[15] ^ h[1] ^ h[2] ^ h[39] ^ h[3] ^ h[5];
assign matrix[4][3] = h[10] ^ h[22] ^ h[24] ^ h[25] ^ h[26] ^ h[27] ^ h[31] ^ h[39] ^ h[7] ^ h[8];
assign matrix[1][4] = h[1] ^ h[21] ^ h[24] ^ h[29] ^ h[33] ^ h[39] ^ h[41] ^ h[47] ^ h[4] ^ h[8];
assign matrix[2][4] = h[16] ^ h[17] ^ h[18] ^ h[21] ^ h[24] ^ h[29] ^ h[39] ^ h[47];
assign matrix[3][4] = h[16] ^ h[17] ^ h[18] ^ h[25] ^ h[26] ^ h[28] ^ h[30] ^ h[31] ^ h[34] ^ h[35] ^ h[37] ^ h[38] ^ h[42] ^ h[46];
assign matrix[4][4] = h[21] ^ h[24] ^ h[25] ^ h[26] ^ h[31] ^ h[33] ^ h[39] ^ h[47];

/*
assign matrix[1][1] = h[15] + h[26] + h[2] + h[30] + h[32] + h[39] + h[40] + h[42] + h[45] + h[7];
assign matrix[2][1] = h[11] + h[12] + h[14] + h[20] + h[22] + h[24] + h[25] + h[29] + h[35] + h[36] + h[37] + h[38] + h[44] + h[47];
assign matrix[3][1] = h[11] + h[12] + h[14] + h[15] + h[26] + h[30] + h[39] + h[42];
assign matrix[4][1] = h[15] + h[22] + h[24] + h[25] + h[26] + h[32] + h[39] + h[42];
assign matrix[1][2] = h[12] + h[17] + h[20] + h[23] + h[27] + h[28] + h[35] + h[39] + h[3] + h[9];
assign matrix[2][2] = h[12] + h[17] + h[18] + h[19] + h[20] + h[21] + h[35] + h[39];
assign matrix[3][2] = h[12] + h[13] + h[14] + h[15] + h[17] + h[28] + h[35] + h[39];
assign matrix[4][2] = h[13] + h[14] + h[15] + h[18] + h[19] + h[21] + h[32] + h[33] + h[36] + h[38] + h[42] + h[43] + h[46] + h[47];
assign matrix[1][3] = h[1] + h[27] + h[39] + h[40];
assign matrix[2][3] = h[16] + h[17] + h[18] + h[19] + h[21] + h[39] + h[40] + h[4] + h[6] + h[9];
assign matrix[3][3] = h[11] + h[12] + h[13] + h[14] + h[15] + h[1] + h[2] + h[39] + h[3] + h[5];
assign matrix[4][3] = h[10] + h[22] + h[24] + h[25] + h[26] + h[27] + h[31] + h[39] + h[7] + h[8];
assign matrix[1][4] = h[1] + h[21] + h[24] + h[29] + h[33] + h[39] + h[41] + h[47] + h[4] + h[8];
assign matrix[2][4] = h[16] + h[17] + h[18] + h[21] + h[24] + h[29] + h[39] + h[47];
assign matrix[3][4] = h[16] + h[17] + h[18] + h[25] + h[26] + h[28] + h[30] + h[31] + h[34] + h[35] + h[37] + h[38] + h[42] + h[46];
assign matrix[4][4] = h[21] + h[24] + h[25] + h[26] + h[31] + h[33] + h[39] + h[47];
*/
//stage vld passing
always @(posedge clk) begin
	if(~rst_n) begin
		postadder_vld_out_reg <= 'b0;
  	end
  	else begin
		postadder_vld_out_reg <= postadder_vld_in;
  	end
end

assign postadder_vld_out = postadder_vld_out_reg;

//rd passing
always @(posedge clk) begin
	if(~rst_n) begin
		rd_out_reg <= 'b0;
  	end
  	else begin
		rd_out_reg <= rd_in;
  	end
end

assign rd_out = rd_out_reg;

endmodule
