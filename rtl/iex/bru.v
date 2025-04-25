
module u_bru (

	//pc input
	input [`DATA_WIDTH-1:0] bru_redir_pc_in,

	//instruction control flag
	input jump,
	input blt,
	input bge,
	input beq,	//|(rs1 XNOR rs2) == 1
	input bne,	//|(rs1 XOR rs2) == 1

	//result control flag
	input [`DATA_WIDTH-1:0] slt_result,
	input [`DATA_WIDTH-1:0] xor_result, 

	//pc output
	output bru_output_vld,
	output bru_flush,
	output [`PC_WIDTH-1:0] bru_redir_pc
	
);
wire xor_result_bit;
wire slt_result_bit;
assign xor_result_bit = |xor_result;
assign slt_result_bit = slt_result[0];
assign bru_redir_pc = bru_redir_pc_in;
assign bru_flush = (jump) | (beq & !xor_result_bit) | (bne & xor_result_bit) | (blt & slt_result_bit) | (bge & !slt_result_bit);
assign bru_output_vld = blt | bge | beq | bne | jump;

endmodule
