//This comparator only operate comparsion data_in_1 < data_in_2
module u_alu_comparator (

	//data input
	input [`DATA_WIDTH-1:0] comp_data_in_1,
	input [`DATA_WIDTH-1:0] comp_data_in_2,

	//control flag
	input unsigned_comp,

	//data output
	output [`DATA_WIDTH-1:0] comp_data_out
	
);

//Internal signal
wire unsigned_comp_result;
wire signed_comp_result;
//Verilog default unsigned data type, signed data need to handle before using 
//Warning: SystemVerilog default differently, always use macro to cast type in reference model
assign signed_comp_result = ($signed(comp_data_in_1) < $signed(comp_data_in_2));
assign unsigned_comp_result = (comp_data_in_1 < comp_data_in_2);

assign comp_data_out[0] = (unsigned_comp)? unsigned_comp_result : signed_comp_result; 
assign comp_data_out[`DATA_WIDTH-1:1] = 'b0;

endmodule
