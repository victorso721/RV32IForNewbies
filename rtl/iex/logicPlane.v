
module u_alu_logic_plane (

	//data input
	input [`DATA_WIDTH-1:0] logic_plane_data_in_1,
	input [`DATA_WIDTH-1:0] logic_plane_data_in_2,

	//control flag
	input and_flag,
	input or_flag,
	input xor_flag,

	//data output
	output [`DATA_WIDTH-1:0] logic_plane_data_out,
	
	//vld output
	output logic_plane_output_vld
	
);

//Internal signal
wire [`DATA_WIDTH-1:0] and_result;
wire [`DATA_WIDTH-1:0] or_result;
wire [`DATA_WIDTH-1:0] xor_result;

assign and_result = logic_plane_data_in_1 & logic_plane_data_in_2;
assign or_result = logic_plane_data_in_1 | logic_plane_data_in_2;
assign xor_result = logic_plane_data_in_1 ^ logic_plane_data_in_2;

assign logic_plane_data_out = (and_result & {32{and_flag}}) | (or_result & {32{or_flag}}) | (xor_result & {32{xor_flag}});

assign logic_plane_output_vld = and_flag | or_flag | xor_flag;

endmodule
