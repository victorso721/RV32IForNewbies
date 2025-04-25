`timescale 1ns/1ps

`define HALF_CLOCK_CYCLE 10  //parameter for clock cycle
`define FULL_CLOCK_CYCLE (`HALF_CLOCK_CYCLE + `HALF_CLOCK_CYCLE)

module tb_top;
//----------------simulated input---------------//
//SoC signal
reg                         	clk                 	;
reg                         	rst_n               	;

//SoC input
reg                         	start_pulse         	;
reg 	[`PC_WIDTH-1:0]         start_pc            	;
reg 	[`EXCEPTION_NUM-1:0]    core_configuration 	;

//Soc output
wire 	[1:0] 			core_status		;
wire 	[`EXCEPTION_NUM-1:0] 	core_exceptions		;
wire 	[`PC_WIDTH-1:0]		core_exceptions_pc	;

//IMEM driver
wire [`INST_MEM_WIDTH-1:0] inst_sequence [`INST_MEM_DEPTH-1:0];
wire [19:0] u_type_imm;
wire [19:0] j_type_imm;	//inst[21] = 1 will call unalign pc
wire [11:0] i_type_imm;
wire [12:1] b_type_imm;	//inst[8] = 1 will call unalign pc
wire [11:0] s_type_imm;
assign u_type_imm = 20'hFF24;
assign j_type_imm = 20'hAE86;
assign i_type_imm = 12'hEE;
assign b_type_imm = 12'h149;	//Due to compiler can't read wire slicing like imm[12], imm[10:5], in testing continous range is used
assign s_type_imm = 12'h485;
//------------R-type sequence--------//
assign inst_sequence[0] = {i_type_imm,5'd19,`ANDI_FUNCT3,5'd30,`IMM_ARITH_OPCODE};	//ANDI
assign inst_sequence[1] = {i_type_imm,5'd20,`ADDI_FUNCT3,5'd31,`IMM_ARITH_OPCODE};	//ADDI 
assign inst_sequence[2] = {i_type_imm[11:0],5'd3,`LW_FUNCT3,5'd16,`LOAD_OPCODE}; //LW
assign inst_sequence[3] = {7'hD,i_type_imm[4:0],5'd13,`SLLI_FUNCT3,5'd24,`IMM_ARITH_OPCODE}; //SLLI ILLEGAL
assign inst_sequence[4] = {`ALL_ZERO_FUNCT7,5'd5,5'd15,`SLTU_FUNCT3,5'd15,`ARITH_OPCODE}; //SLTU
assign inst_sequence[5] = {`ALL_ZERO_FUNCT7,5'd6,5'd16,`XOR_FUNCT3,5'd16,`ARITH_OPCODE}; //XOR
assign inst_sequence[6] = {`ALL_ZERO_FUNCT7,5'd7,5'd17,`SRL_FUNCT3,5'd17,`ARITH_OPCODE}; //SRL
assign inst_sequence[7] = {`ONE_HOT_30_FUNCT7,5'd8,5'd18,`SRA_FUNCT3,5'd18,`ARITH_OPCODE}; //SRA
//------------JALR sequence--------//
assign inst_sequence[8] = {`ALL_ZERO_FUNCT7,5'd10,5'd20,`AND_FUNCT3,5'd20,`ARITH_OPCODE}; //AND
assign inst_sequence[9] = {`ALL_ZERO_FUNCT7,5'd9,5'd19,`OR_FUNCT3,5'd19,`ARITH_OPCODE}; //OR
assign inst_sequence[10] = {i_type_imm,5'd19,`ANDI_FUNCT3,5'd30,`IMM_ARITH_OPCODE};	//ANDI
assign inst_sequence[11] = {i_type_imm,5'd20,`ADDI_FUNCT3,5'd31,`IMM_ARITH_OPCODE};	//ADDI 
assign inst_sequence[12] = {s_type_imm[11:5],5'd0,5'd1,`SB_FUNCT3,s_type_imm[4:0],`STORE_OPCODE}; //SB
assign inst_sequence[13] = {i_type_imm,5'd9,3'b111,5'd4,`JALR_OPCODE}; //JALR ILLEGAL
assign inst_sequence[14] = {`WFI_INST};	//WFI
assign inst_sequence[15] = {20'd15,5'd15,`LUI_OPCODE};	//LUI 
assign inst_sequence[16] = {20'd16,5'd16,`LUI_OPCODE};	//LUI 
assign inst_sequence[17] = {20'd17,5'd17,`LUI_OPCODE};	//LUI 

//--------------------------------//
/*
//assign inst_sequence[0] = {u_type_imm,5'd0,`LUI_OPCODE};	//LUI 
//assign inst_sequence[1] = {u_type_imm,5'd1,`AUIPC_OPCODE};	//AUIPC
assign inst_sequence[0] = {20'd9,5'd2,`JAL_OPCODE};	//JAL
assign inst_sequence[1] = {20'd29,5'd2,`JAL_OPCODE};	//JAL
assign inst_sequence[2] = {j_type_imm,5'd2,`JAL_OPCODE};	//JAL
assign inst_sequence[3] = {i_type_imm,5'd9,`JALR_FUNCT3,5'd3,`JALR_OPCODE}; //JALR
assign inst_sequence[4] = {i_type_imm,5'd9,3'b111,5'd4,`JALR_OPCODE}; //JALR ILLEGAL
assign inst_sequence[5] = 32'b0;
assign inst_sequence[6] = {b_type_imm[12:6],5'd2,5'd1,3'b010,b_type_imm[5:1],`BRANCH_OPCODE}; //BRANCH ILLEGAL
assign inst_sequence[7] = {b_type_imm[12:6],5'd2,5'd1,`BEQ_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BEQ
assign inst_sequence[8] = {b_type_imm[12:6],5'd4,5'd3,`BNE_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BNE
assign inst_sequence[9] = {b_type_imm[12:6],5'd6,5'd5,`BLT_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BLT
assign inst_sequence[10] = {b_type_imm[12:6],5'd8,5'd7,`BGE_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BGE
assign inst_sequence[11] = {b_type_imm[12:6],5'd10,5'd9,`BLTU_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BLTU
assign inst_sequence[12] = {b_type_imm[12:6],5'd12,5'd11,`BGEU_FUNCT3,b_type_imm[5:1],`BRANCH_OPCODE}; //BGEU
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
assign inst_sequence[46] = {7'hF,i_type_imm[4:0],5'd13,`SRA_FUNCT3,5'd24,`ARITH_OPCODE}; //SRAI ILLEGAL
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
assign inst_sequence[59] = {7'hD,i_type_imm[4:0],5'd13,`SLLI_FUNCT3,5'd29,`IMM_ARITH_OPCODE}; //SLLI ILLEGAL
*/

//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_riscv riscv (
	.clk					(clk),
	.rst_n					(rst_n),
	.start_pulse				(start_pulse),
	.start_pc				(start_pc),
	.core_configuration			(core_configuration),
	.core_status				(core_status),
	.core_exceptions			(core_exceptions),
	.core_exceptions_pc			(core_exceptions_pc)	
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
//set blackbox data after reset
initial begin
	@(rst_n);
	#`FULL_CLOCK_CYCLE;
	//for(int i=0; i<`INST_MEM_DEPTH; i++) begin
	//for(int i=0; i<67; i++) begin
	//	riscv.ifu.imem.mem[i]	=	inst_sequence[i];
	//end
	for(int i=1; i<`RF_DEPTH; i++) begin
		riscv.rf.rf_data_array[i] = i;
	end
	riscv.ifu.imem.mem	=	inst_sequence;

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
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b1;
    start_pc            <=   'b11;
    core_configuration  <=   'b01;
    #`FULL_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`HALF_CLOCK_CYCLE;


end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #200000   //run time before calling finish, need to be long enough for all simulation
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
