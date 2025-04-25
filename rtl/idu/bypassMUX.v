//Bypass MUX
//1. collect calculation result from different stage(EX/M/WB)
//2. determine whether result collected are valid(not a LOAD instruction for EX/M stage)
//3. check if rs1/rs2 in IDU have data dependency on either one of them(if more than one(i.e. RAWAW), action depends on the youngest dependency instruction)
//3.1 if older instruction induce stall and younger instruction induce bypass, bypass is taken instead of stall

module u_idu_bypassMUX (

	//RF read data
	input [`DATA_WIDTH-1:0] rf_idu_rs1_data,
	input [`DATA_WIDTH-1:0] rf_idu_rs2_data,

	//ALU bypass data 1,2
	input [`DATA_WIDTH-1:0] iex_idu_byp_data [`SUPER_SCALAR_NUM-1:0],

	//LSU bypass data 1,2
	input [`DATA_WIDTH-1:0] lsu_idu_byp_data [`SUPER_SCALAR_NUM-1:0],

	//RF bypass data 1,2
	input [`DATA_WIDTH-1:0] rf_idu_byp_data [`SUPER_SCALAR_NUM-1:0],

	//Selection control
	//Selection priority
	//1.ALU 2
	//2.ALU 1
	input [`RF_DEPTH_BIT-1:0] iex_idu_byp_rd [`SUPER_SCALAR_NUM-1:0],
	input iex_idu_rd_vld [`SUPER_SCALAR_NUM-1:0],
	input iex_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0],
	input iex_idu_is_load [`SUPER_SCALAR_NUM-1:0],
	//3.LSU 2
	//4.LSU 1
	input [`RF_DEPTH_BIT-1:0] lsu_idu_byp_rd [`SUPER_SCALAR_NUM-1:0],
	input lsu_idu_rd_vld [`SUPER_SCALAR_NUM-1:0],
	input lsu_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0],
	input lsu_idu_is_load [`SUPER_SCALAR_NUM-1:0],
	//5.RF 2
	//6.RF 1
	input [`RF_DEPTH_BIT-1:0] rf_idu_byp_rd [`SUPER_SCALAR_NUM-1:0],
	input rf_idu_rd_vld [`SUPER_SCALAR_NUM-1:0],
	input rf_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0],
	//7.RF read output
	//if rs invalid, choose read result directly, stall and bypass checking result invalid
	input [`RF_DEPTH_BIT-1:0] inst_rs1_idx,
	input [`RF_DEPTH_BIT-1:0] inst_rs2_idx,
	input inst_rs1_idx_vld,
	input inst_rs2_idx_vld,
	
	//data output
	output [`DATA_WIDTH-1:0] idu_iex_rs1_data,
	output [`DATA_WIDTH-1:0] idu_iex_rs2_data,

	//Control output to dispatcher
	//stall
	output idu_dispatcher_stall_vld

);

//Internal signal
wire [`SUPER_SCALAR_NUM-1:0] iex_rd_match_rs1;
wire [`SUPER_SCALAR_NUM-1:0] lsu_rd_match_rs1;
wire [`SUPER_SCALAR_NUM-1:0] rf_rd_match_rs1;

wire [`SUPER_SCALAR_NUM-1:0] iex_rd_match_rs2;
wire [`SUPER_SCALAR_NUM-1:0] lsu_rd_match_rs2;
wire [`SUPER_SCALAR_NUM-1:0] rf_rd_match_rs2;

wire [`SUPER_SCALAR_NUM-1:0] iex_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] lsu_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] rf_byp_vld;

wire [`SUPER_SCALAR_NUM-1:0] iex_load_vld;
wire [`SUPER_SCALAR_NUM-1:0] lsu_load_vld;

wire [`SUPER_SCALAR_NUM-1:0] rs1_iex_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs1_lsu_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs1_rf_byp_vld;

wire [`SUPER_SCALAR_NUM-1:0] rs1_iex_stall_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs1_lsu_stall_vld;

wire [`SUPER_SCALAR_NUM-1:0] rs2_iex_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs2_lsu_byp_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs2_rf_byp_vld;

wire [`SUPER_SCALAR_NUM-1:0] rs2_iex_stall_vld;
wire [`SUPER_SCALAR_NUM-1:0] rs2_lsu_stall_vld;

wire [`DATA_WIDTH-1:0] rs1_iex_byp_data;
wire [`DATA_WIDTH-1:0] rs1_lsu_byp_data;
wire [`DATA_WIDTH-1:0] rs1_rf_byp_data;

wire [`DATA_WIDTH-1:0] rs2_iex_byp_data;
wire [`DATA_WIDTH-1:0] rs2_lsu_byp_data;
wire [`DATA_WIDTH-1:0] rs2_rf_byp_data;

wire rs1_iex_byp_vld_bit;
wire rs1_lsu_byp_vld_bit;
wire rs1_rf_byp_vld_bit;

wire rs2_iex_byp_vld_bit;
wire rs2_lsu_byp_vld_bit;
wire rs2_rf_byp_vld_bit;

wire [`DATA_WIDTH-1:0] rs1_byp_data;
wire [`DATA_WIDTH-1:0] rs2_byp_data;

wire rs1_stall_vld;
wire rs2_stall_vld;

//Layer
//1.Compare to all result data seperately
//1.1 ALU byp vld, ALU stall vld, LSU byp vld...
//1.2 LSU check ALU byp vld or ALU stall vld = 0, RF check LSU and ALU...
for( genvar i = 0; i < `SUPER_SCALAR_NUM; i++) begin
	assign iex_rd_match_rs1[i]	= inst_rs1_idx_vld & (inst_rs1_idx == iex_idu_byp_rd[i]);
	assign lsu_rd_match_rs1[i]	= inst_rs1_idx_vld & (inst_rs1_idx == lsu_idu_byp_rd[i]);
	assign rf_rd_match_rs1[i]	= inst_rs1_idx_vld & (inst_rs1_idx == rf_idu_byp_rd[i]);
	assign iex_rd_match_rs2[i]	= inst_rs2_idx_vld & (inst_rs2_idx == iex_idu_byp_rd[i]);
	assign lsu_rd_match_rs2[i]	= inst_rs2_idx_vld & (inst_rs2_idx == lsu_idu_byp_rd[i]);
	assign rf_rd_match_rs2[i]	= inst_rs2_idx_vld & (inst_rs2_idx == rf_idu_byp_rd[i]);
	assign iex_byp_vld[i] 		= iex_idu_pipe_vld[i] & iex_idu_rd_vld[i] & ~iex_idu_is_load[i];
	assign lsu_byp_vld[i]		= lsu_idu_pipe_vld[i] & lsu_idu_rd_vld[i] & ~lsu_idu_is_load[i];
	assign rf_byp_vld[i]		= rf_idu_pipe_vld[i] & rf_idu_rd_vld[i];
	assign iex_load_vld[i] 		= iex_idu_pipe_vld[i] & iex_idu_is_load[i];
	assign lsu_load_vld[i]		= lsu_idu_pipe_vld[i] & lsu_idu_is_load[i];
	assign rs1_iex_byp_vld[i]	= iex_byp_vld[i] & iex_rd_match_rs1[i];
	assign rs1_lsu_byp_vld[i]	= lsu_byp_vld[i] & lsu_rd_match_rs1[i];
	assign rs1_rf_byp_vld[i]	= rf_byp_vld[i] & rf_rd_match_rs1[i];
	assign rs1_iex_stall_vld[i]	= iex_load_vld[i] & iex_rd_match_rs1[i];
	assign rs1_lsu_stall_vld[i]	= lsu_load_vld[i] & lsu_rd_match_rs1[i];
	assign rs2_iex_byp_vld[i]	= iex_byp_vld[i] & iex_rd_match_rs2[i];
	assign rs2_lsu_byp_vld[i]	= lsu_byp_vld[i] & lsu_rd_match_rs2[i];
	assign rs2_rf_byp_vld[i]	= rf_byp_vld[i] & rf_rd_match_rs2[i];
	assign rs2_iex_stall_vld[i]	= iex_load_vld[i] & iex_rd_match_rs2[i];
	assign rs2_lsu_stall_vld[i]	= lsu_load_vld[i] & lsu_rd_match_rs2[i];
end

//2. two layer of Parallel MUX
//Bypass path don't need to consider stall
//result will not pass to ALU if stall is detected
//2.1 2-to-1 MUX
//2.2 4-to-1 MUX
//2.1
//ALU
//for bypass data, use if(rs1_iex_byp_vld[1])? iex_idu_byp_data[1] : iex_idu_byp_data[0] is better in terms of area
//approach below is used for easier verification
assign rs1_iex_byp_data = ({`DATA_WIDTH{rs1_iex_byp_vld[1]}} & iex_idu_byp_data[1]) | ({`DATA_WIDTH{rs1_iex_byp_vld[0] & ~rs1_iex_byp_vld[1]}} & iex_idu_byp_data[0]);
assign rs1_iex_byp_vld_bit = |rs1_iex_byp_vld; // indicate whether this stage has bypass vld

assign rs2_iex_byp_data = ({`DATA_WIDTH{rs2_iex_byp_vld[1]}} & iex_idu_byp_data[1]) | ({`DATA_WIDTH{rs2_iex_byp_vld[0] & ~rs2_iex_byp_vld[1]}} & iex_idu_byp_data[0]);
assign rs2_iex_byp_vld_bit = |rs2_iex_byp_vld;

//LSU
assign rs1_lsu_byp_data = ({`DATA_WIDTH{rs1_lsu_byp_vld[1]}} & lsu_idu_byp_data[1]) | ({`DATA_WIDTH{rs1_lsu_byp_vld[0] & ~rs1_lsu_byp_vld[1]}} & lsu_idu_byp_data[0]);
assign rs1_lsu_byp_vld_bit = |rs1_lsu_byp_vld;

assign rs2_lsu_byp_data = ({`DATA_WIDTH{rs2_lsu_byp_vld[1]}} & lsu_idu_byp_data[1]) | ({`DATA_WIDTH{rs2_lsu_byp_vld[0] & ~rs2_lsu_byp_vld[1]}} & lsu_idu_byp_data[0]);
assign rs2_lsu_byp_vld_bit = |rs2_lsu_byp_vld;

//RF
assign rs1_rf_byp_data = ({`DATA_WIDTH{rs1_rf_byp_vld[1]}} & rf_idu_byp_data[1]) | ({`DATA_WIDTH{rs1_rf_byp_vld[0] & ~rs1_rf_byp_vld[1]}} & rf_idu_byp_data[0]);
assign rs1_rf_byp_vld_bit = |rs1_rf_byp_vld;

assign rs2_rf_byp_data = ({`DATA_WIDTH{rs2_rf_byp_vld[1]}} & rf_idu_byp_data[1]) | ({`DATA_WIDTH{rs2_rf_byp_vld[0] & ~rs2_rf_byp_vld[1]}} & rf_idu_byp_data[0]);
assign rs2_rf_byp_vld_bit = |rs2_rf_byp_vld;

//2.2
//Question: Why RF read data masking instead of RS1/2 idx masking is used?
//Answer: Timing concern.
assign rs1_byp_data = ({`DATA_WIDTH{rs1_iex_byp_vld_bit}} & rs1_iex_byp_data) | ({`DATA_WIDTH{rs1_lsu_byp_vld_bit & ~rs1_iex_byp_vld_bit}} & rs1_lsu_byp_data) | ({`DATA_WIDTH{rs1_rf_byp_vld_bit & ~rs1_lsu_byp_vld_bit & ~rs1_iex_byp_vld_bit}} & rs1_rf_byp_data) | ({`DATA_WIDTH{~rs1_rf_byp_vld_bit & ~rs1_lsu_byp_vld_bit & ~rs1_iex_byp_vld_bit & inst_rs1_idx_vld}} & rf_idu_rs1_data);
assign rs2_byp_data = ({`DATA_WIDTH{rs2_iex_byp_vld_bit}} & rs2_iex_byp_data) | ({`DATA_WIDTH{rs2_lsu_byp_vld_bit & ~rs2_iex_byp_vld_bit}} & rs2_lsu_byp_data) | ({`DATA_WIDTH{rs2_rf_byp_vld_bit & ~rs2_lsu_byp_vld_bit & ~rs2_iex_byp_vld_bit}} & rs2_rf_byp_data) | ({`DATA_WIDTH{~rs2_rf_byp_vld_bit & ~rs2_lsu_byp_vld_bit & ~rs2_iex_byp_vld_bit & inst_rs2_idx_vld}} & rf_idu_rs2_data);

assign idu_iex_rs1_data = rs1_byp_data;
assign idu_iex_rs2_data = rs2_byp_data;

//Stall vld generation
assign rs1_stall_vld = rs1_iex_stall_vld[1] | (rs1_iex_stall_vld[0] & ~rs1_iex_byp_vld[1]) | (rs1_lsu_stall_vld[1] & ~(|rs1_iex_byp_vld)) | (rs1_lsu_stall_vld[0] & ~rs1_lsu_byp_vld[1] & ~(|rs1_iex_byp_vld));
assign rs2_stall_vld = rs2_iex_stall_vld[1] | (rs2_iex_stall_vld[0] & ~rs2_iex_byp_vld[1]) | (rs2_lsu_stall_vld[1] & ~(|rs2_iex_byp_vld)) | (rs2_lsu_stall_vld[0] & ~rs2_lsu_byp_vld[1] & ~(|rs2_iex_byp_vld));

assign idu_dispatcher_stall_vld = rs1_stall_vld | rs2_stall_vld;

endmodule
