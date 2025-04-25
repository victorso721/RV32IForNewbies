
module u_alu_adder (

	//data input
	input [`DATA_WIDTH-1:0] adder_data_in_1,
	input [`DATA_WIDTH-1:0] adder_data_in_2,

	//control flag
	input sub,

	//data output
	output [`DATA_WIDTH-1:0] adder_data_out
	
);

//Internal signal
wire [`DATA_WIDTH-1:0] first_comp;
assign first_comp = adder_data_in_2 ^ {32{sub}}; //1's comp.
assign adder_data_out = adder_data_in_1 + first_comp + sub; //2's comp if sub=1

//Exception: overflow handling
//assign overflow_add	=	add_result[32];	//modifiy add_result to 33-bit
//assign overflow_sub	=	...;
//assign overflow	=	(sub)? overflow_sub : overflow_add;
endmodule
