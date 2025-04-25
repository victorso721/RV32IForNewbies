//synchronizer
//to synchronize the signal in different clock domain
//2 flip flop synchronizer is used in this project
//3 edges assumption: CPU clock is atleast 1.5 times faster than SoC clock to guarntee signal is captured
//Question: why not 1 flip flop?
//Answer: consider possible meta-stable state, mean time between failure of 2 flip-flop sync is lagre enough
//Some higher failure requirement IC will use 3 or more flip flop synchronizer
//Question: what if 3 edges assumption does not hold?
//Answer: More complex design is needed, e.g. hand-shaking mechanism 

module u_ifu_2ff_synchronizer (
	//SOC input
	input clk,
	input rst_n,
	input start_pulse,
	input [`PC_WIDTH-1:0] start_pc,
	input [`EXCEPTION_NUM-1:0] core_configuration,
	
	//IFU output
	output sync_start_pulse,
	output [`PC_WIDTH-1:0] sync_start_pc,
	output [`EXCEPTION_NUM-1:0] sync_core_configuration
);

//Internal signal
reg start_pulse_ff;
reg sync_start_pulse_reg;
reg [`PC_WIDTH-1:0] start_pc_ff;
reg [`PC_WIDTH-1:0] sync_start_pc_reg;
reg [`EXCEPTION_NUM-1:0] core_configuration_ff;
reg [`EXCEPTION_NUM-1:0] sync_core_configuration_reg;

assign sync_start_pulse			= sync_start_pulse_reg;
assign sync_start_pc			= sync_start_pc_reg;
assign sync_core_configuration	= sync_core_configuration_reg;

always @(posedge clk) begin
	if(~rst_n) begin
		start_pulse_ff <= 0;
		start_pc_ff <= 'b0;
		core_configuration_ff <= 'b0;
		sync_start_pulse_reg <= 0;
		sync_start_pc_reg <= 'b0;
		sync_core_configuration_reg <= 'b0;
	end
	else begin
		start_pulse_ff <= start_pulse & ~start_pulse_ff;	//Only sensitive to the first cycle
		start_pc_ff <= start_pc;
		core_configuration_ff <= core_configuration;
		sync_start_pulse_reg <= start_pulse_ff;
		sync_start_pc_reg <= start_pc_ff;
		sync_core_configuration_reg <= core_configuration_ff;
	end
end

endmodule
