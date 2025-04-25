module u_DMem_512X128(
	//SOC input
	input clk,

	//ALU module input
	input [`DATA_MEM_DEPTH_BIT-1:0] addr,
	input ren,

	//Writing
	input [`DATA_MEM_WIDTH-1:0] wen,
	input [`DATA_MEM_WIDTH-1:0] wr_data,

	//Reading
	output [`DATA_MEM_WIDTH-1:0] rd_data

);

//internal signal
reg [`DATA_MEM_WIDTH-1:0] mem [`DATA_MEM_DEPTH];
reg [`DATA_MEM_WIDTH-1:0] rd_data_reg;

//Writing
always @(posedge clk) begin
	if(|wen) begin
		mem[addr] <= (mem[addr] & !wen) | (wr_data & wen);
	end
end

//Reading
assign rd_data = rd_data_reg;
always @(posedge clk) begin
	if(ren) begin
 		rd_data_reg <= mem[addr];
	end
end

endmodule

