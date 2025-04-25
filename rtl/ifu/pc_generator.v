//PC generator
//1.To generate and select the pc prediction result
//2.Detect pc unalignment

//Dynamic prediction
//-------Not supported in this project---------//

//Static prediction
//Always not taken: pc + 8 (for superscalar: double fetch 32-bit instruction)

//PC selector assumption: start pulse always has higher priority

module u_ifu_pc_generator (
	//Control input
	input						start_pulse,
	input 						bru_flush,
	//Data input
	input [`PC_WIDTH-1:0]		start_pc,
	input [`PC_WIDTH-1:0]		bru_redir_pc,
	input [`PC_WIDTH-1:0]		arb_res_pc,
	//Control output
	output						is_pc_unalign,
	//Data output
	output [`PC_WIDTH-1:0]		arb_res_pc_q
);

reg  [`PC_WIDTH-1:0]	arb_res_pc_q_comb;
wire [1:0] pc_select;
assign pc_select = {start_pulse, ~start_pulse & bru_flush}; //Case 2'b11 is blocked
assign arb_res_pc_q = arb_res_pc_q_comb;
always @(*) begin
	case(pc_select)
		2'b00: arb_res_pc_q_comb <= arb_res_pc + 'd8;	//Current static prediction: always not taken
		2'b01: arb_res_pc_q_comb <= bru_redir_pc;
		2'b10: arb_res_pc_q_comb <= start_pc;
		default: arb_res_pc_q_comb <= arb_res_pc + 'd8; //deadcode: Full case mux
	endcase
end

//PC unalignment detecting
assign is_pc_unalign = |arb_res_pc[1:0];	//remark: Have to change if instruction memory length is not 32 bit = 4 byte

endmodule
