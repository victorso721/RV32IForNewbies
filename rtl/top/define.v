//Core feature flag define
`define SUPER_SCALAR
`define ALPHATENSOR

//Core parameter
`define     EXCEPTION_NUM	2
`define     PC_WIDTH		32
`define     INST_WIDTH		32
`define	    DATA_WIDTH		32
/*As verilog do not support bulit in log2(x) function, pre-calculation is needed, modifying data width will affect result of log2(x). Multiple macro definition can help if set of x is small, using python will be a better approach if x is general arbitary value*/
`define DATA_WIDTH_BIT_NUM 5 //number of bit needed to locate all bit in data, 2^5 = 32

//SUPERSCALR Parameter
`ifdef SUPER_SCALAR
	`define SUPER_SCALAR_NUM 2
`endif

//ALPHATENSOR parameter
`ifdef ALPHATENSOR
	`define ALPHATENSOR_MUL_OPCODE 7'b1000001
	`define MATRIX_MEM_DATA_LENGTH 32
	`define MATRIX_MEM_DATA_LENGTH_BIT 5
	`define MATRIX_MEM_READ_MSB_INDEX (16*`MATRIX_MEM_DATA_LENGTH)-1	//16 element of 32-bit unsigned integer
	`define MATRIX_MEM_DATA_HALF_LENGTH (`MATRIX_MEM_DATA_LENGTH/2)
	`define MATRIX_MEM_DEPTH 256
	`define MATRIX_MEM_DEPTH_BIT 8
	//Number of multiplication of algorithm implemented
	`define MULITIPLICATION_NUM 47
	//Matrix Maximum dimension	
	`define ROW_NUM 4
	`define COL_NUM 4
`endif

//RF 
`define RF_DEPTH 32
`define RF_DEPTH_BIT 5
`define RF_READ_PORT_NUM 2

//IMEM parameter
`define INST_MEM_DEPTH 256
`define INST_MEM_WIDTH 32
`define INST_MEM_DEPTH_BIT 8
`define INST_MEM_WIDTH_BIT 5

//DMEM parameter
`define DATA_MEM_DEPTH 512
`define DATA_MEM_WIDTH 128
`define DATA_MEM_DEPTH_BIT 9
`define DATA_MEM_WIDTH_BIT 4 // Dmem is byte addressable

//Instruction Buffer parameter
`define INST_BUFFER_DEPTH 8
`define INST_BUFFER_DEPTH_BIT 3

//Instruction decode list
//U-Type
`define     LUI_OPCODE          7'b0110111
`define     AUIPC_OPCODE        7'b0010111

//Control flow instruction
//JUMP
`define     JAL_OPCODE          7'b1101111
`define     JALR_OPCODE         7'b1100111
`define     JALR_FUNCT3         3'b000
//BRANCH
`define     BRANCH_OPCODE       7'b1100011
`define     BEQ_FUNCT3          3'b000
`define     BNE_FUNCT3          3'b001
`define     BLT_FUNCT3          3'b100
`define     BGE_FUNCT3          3'b101
`define     BLTU_FUNCT3         3'b110
`define     BGEU_FUNCT3         3'b111

//Memory access instruction
//LOAD
`define     LOAD_OPCODE         7'b0000011
`define     LB_FUNCT3           3'b000
`define     LH_FUNCT3           3'b001
`define     LW_FUNCT3           3'b010
`define     LBU_FUNCT3          3'b100
`define     LHU_FUNCT3          3'b101
//STORE
`define     STORE_OPCODE        7'b0100011
`define     SB_FUNCT3           3'b000
`define     SH_FUNCT3           3'b001
`define     SW_FUNCT3           3'b010

//Arithmetic instruction
//I-TYPE 
`define     IMM_ARITH_OPCODE    7'b0010011
`define     ADDI_FUNCT3         3'b000
`define     SLTI_FUNCT3         3'b010
`define     SLLI_FUNCT3         3'b001
`define     SLTIU_FUNCT3        3'b011
`define     XORI_FUNCT3         3'b100
`define     SRLI_FUNCT3         3'b101
`define     SRAI_FUNCT3         3'b101     //SRLI and SRAI is seperate by FUNCT7
`define     ORI_FUNCT3          3'b110
`define     ANDI_FUNCT3         3'b111
//R_TYPE 
`define     ARITH_OPCODE        7'b0110011
`define     ADD_FUNCT3          3'b000
`define     SUB_FUNCT3          3'b000     //ADD and SUB is seperate by FUNCT7
`define     SLL_FUNCT3          3'b001
`define     SLT_FUNCT3          3'b010
`define     SLTU_FUNCT3         3'b011
`define     XOR_FUNCT3          3'b100
`define     SRL_FUNCT3          3'b101
`define     SRA_FUNCT3          3'b101     //SRL and SRA is seperated by FUNCT7
`define     OR_FUNCT3           3'b110
`define     AND_FUNCT3          3'b111

`define     ALL_ZERO_FUNCT7     7'b0000000
`define     ONE_HOT_30_FUNCT7   7'b0100000

//WFI
`define     WFI_INST            32'b00010000010100000000000001110011

