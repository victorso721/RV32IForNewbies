module u_idu_instBuffer (

	//SoC input
	input						clk,
	input						rst_n,

	//IFU control input
	input						sync_start_pulse,
	input						ifu_idu_fetch_vld,

	//IFU control output
	output						idu_ifu_instBuffer_full,

	//IDU control input
	//dispatch vld 1 2, vld 2 is masked by vld 1 in dispatcher
	//Exceptions/WFI detected, core stopping
	//bru flush
	input						dispatch_vld_0,
	input						dispatch_vld_1,
	input						dispatcher_detect_exceptions_wfi,
	input						bru_flush,

	//IDU control output
	output						instBuffer_inst_vld_0,
	output						instBuffer_inst_vld_1,

	//IFU data input
	//inst 1 2
	//pc 1 2
	//unalign pc 1 2
	input	[`INST_WIDTH-1:0]	inst_in_0,
	input	[`INST_WIDTH-1:0]	inst_in_1,
	input	[`PC_WIDTH-1:0]		pc_in_0,
	input	[`PC_WIDTH-1:0]		pc_in_1,
	input						unalign_pc_in_0,
	input						unalign_pc_in_1,

	//IDU data output
	//inst 1 2
	//pc 1 2
	//unalign pc 1 2
	output	[`INST_WIDTH-1:0]	inst_out_0,
	output	[`INST_WIDTH-1:0]	inst_out_1,
	output	[`PC_WIDTH-1:0]		pc_out_0,
	output	[`PC_WIDTH-1:0]		pc_out_1,
	output						unalign_pc_out_0,
	output						unalign_pc_out_1

);

//Internal signal
//Buffers
reg [`INST_WIDTH-1:0] instBuffer_inst_reg [`INST_BUFFER_DEPTH-1:0];
reg [`PC_WIDTH-1:0] instBuffer_pc_reg [`INST_BUFFER_DEPTH-1:0];
reg instBuffer_unalign_pc_reg [`INST_BUFFER_DEPTH-1:0];
wire instBuffer_wen;

//Buffer Read result
wire [`INST_WIDTH-1:0] instBuffer_read_inst_0;
wire [`INST_WIDTH-1:0] instBuffer_read_inst_1;
wire [`PC_WIDTH-1:0] instBuffer_read_pc_0;
wire [`PC_WIDTH-1:0] instBuffer_read_pc_1;
wire instBuffer_read_unalign_pc_0;
wire instBuffer_read_unalign_pc_1;

//Wrapped pointers: one more bit is needed as wrapper
//Read pointer
//Write pointer
reg [`INST_BUFFER_DEPTH_BIT:0] rd_ptr;
reg [`INST_BUFFER_DEPTH_BIT:0] wr_ptr;

//Pointer update:
//Read pointer next
//Write pointer next
//rd ptr update: +0/+1/+2 depends of dispatch valid result of IDU
//wr ptr nxt always + 2: fetch valid from IFU
//ptr clear: if buffer clear is enabled, do by ptr clear to 0
wire [`INST_BUFFER_DEPTH_BIT:0] rd_ptr_nxt;
wire [`INST_BUFFER_DEPTH_BIT:0] wr_ptr_nxt;
wire [`INST_BUFFER_DEPTH_BIT:0] rd_ptr_plus_one;
wire [`INST_BUFFER_DEPTH_BIT:0] wr_ptr_plus_one;

//Buffer status:
//Buffer clear
//Buffer full
//Buffer empty
//Buffer contain one entry
wire buffer_clear;
wire buffer_full;
wire buffer_empty;
wire buffer_contain_one_entry;

//Signals assignment
//Buffer status
assign buffer_clear = bru_flush | dispatcher_detect_exceptions_wfi | sync_start_pulse;
//buffer cannot overflow, hence can by maximum possible write inst amount
//How to define buffer full? Redefine is needed everytime archi is modified
//1.rd_ptr == wr_ptr		: all entry is currently used up
//2.rd_ptr == wr_ptr + 1	: only one entry is free, but IFU double fetch, so buffer full
//3.rd_ptr == wr_ptr + 2	: two entry is free, buffer not full
//Pointer range detecction is used here, condition is too strong and area inefficient for this case, but worthy for the case in larger pointer movements
assign buffer_full = (rd_ptr[`INST_BUFFER_DEPTH_BIT] != wr_ptr_plus_one[`INST_BUFFER_DEPTH_BIT]) && (rd_ptr[`INST_BUFFER_DEPTH_BIT-1:0] <= wr_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]);
assign buffer_empty = (rd_ptr == wr_ptr);
assign buffer_contain_one_entry = (rd_ptr_plus_one == wr_ptr);

//pointer increment
assign rd_ptr_plus_one = rd_ptr + 'd1;
assign wr_ptr_plus_one = wr_ptr + 'd1;

//pointer update
assign rd_ptr_nxt = (buffer_clear)? 'b0 : (rd_ptr + dispatch_vld_0 + dispatch_vld_1);
assign wr_ptr_nxt = (buffer_clear)? 'b0 : (wr_ptr + {ifu_idu_fetch_vld,1'b0});

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_ptr <= 'b0;
		wr_ptr <= 'b0;
	end
	else begin
		rd_ptr <= rd_ptr_nxt;
		wr_ptr <= wr_ptr_nxt;
	end
end

//buffer write
assign instBuffer_wen = ifu_idu_fetch_vld;
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(int i=0; i<`INST_BUFFER_DEPTH; i++) begin
			instBuffer_inst_reg[i] <= 'b0;
			instBuffer_pc_reg[i] <= 'b0;
			instBuffer_unalign_pc_reg[i] <= 'b0;
		end
	end
	else if(instBuffer_wen) begin
		instBuffer_inst_reg[wr_ptr[`INST_BUFFER_DEPTH_BIT-1:0]] <= inst_in_0;
		instBuffer_inst_reg[wr_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]] <= inst_in_1;
		instBuffer_pc_reg[wr_ptr[`INST_BUFFER_DEPTH_BIT-1:0]] <= pc_in_0;
		instBuffer_pc_reg[wr_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]] <= pc_in_1;
		instBuffer_unalign_pc_reg[wr_ptr[`INST_BUFFER_DEPTH_BIT-1:0]] <= unalign_pc_in_0;
		instBuffer_unalign_pc_reg[wr_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]] <= unalign_pc_in_1;
	end
end

//buffer read
//buffer empty: bypass path 1 2
//buffer one entry, bypass path 1, read 1 from buffer
//buffer two entry or more: read 2 from buffer
assign instBuffer_read_inst_0 = instBuffer_inst_reg[rd_ptr[`INST_BUFFER_DEPTH_BIT-1:0]];
assign instBuffer_read_inst_1 = instBuffer_inst_reg[rd_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]];
assign instBuffer_read_pc_0 = instBuffer_pc_reg[rd_ptr[`INST_BUFFER_DEPTH_BIT-1:0]];
assign instBuffer_read_pc_1 = instBuffer_pc_reg[rd_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]];
assign instBuffer_read_unalign_pc_0 = instBuffer_unalign_pc_reg[rd_ptr[`INST_BUFFER_DEPTH_BIT-1:0]];
assign instBuffer_read_unalign_pc_1 = instBuffer_unalign_pc_reg[rd_ptr_plus_one[`INST_BUFFER_DEPTH_BIT-1:0]];

//Data output without bypass path
assign inst_out_0 		= instBuffer_read_inst_0;
assign inst_out_1 		= instBuffer_read_inst_1;
assign pc_out_0 		= instBuffer_read_pc_0;
assign pc_out_1 		= instBuffer_read_pc_1;
assign unalign_pc_out_0	= instBuffer_read_unalign_pc_0;
assign unalign_pc_out_1	= instBuffer_read_unalign_pc_1;

//Control output: instruction reading valid without bypass path
assign instBuffer_inst_vld_0 = !buffer_empty;
assign instBuffer_inst_vld_1 = !(buffer_contain_one_entry | buffer_empty);

/* Feature dropped as no more register between IFU and instruction buffer, as this project do not consider timing closure
//If timing failure occurs and register is added between IFU and instruction buffer, feature reactivate
//Data output with Bypass path
assign inst_out_0 = (buffer_empty)? inst_in_0 : instBuffer_read_inst_0;
assign inst_out_1 = (buffer_empty)? inst_in_1 : ((buffer_contain_one_entry)? inst_in_0 : instBuffer_read_inst_1);
assign pc_out_0 = (buffer_empty)? pc_in_0 : instBuffer_read_pc_0;
assign pc_out_1 = (buffer_empty)? pc_in_1 : ((buffer_contain_one_entry)? pc_in_0 : instBuffer_read_pc_1);
assign unalign_pc_out_0 = (buffer_empty)? unalign_pc_in_0 : instBuffer_read_unalign_pc_0;
assign unalign_pc_out_1 = (buffer_empty)? unalign_pc_in_1 : ((buffer_contain_one_entry)? unalign_pc_in_0 : instBuffer_read_unalign_pc_1);

//Control output: instruction reading valid with bypass path
//BRU flush will mask inst valid before passing to ALU due to timing concern
assign instBuffer_inst_vld_0 = !buffer_empty | ifu_idu_fetch_vld;
assign instBuffer_inst_vld_1 = !(buffer_contain_one_entry | buffer_empty) | ifu_idu_fetch_vld;
*/

//Control output: Instruction buffer full
assign idu_ifu_instBuffer_full = buffer_full;

endmodule
