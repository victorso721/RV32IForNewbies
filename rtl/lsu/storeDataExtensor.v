
module u_lsu_store_data_extensor (

	//control flag
	input sb,
	input sh,
	input sw,
	//address
	input [`DATA_MEM_WIDTH_BIT-1:0] addr,
	//original data from Dmem
	input [`DATA_WIDTH-1:0] wr_data,
	//selecteddata output
	output [`DATA_MEM_WIDTH-1:0] extended_wr_data,
	output [`DATA_MEM_WIDTH-1:0] extended_wen
	
);

//Internal signal
wire [`DATA_MEM_WIDTH-1:0] sb_wr_data;
wire [`DATA_MEM_WIDTH-1:0] sh_wr_data;
wire [`DATA_MEM_WIDTH-1:0] sw_wr_data;
reg [`DATA_MEM_WIDTH-1:0] sb_wr_en;
reg [`DATA_MEM_WIDTH-1:0] sh_wr_en;
reg [`DATA_MEM_WIDTH-1:0] sw_wr_en;
wire sw_en_bit;
wire sh_en_bit;
wire sb_en_bit;
wire [1:0] sw_addr;
wire [2:0] sh_addr;
wire [3:0] sb_addr;

//pipe valid is considered in IEX
assign sw_en_bit = sw ;
assign sb_en_bit = sb ;
assign sh_en_bit = sh ;

//Upper bound depends on `DATA_MEM_WIDTH, 
//due to hardware accelerated MUX do not support dynamic number of case, hard wire is used here
//possible alternative: use for loop and replace 'd0/1/2... into 'd(i) 
assign sw_addr = addr[3:2];	
assign sh_addr = addr[3:1];	
assign sb_addr = addr[3:0];	

//SW MUX using addr
always @ (*) begin
	case(sw_addr)
		'd0: sw_wr_en = {96'd0,{32{sw_en_bit}}};
		'd1: sw_wr_en = {64'd0,{32{sw_en_bit}},32'd0};
		'd2: sw_wr_en = {32'd0,{32{sw_en_bit}},64'd0};
		'd3: sw_wr_en = {{32{sw_en_bit}},96'd0};
	endcase
end
assign sw_wr_data = {4{wr_data}};

//SH MUX using addr
always @ (*) begin
	case(sh_addr)
		'd0: sh_wr_en = {112'd0,{16{sh_en_bit}}};
		'd1: sh_wr_en = {96'd0,{16{sh_en_bit}},16'd0};
		'd2: sh_wr_en = {80'd0,{16{sh_en_bit}},32'd0};
		'd3: sh_wr_en = {64'd0,{16{sh_en_bit}},48'd0};
		'd4: sh_wr_en = {48'd0,{16{sh_en_bit}},64'd0};
		'd5: sh_wr_en = {32'd0,{16{sh_en_bit}},80'd0};
		'd6: sh_wr_en = {16'd0,{16{sh_en_bit}},96'd0};
		'd7: sh_wr_en = {{16{sh_en_bit}},112'd0};
	endcase
end
assign sh_wr_data = {8{wr_data[15:0]}};

//SB MUX using addr
always @ (*) begin
	case(sb_addr)
		'd0: sb_wr_en = {120'd0,{8{sb_en_bit}}};
		'd1: sb_wr_en = {112'd0,{8{sb_en_bit}},8'd0};
		'd2: sb_wr_en = {104'd0,{8{sb_en_bit}},16'd0};
		'd3: sb_wr_en = {96'd0,{8{sb_en_bit}},24'd0};
		'd4: sb_wr_en = {88'd0,{8{sb_en_bit}},32'd0};
		'd5: sb_wr_en = {80'd0,{8{sb_en_bit}},40'd0};
		'd6: sb_wr_en = {72'd0,{8{sb_en_bit}},48'd0};
		'd7: sb_wr_en = {64'd0,{8{sb_en_bit}},56'd0};
		'd8: sb_wr_en = {56'd0,{8{sb_en_bit}},64'd0};
		'd9: sb_wr_en = {48'd0,{8{sb_en_bit}},72'd0};
		'd10: sb_wr_en = {40'd0,{8{sb_en_bit}},80'd0};
		'd11: sb_wr_en = {32'd0,{8{sb_en_bit}},88'd0};
		'd12: sb_wr_en = {24'd0,{8{sb_en_bit}},96'd0};
		'd13: sb_wr_en = {16'd0,{8{sb_en_bit}},104'd0};
		'd14: sb_wr_en = {8'd0,{8{sb_en_bit}},112'd0};
		'd15: sb_wr_en = {{8{sb_en_bit}},120'd0};
	endcase
end

assign sb_wr_data = {16{wr_data[7:0]}};

//Output MUX
assign extended_wr_data = {{`DATA_MEM_WIDTH{sw}} & sw_wr_data} | {{`DATA_MEM_WIDTH{sh}} & sh_wr_data} | {{`DATA_MEM_WIDTH{sb}} & sb_wr_data};
assign extended_wen = sw_wr_en | sh_wr_en | sb_wr_en;

endmodule
