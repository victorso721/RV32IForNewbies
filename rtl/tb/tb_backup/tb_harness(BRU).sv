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
	//adder
	reg [`DATA_WIDTH-1:0] adder_data_in_1;
	reg [`DATA_WIDTH-1:0] adder_data_in_2;
	reg sub;
	wire [`DATA_WIDTH-1:0] adder_data_out;
	//Non-adder
	reg [`DATA_WIDTH-1:0] non_adder_data_in_1;
	reg [`DATA_WIDTH-1:0] non_adder_data_in_2;
	reg flag_unsigned_data;
	//logic plane
	reg and_flag;
	reg or_flag;
	reg xor_flag;
	wire [`DATA_WIDTH-1:0] logic_plane_data_out;
	wire logic_plane_output_vld;
	//comparator
	wire [`DATA_WIDTH-1:0] comp_data_out;
	//BRU
	//pc input
	reg [`DATA_WIDTH-1:0] bru_redir_pc_in;
	reg jump;
	reg blt;
	reg bge;
	reg beq;	//|(rs1 XNOR rs2) == 1
	reg bne;	//|(rs1 XOR rs2) == 1
	wire bru_output_vld;
	wire bru_flush;
	wire [`PC_WIDTH-1:0] bru_redir_pc;
	//shifter
	reg right_shift;
	reg logical_shift;
	wire [`DATA_WIDTH-1:0] shifter_data_out;
	wire shifter_output_vld;


//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_alu_adder alu_adder_test (
	.adder_data_in_1 (adder_data_in_1),
	.adder_data_in_2 (adder_data_in_2),
	.sub (sub),
	.adder_data_out (adder_data_out)
);
u_alu_logic_plane alu_logic_plane_test (
	.logic_plane_data_in_1 (non_adder_data_in_1),
	.logic_plane_data_in_2 (non_adder_data_in_2),
	.and_flag (and_flag),
	.or_flag (or_flag),	
	.xor_flag (xor_flag),
	.logic_plane_data_out (logic_plane_data_out),
	.logic_plane_output_vld (logic_plane_output_vld)
);
u_alu_comparator alu_comparator_test (
	.comp_data_in_1 (non_adder_data_in_1),
	.comp_data_in_2 (non_adder_data_in_2),
	.unsigned_comp (flag_unsigned_data),
	.comp_data_out (comp_data_out)
);

u_bru bru_test(
	.bru_redir_pc_in 	(adder_data_out),
	.jump				(jump),
	.blt				(blt),
	.bge				(bge),
	.beq				(beq),
	.bne				(bne),
	.slt_result			(comp_data_out),
	.xor_result			(logic_plane_data_out),
	.bru_output_vld		(bru_output_vld),
	.bru_flush			(bru_flush),
	.bru_redir_pc		(bru_redir_pc)
);
u_alu_shifter alu_shifter_test (
	.shifter_data_in_1	(non_adder_data_in_1),
	.shifter_data_in_2	(non_adder_data_in_2[`DATA_WIDTH_BIT_NUM-1:0]),
	.right_shift		(right_shift),
	.logical_shift		(logical_shift),
	.shifter_data_out	(shifter_data_out),
	.shifter_output_vld	(shifter_output_vld)
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
	@(rst_n);
	#`FULL_CLOCK_CYCLE;
	for(int i=0; i<`INST_MEM_DEPTH; i++) begin
		//ifu_test.imem.mem[i] = i;
	end
	for(int i=0; i<`RF_DEPTH; i++) begin
		//rf_test.rf_data_array[i] = i;
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
    fork
	repeat (2) begin @(posedge clk); end
    join_none
    #`FULL_CLOCK_CYCLE;
    #`HALF_CLOCK_CYCLE;
    start_pulse         <=   'b0;
    start_pc            <=   'b0;
    core_configuration  <=   'b0;
    #`HALF_CLOCK_CYCLE;
    //BRU bge, no bru flush as rs1(-ve) < rs2(+ve)
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_BEEF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'hFFFF_FFFF;
    non_adder_data_in_2	<=  32'h0000_FFFF;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b1;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b0;
    //BRU bgeu, call bru flush as rs1 > rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'hFFFF_FFFF;
    non_adder_data_in_2	<=  32'h0000_FFFF;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b1;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b1;
    //BRU beq, call bru flush as rs1 == rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b1;
    adder_data_in_1	<=  32'h0000_123F;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'h0000_ABCE;
    non_adder_data_in_2	<=  32'h0000_ABCE;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b0;
    blt			<=  1'b0;
    beq			<=  1'b1;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b0;
    //BRU bge, call bru flush as rs1(0) > rs2(-ve)
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_BEEF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'h0000_0000;
    non_adder_data_in_2	<=  32'h8F00_0000;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b1;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b0;
    //BRU bgeu, no bru flush as rs1 < rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'h0000_FFFF;
    non_adder_data_in_2	<=  32'hABCD_0000;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b1;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b1;
    //BRU bltu, no bru flush as rs1 == rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'hDEAD_BEEF;
    non_adder_data_in_2	<=  32'hDEAD_BEEF;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b0;
    blt			<=  1'b1;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b1;
    //BRU bne, no bru flush as rs1 != rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b1;
    adder_data_in_1	<=  32'h0000_123F;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'h0000_ABCE;
    non_adder_data_in_2	<=  32'h0000_ABCE;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b0;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b1;
    flag_unsigned_data	<=  1'b0;
    //BRU blt, no bru flush as rs1 > rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'h0000_FFFF;
    non_adder_data_in_2	<=  32'hABCD_0000;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b0;
    blt			<=  1'b1;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b0;
    //BRU bgeu, call bru flush as rs1 == rs2
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'h1;
    non_adder_data_in_1	<=  32'hDEAD_BEEF;
    non_adder_data_in_2	<=  32'hDEAD_BEEF;
    sub			<=  1'b0;
    jump		<=  1'b0;
    bge			<=  1'b1;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b1;
    //JUMP
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    or_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    adder_data_in_1	<=  32'h0000_FFFF;
    adder_data_in_2	<=  32'hFF00_0000;
    non_adder_data_in_1	<=  32'hDEAD_BEEF;
    non_adder_data_in_2	<=  32'hDEAD_BEEF;
    sub			<=  1'b0;
    jump		<=  1'b1;
    bge			<=  1'b0;
    blt			<=  1'b0;
    beq			<=  1'b0;
    bne			<=  1'b0;
    flag_unsigned_data	<=  1'b0;
end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #1000   //run time before calling finish, need to be long enough for all simulation
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
