//LSU Wrapper under Superscalar scheme
//LSU 1,2
//DATA MEMORY with 1r1w port
//SELECTION MUX to select result from ALU 1 or 2, dispatcher in IDU only allow 1 memory access in one cycle

module u_lsu_super_scalar_wrapper (
	//SOC input
	input						clk,
	input						rst_n,

	//ALU input
	input						iex_lsu_pipe_vld			[`SUPER_SCALAR_NUM-1:0],
	input	[`PC_WIDTH-1:0]		iex_lsu_pc					[`SUPER_SCALAR_NUM-1:0],
	input	[`RF_DEPTH_BIT-1:0]	iex_lsu_rd					[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_is_load			[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_rd_vld				[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_rf_wen				[`SUPER_SCALAR_NUM-1:0],
	input	[`DATA_WIDTH-1:0]	iex_lsu_cal_data			[`SUPER_SCALAR_NUM-1:0],
	input	[`DATA_WIDTH-1:0]	iex_lsu_dmem_wr_data		[`SUPER_SCALAR_NUM-1:0],		//Not flopped
	input	[`DATA_WIDTH-1:0]	iex_lsu_dmem_addr			[`SUPER_SCALAR_NUM-1:0],		//Not flopped
	input						iex_lsu_dmem_ren			[`SUPER_SCALAR_NUM-1:0],		//Not flopped
	input						iex_lsu_flag_unsigned_data	[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_flag_dmem_lb		[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_flag_dmem_lh		[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_flag_dmem_lw		[`SUPER_SCALAR_NUM-1:0],
	input						iex_lsu_flag_dmem_sw		[`SUPER_SCALAR_NUM-1:0],		//Not flopped
	input						iex_lsu_flag_dmem_sb		[`SUPER_SCALAR_NUM-1:0],		//Not flopped
	input						iex_lsu_flag_dmem_sh		[`SUPER_SCALAR_NUM-1:0],		//Not flopped

	//RF output
	output	[`PC_WIDTH-1:0]		lsu_rf_pc					[`SUPER_SCALAR_NUM-1:0],
	output						lsu_rf_pipe_vld				[`SUPER_SCALAR_NUM-1:0],
	output	[`RF_DEPTH_BIT-1:0]	lsu_rf_rd					[`SUPER_SCALAR_NUM-1:0],
	output						lsu_rf_wen					[`SUPER_SCALAR_NUM-1:0],
	output	[`DATA_WIDTH-1:0]	lsu_rf_wr_data				[`SUPER_SCALAR_NUM-1:0],

	//IDU output
	output	[`DATA_WIDTH-1:0]	lsu_idu_byp_data			[`SUPER_SCALAR_NUM-1:0],
	output	[`RF_DEPTH_BIT-1:0]	lsu_idu_rd					[`SUPER_SCALAR_NUM-1:0],
	output						lsu_idu_pipe_vld			[`SUPER_SCALAR_NUM-1:0],
	output						lsu_idu_rd_vld				[`SUPER_SCALAR_NUM-1:0],
	output						lsu_idu_is_load				[`SUPER_SCALAR_NUM-1:0]
);

//Intern signals
wire	[`DATA_MEM_WIDTH-1:0]	dmem_lsu_rd_data;
wire				lsu_dmem_ren		[`SUPER_SCALAR_NUM-1:0];
wire							dmem_ren;
wire	[`DATA_MEM_WIDTH-1:0]	extended_wen		[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_MEM_WIDTH-1:0]	extended_wr_data	[`SUPER_SCALAR_NUM-1:0];
wire	[`DATA_WIDTH-1:0]		lsu_dmem_addr;
wire	[`DATA_MEM_WIDTH-1:0]	lsu_dmem_extended_wr_data;
wire	[`DATA_MEM_WIDTH-1:0]	lsu_dmem_extended_wen;
//wire	[`DATA_MEM_DEPTH_BIT-1+:0]	iex_lsu_dmem_addr_clipped	[`SUPER_SCALAR_NUM-1:0];

//assign iex_lsu_dmem_addr_clipped[0] = iex_lsu_dmem_addr[0][`DATA_MEM_DEPTH_BIT-1+`DATA_MEM_WIDTH_BIT:`DATA_MEM_WIDTH_BIT];
//assign iex_lsu_dmem_addr_clipped[1] = iex_lsu_dmem_addr[1][`DATA_MEM_DEPTH_BIT-1+`DATA_MEM_WIDTH_BIT:`DATA_MEM_WIDTH_BIT];
//assign lsu_dmem_addr = (lsu_dmem_ren[0] | iex_lsu_flag_dmem_sb[0] | iex_lsu_flag_dmem_sh[0] | iex_lsu_flag_dmem_sw[0])? iex_lsu_dmem_addr_clipped[0] : iex_lsu_dmem_addr_clipped[1];
assign lsu_dmem_addr = (lsu_dmem_ren[0] | iex_lsu_flag_dmem_sb[0] | iex_lsu_flag_dmem_sh[0] | iex_lsu_flag_dmem_sw[0])? iex_lsu_dmem_addr[0] : iex_lsu_dmem_addr[1];
assign dmem_ren = lsu_dmem_ren[0] | lsu_dmem_ren[1];
assign lsu_dmem_extended_wen = extended_wen[0] | extended_wen[1]; 			//Not optimzied
assign lsu_dmem_extended_wr_data = (iex_lsu_flag_dmem_sb[0] | iex_lsu_flag_dmem_sh[0] | iex_lsu_flag_dmem_sw[0])? extended_wr_data[0] : extended_wr_data[1]; //Not optimzied

//DATA MEM declaration
u_DMem_512X128 dmem(
	.clk		(clk),
	.addr		(lsu_dmem_addr[`DATA_MEM_DEPTH_BIT-1+`DATA_MEM_WIDTH_BIT:`DATA_MEM_WIDTH_BIT]),
	.ren		(dmem_ren),
	.wen		(lsu_dmem_extended_wen),
	.wr_data	(lsu_dmem_extended_wr_data),
	.rd_data	(dmem_lsu_rd_data)
);

u_lsu lsu_0(
	.clk						(clk),
	.rst_n						(rst_n),
	.iex_lsu_pc				(iex_lsu_pc[0]),
	.iex_lsu_pipe_vld			(iex_lsu_pipe_vld[0]),
	.iex_lsu_rd					(iex_lsu_rd[0]),
	.iex_lsu_is_load		(iex_lsu_is_load[0]),
	.iex_lsu_rd_vld				(iex_lsu_rd_vld[0]),
	.iex_lsu_rf_wen				(iex_lsu_rf_wen[0]),
	.iex_lsu_cal_data			(iex_lsu_cal_data[0]),
	.iex_lsu_dmem_wr_data		(iex_lsu_dmem_wr_data[0]),
	.iex_lsu_dmem_addr			(iex_lsu_dmem_addr[0]),
	.iex_lsu_dmem_ren			(iex_lsu_dmem_ren[0]),
	.iex_lsu_flag_unsigned_data	(iex_lsu_flag_unsigned_data[0]),
	.iex_lsu_flag_dmem_lb		(iex_lsu_flag_dmem_lb[0]),
	.iex_lsu_flag_dmem_lh		(iex_lsu_flag_dmem_lh[0]),
	.iex_lsu_flag_dmem_lw		(iex_lsu_flag_dmem_lw[0]),
	.iex_lsu_flag_dmem_sb		(iex_lsu_flag_dmem_sb[0]),
	.iex_lsu_flag_dmem_sh		(iex_lsu_flag_dmem_sh[0]),
	.iex_lsu_flag_dmem_sw		(iex_lsu_flag_dmem_sw[0]),
	.lsu_rf_pc					(lsu_rf_pc[0]),
	.lsu_rf_pipe_vld			(lsu_rf_pipe_vld[0]),
	.lsu_rf_rd					(lsu_rf_rd[0]),
	.lsu_rf_wen					(lsu_rf_wen[0]),
	.lsu_rf_wr_data				(lsu_rf_wr_data[0]),
	.lsu_idu_byp_data			(lsu_idu_byp_data[0]),
	.lsu_idu_pipe_vld			(lsu_idu_pipe_vld[0]),
	.lsu_idu_rd					(lsu_idu_rd[0]),
	.lsu_idu_rd_vld				(lsu_idu_rd_vld[0]),
	.lsu_idu_is_load			(lsu_idu_is_load[0]),
	.lsu_dmem_extended_wen		(extended_wen[0]),
	.lsu_dmem_extended_wr_data	(extended_wr_data[0]),
	.lsu_dmem_ren				(lsu_dmem_ren[0]),
	.dmem_lsu_rd_data			(dmem_lsu_rd_data)
);

u_lsu lsu_1 (
	.clk						(clk),
	.rst_n						(rst_n),
	.iex_lsu_pc				(iex_lsu_pc[1]),
	.iex_lsu_pipe_vld			(iex_lsu_pipe_vld[1]),
	.iex_lsu_rd					(iex_lsu_rd[1]),
	.iex_lsu_is_load		(iex_lsu_is_load[1]),
	.iex_lsu_rd_vld				(iex_lsu_rd_vld[1]),
	.iex_lsu_rf_wen				(iex_lsu_rf_wen[1]),
	.iex_lsu_cal_data			(iex_lsu_cal_data[1]),
	.iex_lsu_dmem_wr_data		(iex_lsu_dmem_wr_data[1]),
	.iex_lsu_dmem_addr			(iex_lsu_dmem_addr[1]),
	.iex_lsu_dmem_ren			(iex_lsu_dmem_ren[1]),
	.iex_lsu_flag_unsigned_data	(iex_lsu_flag_unsigned_data[1]),
	.iex_lsu_flag_dmem_lb		(iex_lsu_flag_dmem_lb[1]),
	.iex_lsu_flag_dmem_lh		(iex_lsu_flag_dmem_lh[1]),
	.iex_lsu_flag_dmem_lw		(iex_lsu_flag_dmem_lw[1]),
	.iex_lsu_flag_dmem_sb		(iex_lsu_flag_dmem_sb[1]),
	.iex_lsu_flag_dmem_sh		(iex_lsu_flag_dmem_sh[1]),
	.iex_lsu_flag_dmem_sw		(iex_lsu_flag_dmem_sw[1]),
	.lsu_rf_pc					(lsu_rf_pc[1]),
	.lsu_rf_pipe_vld			(lsu_rf_pipe_vld[1]),
	.lsu_rf_rd					(lsu_rf_rd[1]),
	.lsu_rf_wen					(lsu_rf_wen[1]),
	.lsu_rf_wr_data				(lsu_rf_wr_data[1]),
	.lsu_idu_byp_data			(lsu_idu_byp_data[1]),
	.lsu_idu_pipe_vld			(lsu_idu_pipe_vld[1]),
	.lsu_idu_rd					(lsu_idu_rd[1]),
	.lsu_idu_rd_vld				(lsu_idu_rd_vld[1]),
	.lsu_idu_is_load			(lsu_idu_is_load[1]),
	.lsu_dmem_extended_wen		(extended_wen[1]),
	.lsu_dmem_extended_wr_data	(extended_wr_data[1]),
	.lsu_dmem_ren				(lsu_dmem_ren[1]),
	.dmem_lsu_rd_data			(dmem_lsu_rd_data)
);

endmodule
