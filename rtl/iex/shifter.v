
module u_alu_shifter (

	//data input
	input [`DATA_WIDTH-1:0] shifter_data_in_1,
	input [`DATA_WIDTH_BIT_NUM-1:0] shifter_data_in_2,

	//control flag
	input right_shift,
	input logical_shift,

	//data output
	output [`DATA_WIDTH-1:0] shifter_data_out,
	
	//vld output
	output shifter_output_vld
	
);

//Internal signal
wire [`DATA_WIDTH-1:0] left_shift_result;	//left arithmetic shift do not exist
wire [`DATA_WIDTH-1:0] right_shift_result;
wire [`DATA_WIDTH-1:0] right_logical_shift_result;
wire [`DATA_WIDTH-1:0] right_arithmetic_shift_result;

assign left_shift_result = shifter_data_in_1 << shifter_data_in_2;
assign right_arithmetic_shift_result = $signed(shifter_data_in_1) >>> shifter_data_in_2;
assign right_logical_shift_result = shifter_data_in_1 >> shifter_data_in_2;


assign right_shift_result = (logical_shift)? right_logical_shift_result : right_arithmetic_shift_result;
assign shifter_data_out = (right_shift)? right_shift_result : left_shift_result;

assign shifter_output_vld = right_shift | logical_shift;	//if right shift=0 & logical_shift=0, it is invalid as left arithmetic shift not exist

endmodule
