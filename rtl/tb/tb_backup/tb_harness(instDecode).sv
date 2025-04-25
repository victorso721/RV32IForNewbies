`timescale 1ns/1ps

`define HALF_CLOCK_CYCLE 10  //parameter for clock cycle
`define FULL_CLOCK_CYCLE (`HALF_CLOCK_CYCLE + `HALF_CLOCK_CYCLE)

module tb_top;
//----------------simulated input---------------//
//SoC signal
reg                         clk                 ;
reg                         rst_n               ;

//CPU input
reg                         start_pulse         ;
reg [`PC_WIDTH-1:0]         start_pc            ;
reg [`EXCEPTION_NUM-1:0]    core_configuration  ;

//Signal for submodules
//input
	//Instruction input
	reg [`INST_WIDTH-1:0] inst;

	//Decode result
	//Exception result
	wire illegal_inst;
	
	//SYSTEM instruction
	wire wfi;

	//Imm data output
	wire [`DATA_WIDTH-1:0] imm_data_out;

	//Data selection control flag within IDU
	wire inst_rs1_vld;
	wire inst_rs2_vld;
	wire inst_rd_vld;
	wire dmem_load;		//Also pass to ALU LSU for indicating LOAD instruction
	wire dmem_store;

	//Data selection control flag in ALU
	wire alu_adder_sel_src1_pc;
	wire alu_adder_sel_src2_rs2;
	wire alu_general_sel_src2_rs2;

	//Control flag for calculation module in ALU
	//General flag; whether data is treated unsigned
	wire unsigned_data;
	//Adder
	wire adder_vld;
	wire adder_sub;
	//Comparator
	wire comparator_vld;
	//logical plane
	wire logical_plane_and;
	wire logical_plane_or;
	wire logical_plane_xor;
	//Shifter
	wire shifter_right_shift;
	wire shifter_logical_shift;
	//BRU
	wire bru_jal;
	wire bru_jalr;
	wire bru_bge;
	wire bru_blt;
	wire bru_beq;
	wire bru_bne;

	//Memory access flag
	wire lsu_sel_lb;
	wire lsu_sel_lh;
	wire lsu_sel_lw;
	wire lsu_sel_sw;
	wire lsu_sel_sb;
	wire lsu_sel_sh;

	//Control flag for RF
	wire rf_wen;

	//Extended rs1; rs2; rd for accelerator
	`ifdef ALPHATENSOR
		wire [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rs1_idx;
		wire [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rs2_idx;
		wire [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rd_idx;
		//inst vld for matrix multiplication
		wire matrix_mul_vld;
	`endif

	//RS1;RS2 wire; for RF
	wire [`RF_DEPTH_BIT-1:0] rf_rs1_idx;
	wire [`RF_DEPTH_BIT-1:0] rf_rs2_idx;

	//RD
	wire [`RF_DEPTH_BIT-1:0] rf_rd_idx;

//IMEM driver
wire [`INST_WIDTH-1:0] inst_sequence [`INST_MEM_DEPTH-1:0];
wire [19:0] u_type_imm;
wire [19:0] j_type_imm;	//inst[21] = 1 will call unalign pc
wire [11:0] i_type_imm;
wire [12:1] b_type_imm;	//inst[8] = 1 will call unalign pc
wire [11:0] s_type_imm;
assign u_type_imm = 'hFF24;
assign j_type_imm = 'hAE86;
assign i_type_imm = 'hEE;
assign b_type_imm = 'h149;
assign s_type_imm = 'h485;
assign inst_sequence[0] = {u_type_imm,5'd0,`LUI_OPCODE};	//LUI 
assign inst_sequence[1] = {u_type_imm,5'd1,`AUIPC_OPCODE};	//AUIPC
assign inst_sequence[2] = {j_type_imm,5'd2,`JAL_OPCODE};	//JAL
assign inst_sequence[3] = {i_type_imm,5'd9,`JALR_FUNCT3,5'd3,`JALR_OPCODE}; //JALR
assign inst_sequence[4] = {i_type_imm,5'd9,3'b111,5'd4,`JALR_OPCODE}; //JALR ILLEGAL
assign inst_sequence[5] = 32'b0;
assign inst_sequence[6] = {b_type_imm[12],b_type_imm[10:5],5'd2,5'd1,3'b010,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BRANCH ILLEGAL
assign inst_sequence[7] = {b_type_imm[12],b_type_imm[10:5],5'd2,5'd1,`BEQ_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BEQ
assign inst_sequence[8] = {b_type_imm[12],b_type_imm[10:5],5'd4,5'd3,`BNE_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BNE
assign inst_sequence[9] = {b_type_imm[12],b_type_imm[10:5],5'd6,5'd5,`BLT_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BLT
assign inst_sequence[10] = {b_type_imm[12],b_type_imm[10:5],5'd8,5'd7,`BGE_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BGE
assign inst_sequence[11] = {b_type_imm[12],b_type_imm[10:5],5'd10,5'd9,`BLTU_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BLTU
assign inst_sequence[12] = {b_type_imm[12],b_type_imm[10:5],5'd12,5'd11,`BGEU_FUNCT3,b_type_imm[4:1],b_type_imm[11],`BRANCH_OPCODE}; //BGEU
assign inst_sequence[13] = {i_type_imm[11:0],5'd0,3'b111,5'd13,`LOAD_OPCODE}; //LOAD ILLEGAL
assign inst_sequence[14] = {i_type_imm[11:0],5'd1,`LB_FUNCT3,5'd14,`LOAD_OPCODE}; //LB
assign inst_sequence[15] = {i_type_imm[11:0],5'd2,`LH_FUNCT3,5'd15,`LOAD_OPCODE}; //LH
assign inst_sequence[16] = {i_type_imm[11:0],5'd3,`LW_FUNCT3,5'd16,`LOAD_OPCODE}; //LW
assign inst_sequence[17] = {i_type_imm[11:0],5'd4,`LBU_FUNCT3,5'd17,`LOAD_OPCODE}; //LBU
assign inst_sequence[18] = {i_type_imm[11:0],5'd5,`LHU_FUNCT3,5'd18,`LOAD_OPCODE}; //LHU
assign inst_sequence[19] = {s_type_imm[11:5],5'd0,5'd1,`SB_FUNCT3,s_type_imm[4:0],`STORE_OPCODE}; //SB
assign inst_sequence[20] = {s_type_imm[11:5],5'd2,5'd3,`SH_FUNCT3,s_type_imm[4:0],`STORE_OPCODE}; //SH
assign inst_sequence[21] = {s_type_imm[11:5],5'd4,5'd5,`SW_FUNCT3,s_type_imm[4:0],`STORE_OPCODE}; //SW
assign inst_sequence[22] = {s_type_imm[11:5],5'd6,5'd7,3'b111,s_type_imm[4:0],`STORE_OPCODE}; //STORE ILLEGAL
assign inst_sequence[23] = {i_type_imm,5'd12,`SLTI_FUNCT3,5'd23,`IMM_ARITH_OPCODE}; //SLTI
assign inst_sequence[24] = {`ALL_ZERO_FUNCT7,i_type_imm[4:0],5'd13,`SLLI_FUNCT3,5'd24,`IMM_ARITH_OPCODE}; //SLLI
assign inst_sequence[25] = {i_type_imm,5'd14,`SLTIU_FUNCT3,5'd25,`IMM_ARITH_OPCODE}; //SLTIU
assign inst_sequence[26] = {i_type_imm,5'd15,`XORI_FUNCT3,5'd26,`IMM_ARITH_OPCODE}; //XORI
assign inst_sequence[27] = {`ALL_ZERO_FUNCT7,i_type_imm[4:0],5'd16,`SRLI_FUNCT3,5'd27,`IMM_ARITH_OPCODE}; //SRLI
assign inst_sequence[28] = {`ONE_HOT_30_FUNCT7,i_type_imm[4:0],5'd17,`SRAI_FUNCT3,5'd28,`IMM_ARITH_OPCODE}; //SRAI
assign inst_sequence[29] = {7'b1,i_type_imm[4:0],5'd17,`SRAI_FUNCT3,5'd29,`IMM_ARITH_OPCODE}; //SRAI ILLEGAL
assign inst_sequence[30] = {i_type_imm,5'd19,`ANDI_FUNCT3,5'd30,`IMM_ARITH_OPCODE}; //ANDI
assign inst_sequence[31] = {i_type_imm,5'd20,`ADDI_FUNCT3,5'd31,`IMM_ARITH_OPCODE}; //ADDI

assign inst_sequence[32] = {`ALL_ZERO_FUNCT7,5'd1,5'd11,`ADD_FUNCT3,5'd11,`ARITH_OPCODE}; //ADD
assign inst_sequence[33] = {`ONE_HOT_30_FUNCT7,5'd2,5'd12,`SUB_FUNCT3,5'd12,`ARITH_OPCODE}; //SUB
assign inst_sequence[34] = {`ALL_ZERO_FUNCT7,5'd3,5'd13,`SLL_FUNCT3,5'd13,`ARITH_OPCODE}; //SLL
assign inst_sequence[35] = {`ALL_ZERO_FUNCT7,5'd4,5'd14,`SLT_FUNCT3,5'd14,`ARITH_OPCODE}; //SLT
assign inst_sequence[36] = {`ALL_ZERO_FUNCT7,5'd5,5'd15,`SLTU_FUNCT3,5'd15,`ARITH_OPCODE}; //SLTU
assign inst_sequence[37] = {`ALL_ZERO_FUNCT7,5'd6,5'd16,`XOR_FUNCT3,5'd16,`ARITH_OPCODE}; //XOR
assign inst_sequence[38] = {`ALL_ZERO_FUNCT7,5'd7,5'd17,`SRL_FUNCT3,5'd17,`ARITH_OPCODE}; //SRL
assign inst_sequence[39] = {`ONE_HOT_30_FUNCT7,5'd8,5'd18,`SRA_FUNCT3,5'd18,`ARITH_OPCODE}; //SRA
assign inst_sequence[40] = {`ALL_ZERO_FUNCT7,5'd9,5'd19,`OR_FUNCT3,5'd19,`ARITH_OPCODE}; //OR
assign inst_sequence[41] = {`ALL_ZERO_FUNCT7,5'd10,5'd20,`AND_FUNCT3,5'd20,`ARITH_OPCODE}; //AND
assign inst_sequence[42] = {8'h14,8'h94,8'h85,`ALPHATENSOR_MUL_OPCODE};	//ALPHATENSOR
assign inst_sequence[43] = {7'd9,5'd2,5'd12,`SUB_FUNCT3,5'd12,`ARITH_OPCODE}; //SUB ILLEGAL
assign inst_sequence[44] = {7'hF,5'd6,5'd16,`XOR_FUNCT3,5'd16,`ARITH_OPCODE}; //XOR ILLEGAL
assign inst_sequence[45] = {7'hD,i_type_imm[4:0],5'd13,`SLLI_FUNCT3,5'd24,`IMM_ARITH_OPCODE}; //SLLI ILLEGAL
assign inst_sequence[46] = {7'hF,i_type_imm[4:0],5'd13,`SRA_FUNCT3,5'd24,`ARITH_OPCODE}; //SRA ILLEGAL
assign inst_sequence[47] = {7'hD,i_type_imm[4:0],5'd13,`SRAI_FUNCT3,5'd24,7'b0}; //OPCODE ILLEGAL

assign inst_sequence[48] = `WFI_INST; //WFI 

assign inst_sequence[49] = {7'hD,5'd1,5'd11,`ADD_FUNCT3,5'd19,`ARITH_OPCODE}; //ADD ILLEGAL
assign inst_sequence[50] = {`ONE_HOT_30_FUNCT7,5'd2,5'd12,3'b111,5'd20,`ARITH_OPCODE}; //SUB ILLEGAL
assign inst_sequence[51] = {7'hD,5'd3,5'd13,`SLL_FUNCT3,5'd21,`ARITH_OPCODE}; //SLL ILLEGAL
assign inst_sequence[52] = {7'hD,5'd4,5'd14,`SLT_FUNCT3,5'd22,`ARITH_OPCODE}; //SLT ILLEGAL
assign inst_sequence[53] = {7'hD,5'd5,5'd15,`SLTU_FUNCT3,5'd23,`ARITH_OPCODE}; //SLTU ILLEGAL
assign inst_sequence[54] = {7'hD,5'd6,5'd16,`XOR_FUNCT3,5'd24,`ARITH_OPCODE}; //XOR ILLEGAL
assign inst_sequence[55] = {7'hD,5'd7,5'd17,`SRL_FUNCT3,5'd25,`ARITH_OPCODE}; //SRL ILLEGAL
assign inst_sequence[56] = {`ONE_HOT_30_FUNCT7,5'd8,5'd18,3'b010,5'd26,`ARITH_OPCODE}; //SRA ILLEGAL
assign inst_sequence[57] = {7'hD,5'd9,5'd19,`OR_FUNCT3,5'd27,`ARITH_OPCODE}; //OR ILLEGAL
assign inst_sequence[58] = {7'hD,5'd10,5'd20,`AND_FUNCT3,5'd28,`ARITH_OPCODE}; //AND ILLEGAL
assign inst_sequence[59] = {7'hD,i_type_imm[4:0],5'd13,`SLLI_FUNCT3,5'd24,`IMM_ARITH_OPCODE}; //SLLI ILLEGAL
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_idu_instDecode instDecode_test (

	//Instruction input
	.inst						(inst),

	//Decode result
	//Exception result
	.illegal_inst				(illegal_inst),
	
	//SYSTEM instruction
	.wfi						(wfi),
	
	//Imm data output
	.imm_data_out				(imm_data_out),

	//Data selection control flag within IDU
	.inst_rs1_vld				(inst_rs1_vld),
	.inst_rs2_vld				(inst_rs2_vld),
	.inst_rd_vld				(inst_rd_vld),		//Also pass to ALU LSU for bypass detecting
	.dmem_load					(dmem_load),		//Also pass to ALU LSU for indicating LOAD instruction
	.dmem_store					(dmem_store),		
	
	//Data selection control flag in ALU
	.alu_adder_sel_src1_pc		(alu_adder_sel_src1_pc),
	.alu_adder_sel_src2_rs2		(alu_adder_sel_src2_rs2),
	.alu_general_sel_src2_rs2	(alu_general_sel_src2_rs2),

	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	.unsigned_data				(unsigned_data),
	//Adder
	.adder_vld					(adder_vld),
	.adder_sub					(adder_sub),
	//Comparator
	.comparator_vld				(comparator_vld),
	//logical plane
	.logical_plane_and			(logical_plane_and),
	.logical_plane_or			(logical_plane_or),
	.logical_plane_xor			(logical_plane_xor),
	//Shifter
	.shifter_right_shift		(shifter_right_shift),
	.shifter_logical_shift		(shifter_logical_shift),

	//BRU
	.bru_jal					(bru_jal),
	.bru_jalr					(bru_jalr),
	.bru_bge					(bru_bge),
	.bru_blt					(bru_blt),
	.bru_beq					(bru_beq),
	.bru_bne					(bru_bne),

	//Memory access flag
	.lb					(lsu_sel_lb),
	.lh					(lsu_sel_lh),
	.lw					(lsu_sel_lw),
	.sw					(lsu_sel_sw),
	.sb					(lsu_sel_sb),
	.sh					(lsu_sel_sh),

	//Control flag for RF
	.rf_wen						(rf_wen),

	//Extended rs1, rs2, rd for accelerator
	`ifdef ALPHATENSOR
		.matrix_mem_rs1_idx			(matrix_mem_rs1_idx),
		.matrix_mem_rs2_idx			(matrix_mem_rs2_idx),
		.matrix_mem_rd_idx			(matrix_mem_rd_idx),
		//inst vld for matrix multiplication
		.matrix_mul_vld				(matrix_mul_vld),
	`endif

	//RS1,RS2 output, for RF
	.rf_rs1_idx					(rf_rs1_idx),
	.rf_rs2_idx					(rf_rs2_idx),

	//RD
	.rf_rd_idx					(rf_rd_idx)

);


//----------------------end----------------------//

//testbench
//-----------------simulation setting------------//
initial clk = 1'b1;      //define starting condition of clock

always #`HALF_CLOCK_CYCLE clk = ~clk;  //flopping clocks with clock cycle

//reset register before testing
initial begin
    rst_n = 1'b0;     
    #3;
    rst_n = 1'b1;
end
//set blackbox data
initial begin
	for(int i=0; i<`INST_MEM_DEPTH; i++) begin
		//imem_test.mem[i]	<=	inst_sequence[i];
	end
end
//modules input value setting
//for submodules including register, be careful with time changing value
initial begin
    //initialize
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`FULL_CLOCK_CYCLE;
    #`FULL_CLOCK_CYCLE;
    //input comes at rising edge
    #`FULL_CLOCK_CYCLE;
    start_pulse         <=   'b1;
    start_pc            <=   'b1000;
    core_configuration  <=   'b10;
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`HALF_CLOCK_CYCLE;
	#`FULL_CLOCK_CYCLE;
	for(int i=0 ; i<60; i++) begin
		#`FULL_CLOCK_CYCLE;
		inst	<=	inst_sequence[i];
	end
   #`FULL_CLOCK_CYCLE
   inst <= 32'h0;
end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #20000   //run time before calling finish, need to be long enough for all simulation
        $finish;
    end

    initial begin
        //for different modules waveform, change fsdb file name
        $fsdbDumpfile("{wave form name}.fsdb");
        $fsdbDumpvars("+all");
    end
`endif
//----------------------end----------------------//

endmodule
