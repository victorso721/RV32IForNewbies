//This module act as wrapper of non-clock calculation units
module u_alu (
	
	//IDU input
	//Data
	input	[`PC_WIDTH-1:0]		iex_alu_pc,			//for AUIPC/BRANCH/JUMP
	input	[`DATA_WIDTH-1:0]	iex_alu_rs1_data,
	input	[`DATA_WIDTH-1:0]	iex_alu_rs2_data,
	input	[`DATA_WIDTH-1:0]	iex_alu_imm_data,
	//Control flags
	input						iex_alu_pipe_vld,
	input						iex_alu_flag_adder_sel_src1_pc,
	input						iex_alu_flag_adder_sel_src2_rs2,
	input						iex_alu_flag_general_sel_src2_rs2,
	input						iex_alu_flag_unsigned_data,
	//Adder
	input						iex_alu_flag_adder_vld,
	input						iex_alu_flag_adder_sub,
	//Comparator
	input						iex_alu_flag_comparator_vld,
	//Logical plane
	input						iex_alu_flag_logical_plane_and,
	input						iex_alu_flag_logical_plane_or,
	input						iex_alu_flag_logical_plane_xor,
	//Shifter
	input						iex_alu_flag_shifter_right_shift,
	input						iex_alu_flag_shifter_logical_shift,
	//BRU
	input						iex_alu_flag_bru_jal,
	input						iex_alu_flag_bru_jalr,
	input						iex_alu_flag_bru_bge,
	input						iex_alu_flag_bru_blt,
	input						iex_alu_flag_bru_beq,
	input						iex_alu_flag_bru_bne,

	//BRU output
	output						alu_iex_bru_vld,
	output						alu_iex_bru_flush,
	output	[`PC_WIDTH-1:0]		alu_iex_bru_redir_pc,

	//ALU calculation output
	output	[`DATA_WIDTH-1:0]	alu_iex_cal_data

);

//Internal signal
//arithmetic logic
wire	[`DATA_WIDTH-1:0]	alu_output_result;
wire	[`DATA_WIDTH-1:0]	adder_result;
wire	[`DATA_WIDTH-1:0]	comparator_result;
wire	[`DATA_WIDTH-1:0]	logic_plane_result;
wire	[`DATA_WIDTH-1:0]	shifter_result;
wire	[`DATA_WIDTH-1:0]	return_address;
wire	[`DATA_WIDTH-1:0]	adder_data_in_1;
wire	[`DATA_WIDTH-1:0]	adder_data_in_2;
wire	[`DATA_WIDTH-1:0]	non_adder_data_in_1;
wire	[`DATA_WIDTH-1:0]	non_adder_data_in_2;
wire 						adder_result_vld;
wire 						comparator_result_vld;
wire						logic_plane_result_vld;
wire						shifter_result_vld;
//bru
wire				jump;
wire 						bru_vld;
wire 						bru_flush;
wire	[`DATA_WIDTH-1:0]	bru_pc_in;
wire	[`DATA_WIDTH-1:0]	bru_redir_pc;

assign	adder_result_vld		=	iex_alu_flag_adder_vld;	//adder control flag has no spare space to indicate result not selected, pass from IDU
assign	comparator_result_vld	=	iex_alu_flag_comparator_vld; //comparator control flag has no spare space to indicate result not selected, pass from IDU

//adder data 1 selection mux
assign	adder_data_in_1			=	(iex_alu_flag_adder_sel_src1_pc)? iex_alu_pc : iex_alu_rs1_data;

//adder data 2 selection mux
assign	adder_data_in_2			=	(iex_alu_flag_adder_sel_src2_rs2)? iex_alu_rs2_data : iex_alu_imm_data;

//non adder module data 1 selection mux
assign	non_adder_data_in_1		=	iex_alu_rs1_data;
assign	non_adder_data_in_2		=	(iex_alu_flag_general_sel_src2_rs2)? iex_alu_rs2_data : iex_alu_imm_data;

//ALU result selection mux
assign	alu_output_result		=	{`DATA_WIDTH{jump}} & return_address |{`DATA_WIDTH{logic_plane_result_vld}} & logic_plane_result | {`DATA_WIDTH{adder_result_vld}} & adder_result | {`DATA_WIDTH{comparator_result_vld}} & comparator_result | {`DATA_WIDTH{shifter_result_vld}} & shifter_result;

//return address calculation
assign	return_address			=	iex_alu_pc + 'd4;

//BRU
assign jump = iex_alu_flag_bru_jal | iex_alu_flag_bru_jalr;
assign bru_pc_in = {adder_result[31:1],adder_result[0] & ~iex_alu_flag_bru_jalr};

//Adder mux
//data in 1
//data in 2
//data out
//sub flag
//external result mux control: adder vld
u_alu_adder alu_adder(
	.adder_data_in_1 	(adder_data_in_1),
	.adder_data_in_2 	(adder_data_in_2),
	.sub 				(iex_alu_flag_adder_sub),
	.adder_data_out 	(adder_result)
);

//Comparator mux
//data in 1
//data in 2
//data out: matched with rf length, bit 0 stores the result of comparsion
//unsigned flag
//external result mux control: comparator vld
u_alu_comparator alu_comparator(
	.comp_data_in_1 	(non_adder_data_in_1),
	.comp_data_in_2		(non_adder_data_in_2),
	.unsigned_comp		(iex_alu_flag_unsigned_data),
	.comp_data_out		(comparator_result)
);

//Logical plane
//data in 1
//data in 2
//data out
//and flag
//or flag
//xor flag
//vld out
u_alu_logic_plane alu_logic_plane (
	.logic_plane_data_in_1	(non_adder_data_in_1),
	.logic_plane_data_in_2	(non_adder_data_in_2),
	.and_flag				(iex_alu_flag_logical_plane_and),
	.or_flag				(iex_alu_flag_logical_plane_or),
	.xor_flag				(iex_alu_flag_logical_plane_xor),
	.logic_plane_data_out	(logic_plane_result),
	.logic_plane_output_vld	(logic_plane_result_vld)
	
);

//Shifter
//data in 1
//data in 2, only lowest log_2(`DATA_WIDTH) bit is used, i.e.[log_2(`DATA_WIDTH-1):0]
//left shift/right shift
//logical shift / arithmetic shift
//data out 
//data out vld
u_alu_shifter alu_shifter(
	.shifter_data_in_1	(non_adder_data_in_1),
	.shifter_data_in_2	(non_adder_data_in_2[`DATA_WIDTH_BIT_NUM-1:0]),
	.right_shift		(iex_alu_flag_shifter_right_shift),
	.logical_shift		(iex_alu_flag_shifter_logical_shift),
	.shifter_data_out	(shifter_result),
	.shifter_output_vld	(shifter_result_vld)
);

//BRU
//redirect pc input			:	adder calculation result
//instruction control flag	:	to select comparsion result
//result control flag		:	comparsion result
//BRU result valid			:	branch/jump instruction is handling
//BRU flush
//BRU redir pc

u_bru bru(
	.bru_redir_pc_in 	(bru_pc_in),
	.jump				(jump),
	.blt				(iex_alu_flag_bru_blt),
	.bge				(iex_alu_flag_bru_bge),
	.beq				(iex_alu_flag_bru_beq),
	.bne				(iex_alu_flag_bru_bne),
	.slt_result			(comparator_result),
	.xor_result			(logic_plane_result),
	.bru_output_vld		(bru_vld),
	.bru_flush			(bru_flush),
	.bru_redir_pc		(bru_redir_pc)
);

//Interface assignment
assign	alu_iex_bru_vld			=	iex_alu_pipe_vld & bru_vld;
assign	alu_iex_bru_flush		=	bru_flush;
assign	alu_iex_bru_redir_pc	=	bru_redir_pc;
assign	alu_iex_cal_data		=	alu_output_result;

endmodule
