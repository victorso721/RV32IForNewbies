//This block simply act as instruction decode by checking combination 
//input: 
//1. whole instruction
//output: 
//1. control flag indicate what operation is doing, for ALU, LSU and RF
//2. control flag for imm data selection within IDU
//3. RS1 and RS2, just feed through signal, reserve in interface to make reading of whole instruction legit
//4. RD, also feed through with same reason as 3.
//5. Extend RS1, RS2 and RD, added just for accelerator feature
//6. Matrix mulitplication instruction vld, added just for accelerator feature

module u_idu_instDecode (

	//Instruction input
	input [`INST_WIDTH-1:0] inst,

	//Decode result
	//Exception result
	output illegal_inst,
	
	//SYSTEM instruction
	output wfi,

	//Imm data output
	output [`DATA_WIDTH-1:0] imm_data_out,

	//Data selection control flag within IDU
	output inst_rs1_vld,
	output inst_rs2_vld,
	output inst_rd_vld,
	output dmem_load,		//Also pass to ALU LSU for indicating LOAD instruction
	output dmem_store,

	//Data selection control flag in ALU
	output alu_adder_sel_src1_pc,
	output alu_adder_sel_src2_rs2,
	output alu_general_sel_src2_rs2,

	//Control flag for calculation module in ALU
	//General flag, whether data is treated unsigned
	output unsigned_data,
	//Adder
	output adder_vld,
	output adder_sub,
	//Comparator
	output comparator_vld,
	//logical plane
	output logical_plane_and,
	output logical_plane_or,
	output logical_plane_xor,
	//Shifter
	output shifter_right_shift,
	output shifter_logical_shift,
	//BRU
	output bru_jal,
	output bru_jalr,
	output bru_bge,
	output bru_blt,
	output bru_beq,
	output bru_bne,

	//Memory access flag
	output lb,	
	output lh,
	output lw,
	output sw,
	output sb,
	output sh,

	//Control flag for RF
	output rf_wen,

	//Extended rs1, rs2, rd for accelerator
	`ifdef ALPHATENSOR
		output [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rs1_idx,
		output [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rs2_idx,
		output [`MATRIX_MEM_DEPTH_BIT-1:0] matrix_mem_rd_idx,
		//inst vld for matrix multiplication
		output matrix_mul_vld,
	`endif

	//RS1,RS2 output, for RF
	output [`RF_DEPTH_BIT-1:0] rf_rs1_idx,
	output [`RF_DEPTH_BIT-1:0] rf_rs2_idx,

	//RD
	output [`RF_DEPTH_BIT-1:0] rf_rd_idx
);

//Internal signal
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;

wire s_type;
wire r_type;
wire i_type;
wire j_type;
wire b_type;
wire u_type;

wire [`DATA_WIDTH-1:0] s_type_imm;
wire [`DATA_WIDTH-1:0] i_type_imm;
wire [`DATA_WIDTH-1:0] j_type_imm;
wire [`DATA_WIDTH-1:0] b_type_imm;
wire [`DATA_WIDTH-1:0] u_type_imm;

wire lui;
wire auipc;
wire jal;
wire jalr;
wire jalr_inst;
wire branch;
wire load;
wire store;
wire imm_arith;
wire arith;
wire opcode_illegal;
wire branch_illegal;
wire jalr_illegal;
wire load_illegal;
wire store_illegal;
wire imm_arith_illegal;
wire arith_illegal;

wire bgeu;
wire bltu;
wire bge;
wire blt;
wire beq;
wire bne;
wire addi;
wire slti;
wire sltiu;
wire xori;
wire ori;
wire andi;
wire slli;
wire srli;
wire srai;
wire add;
wire sub;
wire sll;
wire slt;
wire sltu;
wire srl;
wire sra;
wire xor_inst;
wire or_inst;
wire and_inst;
wire lb_inst;
wire lh_inst;
wire lbu;
wire lhu;

wire alphaTensor_vld;
wire exceptions_inst;

//RS1,RS2,RD
assign rf_rs1_idx	= inst[19:15];
assign rf_rs2_idx	= inst[24:20];
assign rf_rd_idx	= inst[11:7];

//RS1,RS2,RD for accelerator
`ifdef ALPHATENSOR
	assign matrix_mem_rs1_idx = {funct7[2:0],rf_rs1_idx};
	assign matrix_mem_rs2_idx = {funct7[5:3],rf_rs2_idx};
	assign matrix_mem_rd_idx = {funct3,rf_rd_idx};
`endif

//Instruction decoding
assign opcode	= inst[6:0];
assign funct3	= inst[14:12];
assign funct7	= inst[31:25];

//Instruction decoding
//Propose of design below:
//1. Do opcode, funct3 and funct7 decode seperately
//2. check condition for exact instruction decoded
//3. Activate control flags, or report exceptions
//Opcode decode, data path control only need opcode
assign lui 				= (opcode == `LUI_OPCODE);
assign auipc 			= (opcode == `AUIPC_OPCODE);
assign jal 				= (opcode == `JAL_OPCODE);
assign jalr				= (opcode == `JALR_OPCODE);
assign branch   		= (opcode == `BRANCH_OPCODE);
assign load				= (opcode == `LOAD_OPCODE);
assign store			= (opcode == `STORE_OPCODE);
assign imm_arith		= (opcode == `IMM_ARITH_OPCODE);
assign arith 			= (opcode == `ARITH_OPCODE);
assign opcode_illegal	= ~(exceptions_inst | lui | auipc | jal | jalr | branch | load | store | imm_arith | arith);

//Instruction decoding
//LUI:DECODED, opcode only
//AUIPC: DECODED, opcode only
//Jump
assign jalr_inst		= jalr & (funct3 == `JALR_FUNCT3);
assign jalr_illegal		= jalr & ~(funct3 == `JALR_FUNCT3);
//Branch
assign beq				= branch & (funct3 == `BEQ_FUNCT3);
assign bne				= branch & (funct3 == `BNE_FUNCT3);
assign blt				= branch & (funct3 == `BLT_FUNCT3);
assign bge				= branch & (funct3 == `BGE_FUNCT3);
assign bltu				= branch & (funct3 == `BLTU_FUNCT3);
assign bgeu				= branch & (funct3 == `BGEU_FUNCT3);
assign branch_illegal	= branch & ~((funct3 == `BEQ_FUNCT3)|(funct3 == `BNE_FUNCT3)|(funct3 == `BLT_FUNCT3)|(funct3 == `BGE_FUNCT3)|(funct3 == `BLTU_FUNCT3)|(funct3 == `BGEU_FUNCT3));
assign bru_jal			= jal;
assign bru_jalr			= jalr_inst;
assign bru_beq			= beq;
assign bru_bne			= bne;
assign bru_blt			= blt | bltu;
assign bru_bge			= bge | bgeu;

//Load
assign lb_inst				= load & (funct3 == `LB_FUNCT3);
assign lh_inst				= load & (funct3 == `LH_FUNCT3);
assign lw				= load & (funct3 == `LW_FUNCT3);
assign lbu				= load & (funct3 == `LBU_FUNCT3);
assign lhu				= load & (funct3 == `LHU_FUNCT3);
assign load_illegal		= load & ~((funct3 == `LB_FUNCT3)|(funct3 == `LH_FUNCT3)|(funct3 == `LW_FUNCT3)|(funct3 == `LBU_FUNCT3)|(funct3 == `LHU_FUNCT3));
//Store
assign sb				= store & (funct3 == `SB_FUNCT3);
assign sh				= store & (funct3 == `SH_FUNCT3);
assign sw				= store & (funct3 == `SW_FUNCT3);
assign store_illegal	= store & ~((funct3 == `SB_FUNCT3)|(funct3 == `SH_FUNCT3)|(funct3 == `SW_FUNCT3));
//Imm-arith
assign addi				= imm_arith & (funct3 == `ADDI_FUNCT3);
assign slti				= imm_arith & (funct3 == `SLTI_FUNCT3);
assign sltiu			= imm_arith & (funct3 == `SLTIU_FUNCT3);
assign xori				= imm_arith & (funct3 == `XORI_FUNCT3);
assign ori				= imm_arith & (funct3 == `ORI_FUNCT3);
assign andi				= imm_arith & (funct3 == `ANDI_FUNCT3);
assign slli				= imm_arith & (funct3 == `SLLI_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign srli				= imm_arith & (funct3 == `SRLI_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign srai				= imm_arith & (funct3 == `SRAI_FUNCT3) & (funct7 == `ONE_HOT_30_FUNCT7);
assign slli_illegal			= imm_arith & (funct3 == `SLLI_FUNCT3) & (funct7 != `ALL_ZERO_FUNCT7);
assign srali_illegal			= imm_arith & (funct3 == `SRLI_FUNCT3) & (funct7 != `ALL_ZERO_FUNCT7) & (funct7 != `ONE_HOT_30_FUNCT7); //srai and srli share same funct3

//Deadcode: imm_arith funct3 is fully used, no illegal combination
//assign imm_arith_illegal = imm_arith & ~((funct3 == `ADDI_FUNCT3)|(funct3 == `SLTI_FUNCT3)|(funct3 == `SLTIU_FUNCT3)|(funct3 == `XORI_FUNCT3)|(funct3 == `ORI_FUNCT3)|(funct3 == `ANDI_FUNCT3)|((funct3 == `SLLI_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7))|((funct3 == `SRLI_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7))|((funct3 == `SRAI_FUNCT3) & (funct7 == `ONE_HOT_30_FUNCT7)));
assign imm_arith_illegal = srali_illegal | slli_illegal;
//Arith
assign add				= arith & (funct3 == `ADD_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign sub				= arith & (funct3 == `SUB_FUNCT3) & (funct7 == `ONE_HOT_30_FUNCT7);
assign sll				= arith & (funct3 == `SLL_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign slt				= arith & (funct3 == `SLT_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign sltu				= arith & (funct3 == `SLTU_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign xor_inst			= arith & (funct3 == `XOR_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign srl				= arith & (funct3 == `SRL_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign sra				= arith & (funct3 == `SRA_FUNCT3) & (funct7 == `ONE_HOT_30_FUNCT7);
assign or_inst			= arith & (funct3 == `OR_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
assign and_inst			= arith & (funct3 == `AND_FUNCT3) & (funct7 == `ALL_ZERO_FUNCT7);
//as funct3 is fully used, only checking if it is SUB or SRA can cover whole funct3
//1. mask by arith opcode checking result
//2. check if funct7 is legal
//3. for funct7 ONE HOT, check if funct3 legal
//4. for funct7 ALL ZERO, all funct3 is legal so no checking is needed
assign arith_illegal			= arith & (~((funct7 == `ONE_HOT_30_FUNCT7)|(funct7 == `ALL_ZERO_FUNCT7)) | ((funct7 == `ONE_HOT_30_FUNCT7) & ~((funct3 == `SUB_FUNCT3)|(funct3 == `SRA_FUNCT3))));

//ALU internal control flag generation
assign unsigned_data			= bltu | bgeu | sltiu | sltu | lbu | lhu;
assign adder_vld				= lui | auipc | lb_inst | lh_inst | lw | lbu | lhu | addi | add | sub; //for jal and jalr, return address pc+4 choose by jump flag but not adder_vld
assign adder_sub				= sub;
assign comparator_vld			= slt | sltu | slti | sltiu;
assign logical_plane_and		= and_inst | andi;
assign logical_plane_or			= or_inst | ori;
assign logical_plane_xor		= xor_inst | xori | beq | bne; //xor = result of (rs1 != rs2)
assign shifter_right_shift		= sra | srl | srai | srli;
assign shifter_logical_shift	= srl | sll | srli | slli;

//ALU data flag generation
assign alu_adder_sel_src1_pc	= auipc | branch | jal;
assign alu_adder_sel_src2_rs2 	= r_type;
assign alu_general_sel_src2_rs2	= r_type | branch;

//Memory control flag generation
assign dmem_load				= lb_inst | lh_inst | lw | lbu | lhu;
assign dmem_store				= sb | sh | sw;
assign lb					= lb_inst | lbu;
assign lh					= lh_inst | lhu;
//Control signal for matrix multiplication
`ifdef ALPHATENSOR
	assign matrix_mul_vld = alphaTensor_vld;
`endif

//Exception instructions
//As the status registers is ignored in this project,
//decode of wfi instruction will be completed by decode all 32 bits instruction
assign wfi						= (inst == `WFI_INST);
`ifdef ALPHATENSOR
	assign alphaTensor_vld		= (opcode == `ALPHATENSOR_MUL_OPCODE);
	assign exceptions_inst 		= wfi | alphaTensor_vld;
`else
	assign exceptions_inst 		= wfi;
`endif

//IDU internal data flag generation
assign s_type		= store;
assign b_type		= branch;
assign j_type		= jal;
assign i_type		= imm_arith | jalr | load;
assign r_type		= arith;
assign u_type		= lui | auipc;
assign inst_rs1_vld	= s_type | b_type | i_type | r_type;
assign inst_rs2_vld	= r_type | b_type | s_type;
assign inst_rd_vld	= rf_wen;
assign rf_wen		= (u_type | j_type | i_type | r_type) & (rf_rd_idx != 'b0);

//immediate data selection
assign i_type_imm	= {{`DATA_WIDTH-1-10{inst[31]}},inst[30:21],inst[20]};
assign s_type_imm	= {{`DATA_WIDTH-1-10{inst[31]}},inst[30:25],inst[11:7]};
assign b_type_imm	= {{`DATA_WIDTH-1-11{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0}; 
assign u_type_imm	= {inst[31:12],{12{1'b0}}};
assign j_type_imm	= {{`DATA_WIDTH-1-19{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0}; 

assign imm_data_out	= {`DATA_WIDTH{i_type}} & i_type_imm | {`DATA_WIDTH{s_type}} & s_type_imm | {`DATA_WIDTH{b_type}} & b_type_imm | {`DATA_WIDTH{u_type}} & u_type_imm | {`DATA_WIDTH{j_type}} & j_type_imm;

//Exception generating
//exception inst is considered in opcode detection
//funct7 illegal also call expcetion 
assign illegal_inst	= opcode_illegal | branch_illegal | jalr_illegal | load_illegal | store_illegal | imm_arith_illegal | arith_illegal;

endmodule
