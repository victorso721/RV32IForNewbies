module u_lsu (
	//SOC input
	input							clk,
	input							rst_n,

	//ALU input
	input	[`PC_WIDTH-1:0]			iex_lsu_pc,
	input							iex_lsu_pipe_vld,
	input	[`RF_DEPTH_BIT-1:0]		iex_lsu_rd,
	input							iex_lsu_is_load,
	input							iex_lsu_rd_vld,
	input							iex_lsu_rf_wen,
	input	[`DATA_WIDTH-1:0]		iex_lsu_cal_data,
	input	[`DATA_WIDTH-1:0]		iex_lsu_dmem_wr_data,		//Not flopped
	input	[`DATA_WIDTH-1:0]		iex_lsu_dmem_addr,			//Not flopped
	input							iex_lsu_dmem_ren,			//Not flopped
	input							iex_lsu_flag_unsigned_data,
	input							iex_lsu_flag_dmem_lb,
	input							iex_lsu_flag_dmem_lh,
	input							iex_lsu_flag_dmem_lw,
	input							iex_lsu_flag_dmem_sw,		//Not flopped
	input							iex_lsu_flag_dmem_sb,		//Not flopped
	input							iex_lsu_flag_dmem_sh,		//Not flopped

	//RF output
	output	[`PC_WIDTH-1:0]			lsu_rf_pc,
	output							lsu_rf_pipe_vld,
	output	[`RF_DEPTH_BIT-1:0]		lsu_rf_rd,
	output							lsu_rf_wen,
	output	[`DATA_WIDTH-1:0]		lsu_rf_wr_data,
	
	//IDU output
	output	[`DATA_WIDTH-1:0]		lsu_idu_byp_data,
	output	[`RF_DEPTH_BIT-1:0]		lsu_idu_rd,
	output							lsu_idu_pipe_vld,
	output							lsu_idu_rd_vld,
	output							lsu_idu_is_load,

	//Dmem output
	output	[`DATA_MEM_WIDTH-1:0]	lsu_dmem_extended_wen,
	output	[`DATA_MEM_WIDTH-1:0]	lsu_dmem_extended_wr_data,
	output							lsu_dmem_ren,				//Feed-Through wire, just to maintain interface port for easy adjustment

	//Dmem input
	input	[`DATA_MEM_WIDTH-1:0]	dmem_lsu_rd_data

);

//Intern signals
wire	[`DATA_WIDTH-1:0]	selected_dmem_data;
wire	[`DATA_WIDTH-1:0]	path_selected_data;

reg		[`DATA_WIDTH-1:0]	lsu_rf_wr_data_reg;
reg		[`PC_WIDTH-1:0]		lsu_rf_pc_reg;
reg							lsu_rf_pipe_vld_reg;
reg		[`RF_DEPTH_BIT-1:0]	lsu_rf_rd_reg;
reg							lsu_rf_wen_reg;
/*
//wire [`DATA_MEM_WIDTH-1:0] dmem_lsu_rd_data;
//wire [`DATA_MEM_WIDTH-1:0] extended_wen;
//wire [`DATA_MEM_WIDTH-1:0] extended_wr_data;
Superscalar archi Dmem is located in Wrapper
//DATA MEM declaration
u_DMem_512X128 dmem(
	.clk		(clk),
	.addr		(iex_lsu_dmem_addr[`DATA_MEM_DEPTH_BIT+`DATA_MEM_WIDTH_BIT:`DATA_MEM_WIDTH_BIT]),
	.ren		(iex_lsu_dmem_ren),
	.wen		(extended_wen),
	.wr_data	(extended_wr_data),
	.rd_data	(dmem_lsu_rd_data)
);
*/
//LOAD
assign path_selected_data = (iex_lsu_is_load)? selected_dmem_data : iex_lsu_cal_data;
//Data selector 
u_lsu_load_data_selector load_data_selector(
	.lb					(iex_lsu_flag_dmem_lb),
	.lh					(iex_lsu_flag_dmem_lh),
	.lw					(iex_lsu_flag_dmem_lw),
	.unsigned_data		(iex_lsu_flag_unsigned_data),
	.addr				(iex_lsu_cal_data[`DATA_MEM_WIDTH_BIT-1:0]),
	.rd_data			(dmem_lsu_rd_data),
	.selected_dmem_data	(selected_dmem_data)
);

//STORE
//WEN and WR DATA extension
u_lsu_store_data_extensor store_data_extensor(
	.sb					(iex_lsu_flag_dmem_sb),
	.sh					(iex_lsu_flag_dmem_sh),
	.sw					(iex_lsu_flag_dmem_sw),
	.addr				(iex_lsu_dmem_addr[`DATA_MEM_WIDTH_BIT-1:0]),
	.wr_data			(iex_lsu_dmem_wr_data),
	.extended_wr_data	(lsu_dmem_extended_wr_data),
	.extended_wen		(lsu_dmem_extended_wen)
);

//Interface assignment
assign	lsu_rf_wr_data	=	lsu_rf_wr_data_reg;
assign	lsu_rf_pc		=	lsu_rf_pc_reg;
assign	lsu_rf_pipe_vld	=	lsu_rf_pipe_vld_reg;
assign	lsu_rf_rd		=	lsu_rf_rd_reg;
assign	lsu_rf_wen		=	lsu_rf_wen_reg;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		lsu_rf_pipe_vld_reg	<=	'b0;
	end
	else begin
		lsu_rf_pipe_vld_reg	<=	iex_lsu_pipe_vld;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		lsu_rf_wr_data_reg	<=	'b0;
		lsu_rf_pc_reg		<=	'b0;
		lsu_rf_rd_reg		<=	'b0;
		lsu_rf_wen_reg		<=	'b0;
	end
	else if(iex_lsu_pipe_vld) begin
		lsu_rf_wr_data_reg	<=	path_selected_data;
		lsu_rf_pc_reg		<=	iex_lsu_pc;
		lsu_rf_rd_reg		<=	iex_lsu_rd;
		lsu_rf_wen_reg		<=	iex_lsu_rf_wen;
	end
end

//Bypass path
assign	lsu_idu_byp_data	=	iex_lsu_cal_data; //data from memory do not have bypass path for timing concern
assign	lsu_idu_rd			=	iex_lsu_rd;
assign	lsu_idu_rd_vld		=	iex_lsu_rd_vld;
assign	lsu_idu_pipe_vld 	=	iex_lsu_pipe_vld;
assign	lsu_idu_is_load 	=	iex_lsu_is_load;	

//FT wire
assign lsu_dmem_ren = iex_lsu_dmem_ren;

endmodule
