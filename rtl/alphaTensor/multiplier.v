//special arrangment on starting index for 2D array: start from 1 for eaiser counting
module u_multiplier(
	//SOC input
	input clk,
	input rst_n,

	//preadder input
	input mul_vld_in,
	input [`MATRIX_MEM_DEPTH_BIT-1:0] rd_in,
	input [`MATRIX_MEM_DATA_LENGTH-1:0] mul_data_in_lhs [`MULITIPLICATION_NUM:1],
	input [`MATRIX_MEM_DATA_LENGTH-1:0] mul_data_in_rhs [`MULITIPLICATION_NUM:1],

	//postadder output
	output mul_vld_out,
	output [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out,
	output [`MATRIX_MEM_DATA_LENGTH-1:0] mul_data_out [`MULITIPLICATION_NUM:1]	//h1 to h47

);

//internal signal
reg [`MATRIX_MEM_DATA_LENGTH_BIT:0] cnt;
wire [`MATRIX_MEM_DATA_LENGTH_BIT:0] cnt_nxt;
wire mul_start;
wire mul_running;
wire mul_complete;

reg [`MATRIX_MEM_DATA_LENGTH-1:0] lhs [`MULITIPLICATION_NUM:1];
reg [`MATRIX_MEM_DATA_LENGTH-1:0] rhs [`MULITIPLICATION_NUM:1];
reg [`MATRIX_MEM_DATA_LENGTH-1:0] acc [`MULITIPLICATION_NUM:1];
reg [`MATRIX_MEM_DATA_LENGTH-1:0] mul_data_out_reg [`MULITIPLICATION_NUM:1];

reg [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out_temp;
reg [`MATRIX_MEM_DEPTH_BIT-1:0] rd_out_reg;

reg mul_vld_out_reg;

//Cycle Counter
assign cnt_nxt = (cnt == `MATRIX_MEM_DATA_HALF_LENGTH)? 'b0 : cnt + 1'b1;
assign mul_start = mul_vld_in;
assign mul_running = (cnt != 0);
assign mul_complete = (cnt == `MATRIX_MEM_DATA_HALF_LENGTH);
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 'b0;
	end
	else if(mul_start | mul_running) begin
		cnt <= cnt_nxt;
	end
end

//Matrix element multiplying
//Operation: shift-add multiplying
//output result writing: write enable = rhs[0], write data <= write data + lhs
//next cycle: lhs << 1, rhs >> 1 (shift-add start from LSB of rhs to MSB of rhs)
//start condition: mul_vld_in == 1, set counter running
//running condition: 0 < counting < `MATRIX_MEM_DATA_LENGTH
//stop condition: counter == `MATRIX_MEM_DATA_LENGTH, set output vld 1, reset counter to 0 in next cycle

for(genvar i=1; i<=`MULITIPLICATION_NUM; i++) begin
	always @ (posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			lhs[i] <= 'b0;
			rhs[i] <= 'b0;
			acc[i] <= 'b0;
		end
		else if(mul_start) begin
			lhs[i] <= mul_data_in_lhs[i] << 1;
			rhs[i] <= mul_data_in_rhs[i] >> 1;
			acc[i] <= (mul_data_in_rhs[i][0])? mul_data_in_lhs[i] : 'b0;
		end
		else if(mul_running & ~mul_complete) begin	//condition: start running | in running
			lhs[i] <= lhs[i] << 1; //lhs left-shift by 1 bit
			rhs[i] <= rhs[i] >> 1; //rhs right-logical-shift(no sign extension) by 1 bit
			//Modulo 2 addition performed by bitwise XOR 
			acc[i] <= (rhs[i][0])? (acc[i] ^ lhs[i]) : acc[i]; 
			//acc[i] <= (rhs[i][0])? (acc[i] + lhs[i]) : acc[i]; 
		end
	end
end

//Result output
assign mul_data_out = mul_data_out_reg;
for(genvar i=1; i<=`MULITIPLICATION_NUM; i++) begin
	always @ (posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			mul_data_out_reg[i] <= 'b0;
		end
		else if(mul_complete) begin
			mul_data_out_reg[i] <= acc[i];
		end
	end
end

//Stage vld passing
assign mul_vld_out = mul_vld_out_reg;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		mul_vld_out_reg <= 'b0;
	end
	else begin
		mul_vld_out_reg <= mul_complete;
	end
end

//rd passing
assign rd_out = rd_out_reg;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_out_temp <= 'b0;
	end
	else if(mul_start) begin
		rd_out_temp <= rd_in;	 
  	end
end
always @(posedge clk or negedge rst_n) begin
 	if(!rst_n) begin
		rd_out_reg <= 'b0;
	end
	else if(mul_complete) begin
		rd_out_reg <= rd_out_temp;	 
  	end
end

endmodule
