//Core Status Register

module u_csr (
	//SoC input
	input 						clk,
	input 						rst_n,

	//IFU input
	input 						sync_start_pulse,
	input [`EXCEPTION_NUM-1:0] 	sync_core_configuration,

	//ALU input
	input 						iex_csr_wfi_vld,
	input						iex_csr_exception_vld,
	input [`EXCEPTION_NUM-1:0] 	iex_csr_exceptions,
	input [`PC_WIDTH-1:0]		iex_csr_exception_pc,

	//SoC output
	output [1:0] 				core_status,
	output [`EXCEPTION_NUM-1:0] core_configuration,
	output [`EXCEPTION_NUM-1:0] core_exceptions,
	output [`PC_WIDTH-1:0]		core_exceptions_pc
);

//Internal signal
reg [1:0] 					csr_core_status;
reg [`EXCEPTION_NUM-1:0] 	csr_core_configuration;
reg [`EXCEPTION_NUM-1:0] 	csr_core_exceptions;
reg [`PC_WIDTH-1:0]			csr_core_exceptions_pc;

assign core_status 			= csr_core_status;
assign core_configuration 	= csr_core_configuration;
assign core_exceptions		= csr_core_exceptions;
assign core_exceptions_pc	= csr_core_exceptions_pc;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		csr_core_status	<= 'b0;
	end
	else if(sync_start_pulse) begin
		csr_core_status	<= 2'b01;
	end
	else if(iex_csr_wfi_vld | iex_csr_exception_vld) begin
		csr_core_status[0] <= 1'b0;
		csr_core_status[1] <= iex_csr_wfi_vld & ~iex_csr_exception_vld;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		csr_core_configuration	<= 'b0;
	end
	else if(sync_start_pulse) begin
		csr_core_configuration	<= sync_core_configuration;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n | sync_start_pulse) begin
		csr_core_exceptions		<= 'b0;
	end
	else if(iex_csr_exception_vld) begin
		csr_core_exceptions		<= iex_csr_exceptions;
	end
end

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n | sync_start_pulse) begin
		csr_core_exceptions_pc	<= 'b0;
	end
	else if(iex_csr_exception_vld) begin
		csr_core_exceptions_pc	<= iex_csr_exception_pc;
	end
end

endmodule
