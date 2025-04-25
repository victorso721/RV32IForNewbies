module u_IMem_256X32_2R1W(
	//SOC input
	input clk,

	//ALU module input
	input [`INST_MEM_DEPTH_BIT-1:0] addr,
	input cen,

	//Writing
	input wen,
	input [`INST_MEM_WIDTH-1:0] wr_data,

	//Reading
	output [`INST_MEM_WIDTH-1:0] rd_data_1,
	output [`INST_MEM_WIDTH-1:0] rd_data_2

);

//internal signal
reg [`INST_MEM_WIDTH-1:0] mem [`INST_MEM_DEPTH-1:0];
reg [`INST_MEM_WIDTH-1:0] rd_data_reg_1;
reg [`INST_MEM_WIDTH-1:0] rd_data_reg_2;

//Writing
//INST MEM is writing by blackbox in this project
always @(posedge clk) begin
	if(wen & cen) begin
		mem[addr] <= wr_data;
	end
end

//Reading
assign rd_data_1 = rd_data_reg_1;
assign rd_data_2 = rd_data_reg_2;
always @(posedge clk) begin
	if(!wen & cen) begin
 		rd_data_reg_1 <= mem[addr];
		rd_data_reg_2 <= mem[addr + 1];
	end
end

endmodule
