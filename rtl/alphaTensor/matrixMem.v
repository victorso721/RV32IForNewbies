module u_MatrixMem(
	//SOC input
	input clk,

	//Top module input
	//Writing
	input wen,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rd_idx,
	input [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_wr_data,

	//Reading
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rs1_idx,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rs2_idx,
	output [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_rd_data_1,
	output [`MATRIX_MEM_READ_MSB_INDEX:0] matrix_rd_data_2

);

//internal signal
reg [`MATRIX_MEM_READ_MSB_INDEX:0] mem [`MATRIX_MEM_DEPTH-1:0];

//Writing
always @(posedge clk) begin
	if(wen) begin
		mem[rd_idx] <= matrix_wr_data;
	end
end

//Reading
assign matrix_rd_data_1 = mem[rs1_idx];
assign matrix_rd_data_2 = mem[rs2_idx];

endmodule
