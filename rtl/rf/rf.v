module u_rf (
	//SOC input
	input						clk,
	input						rst_n,

	//LSU input
	input	[`PC_WIDTH-1:0]		lsu_rf_pc			[`SUPER_SCALAR_NUM-1:0],
	input						lsu_rf_pipe_vld	[`SUPER_SCALAR_NUM-1:0],
	input						lsu_rf_wen			[`SUPER_SCALAR_NUM-1:0],
	input	[`RF_DEPTH_BIT-1:0]	lsu_rf_rd			[`SUPER_SCALAR_NUM-1:0], 
	input	[`DATA_WIDTH-1:0]	lsu_rf_wr_data		[`SUPER_SCALAR_NUM-1:0],

	//IDU input
	input	[`RF_DEPTH_BIT-1:0]	idu_rf_rs1_idx		[`RF_READ_PORT_NUM-1:0],
	input	[`RF_DEPTH_BIT-1:0]	idu_rf_rs2_idx		[`RF_READ_PORT_NUM-1:0],
	
	//IDU output
	output	[`DATA_WIDTH-1:0]	rf_idu_rs1_data		[`RF_READ_PORT_NUM-1:0],
	output	[`DATA_WIDTH-1:0]	rf_idu_rs2_data		[`RF_READ_PORT_NUM-1:0],
	output	[`DATA_WIDTH-1:0]	rf_idu_byp_data		[`SUPER_SCALAR_NUM-1:0],
	output						rf_idu_pipe_vld		[`SUPER_SCALAR_NUM-1:0],
	output						rf_idu_rd_vld		[`SUPER_SCALAR_NUM-1:0],
	output	[`RF_DEPTH_BIT-1:0]	rf_idu_rd			[`SUPER_SCALAR_NUM-1:0]

);

//internal signals
reg [`RF_DEPTH-1:0] [`DATA_WIDTH-1:0] rf_data_array;	
wire  rf_wen	[`SUPER_SCALAR_NUM-1:0];
//Write dependency checking
//Difficulties for n write port: try to make checking into for extentable structure > word generating through python is needed
//rd == 0 writing is blocked in idu_instDecode
assign rf_wen[0] = lsu_rf_pipe_vld[0] & lsu_rf_wen[0] & (lsu_rf_rd[0] != lsu_rf_rd[1]);
assign rf_wen[1] = lsu_rf_pipe_vld[1] & lsu_rf_wen[1];

//Data writing
always @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		for(int i=0; i<`RF_DEPTH; i++) begin
			rf_data_array[i] <= 'b0;
		end
	end
	else begin 
		for(int i=0; i<`SUPER_SCALAR_NUM; i++) begin
			if(rf_wen[i]) begin
				rf_data_array[lsu_rf_rd[i]] <= lsu_rf_wr_data[i];
			end
		end
	end
end

//Data Reading
for(genvar i=0; i<`RF_READ_PORT_NUM; i++) begin
	assign rf_idu_rs1_data[i] = rf_data_array[idu_rf_rs1_idx[i]];
	assign rf_idu_rs2_data[i] = rf_data_array[idu_rf_rs2_idx[i]];
end

//Bypass path
assign	rf_idu_byp_data		=	lsu_rf_wr_data;
assign	rf_idu_rd			=	lsu_rf_rd;
assign	rf_idu_pipe_vld		=	lsu_rf_pipe_vld;
assign	rf_idu_rd_vld		=	rf_wen;

endmodule
