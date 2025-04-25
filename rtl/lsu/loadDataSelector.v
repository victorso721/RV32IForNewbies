
module u_lsu_load_data_selector (

	//control flag
	input lb,
	input lh,
	input lw,
	input unsigned_data,
	//address
	input [`DATA_MEM_WIDTH_BIT-1:0] addr,
	//original data from Dmem
	input [`DATA_MEM_WIDTH-1:0] rd_data,
	//selecteddata output
	output [`DATA_WIDTH-1:0] selected_dmem_data
	
);

//Internal signal
reg [7:0] byte_selected_data;
reg [15:0] half_word_selected_data;
reg [31:0] word_selected_data; 
wire [31:0] lb_data;
wire [31:0] lh_data;
wire [31:0] lw_data;
wire [1:0] lw_addr;
wire [2:0] lh_addr;
wire [3:0] lb_addr;

//Upper bound depends on `DATA_MEM_WIDTH, 
//due to hardware accelerated MUX do not support dynamic number of case, hard wire is used here 
assign lw_addr = addr[3:2];
assign lh_addr = addr[3:1];
assign lb_addr = addr[3:0];

//LW MUX using addr
always @(*) begin
	case(lw_addr)
		'd0: word_selected_data <= rd_data[31:0];
		'd1: word_selected_data <= rd_data[63:32];
		'd2: word_selected_data <= rd_data[95:64];
		'd3: word_selected_data <= rd_data[127:96];
	endcase
end

//LH MUX using addr
always @(*) begin
	case(lh_addr)
		'd0: half_word_selected_data <= rd_data[15:0];
		'd1: half_word_selected_data <= rd_data[31:16];
		'd2: half_word_selected_data <= rd_data[47:32];
		'd3: half_word_selected_data <= rd_data[63:48];
		'd4: half_word_selected_data <= rd_data[79:64];
		'd5: half_word_selected_data <= rd_data[95:80];
		'd6: half_word_selected_data <= rd_data[111:96];
		'd7: half_word_selected_data <= rd_data[127:112];
	endcase
end

//LB MUX using addr
always @(*) begin
	case(lb_addr)
		'd0: byte_selected_data <= rd_data[7:0];
		'd1: byte_selected_data <= rd_data[15:8];
		'd2: byte_selected_data <= rd_data[23:16];
		'd3: byte_selected_data <= rd_data[31:24];
		'd4: byte_selected_data <= rd_data[39:32];
		'd5: byte_selected_data <= rd_data[47:40];
		'd6: byte_selected_data <= rd_data[55:48];
		'd7: byte_selected_data <= rd_data[63:56];
		'd8: byte_selected_data <= rd_data[71:64];
		'd9: byte_selected_data <= rd_data[79:72];
		'd10: byte_selected_data <= rd_data[87:80];
		'd11: byte_selected_data <= rd_data[95:88];
		'd12: byte_selected_data <= rd_data[103:96];
		'd13: byte_selected_data <= rd_data[111:104];
		'd14: byte_selected_data <= rd_data[119:112];
		'd15: byte_selected_data <= rd_data[127:120];
	endcase
end

//Unsigned/signed instruction handling
assign lh_data = {{16{!unsigned_data & half_word_selected_data[15]}}, half_word_selected_data};
assign lb_data = {{24{!unsigned_data & byte_selected_data[7]}}, byte_selected_data};
assign lw_data = word_selected_data;
//Output MUX
assign selected_dmem_data = {{32{lw}} & lw_data} | {{32{lh}} & lh_data} | {{32{lb}} & lb_data};

endmodule
