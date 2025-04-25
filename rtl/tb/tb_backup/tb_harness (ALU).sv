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
	//logic plane
	reg [`DATA_WIDTH-1:0] logic_plane_data_in_1;
	reg [`DATA_WIDTH-1:0] logic_plane_data_in_2;
	reg and_flag;
	reg or_flag;
	reg xor_flag;
	wire [`DATA_WIDTH-1:0] logic_plane_data_out;
	wire logic_plane_output_vld;
	//comparator
	reg [`DATA_WIDTH-1:0] comp_data_in_1;
	reg [`DATA_WIDTH-1:0] comp_data_in_2;
	reg unsigned_comp;
	wire [`DATA_WIDTH-1:0] comp_data_out;
	//shifter
	reg [`DATA_WIDTH-1:0] shifter_data_in_1;
	reg [`DATA_WIDTH-1:0] shifter_data_in_2;
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
	.logic_plane_data_in_1 (logic_plane_data_in_1),
	.logic_plane_data_in_2 (logic_plane_data_in_2),
	.and_flag (and_flag),
	.or_flag (or_flag),	
	.xor_flag (xor_flag),
	.logic_plane_data_out (logic_plane_data_out),
	.logic_plane_output_vld (logic_plane_output_vld)
);
u_alu_comparator alu_comparator_test (
	.comp_data_in_1 (comp_data_in_1),
	.comp_data_in_2 (comp_data_in_2),
	.unsigned_comp (unsigned_comp),
	.comp_data_out (comp_data_out)
);
u_alu_shifter alu_shifter_test (
	.shifter_data_in_1	(shifter_data_in_1),
	.shifter_data_in_2	(shifter_data_in_2[`DATA_WIDTH_BIT_NUM-1:0]),
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
    //add overflow
    #`FULL_CLOCK_CYCLE;
    adder_data_in_1	<=  32'hFFFF_FFFF;
    adder_data_in_2	<=  32'hF;
    sub			<=  1'b0;
    //sub 
    #`FULL_CLOCK_CYCLE;
    adder_data_in_1	<=  32'hFF0F_FFFA;
    adder_data_in_2	<=  32'hA;
    sub			<=  1'b1;
    //sub overflow 
    #`FULL_CLOCK_CYCLE;
    adder_data_in_1	<=  32'h0;
    adder_data_in_2	<=  32'hF;
    sub			<=  1'b1;
    and_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    or_flag		<=  1'b0;
    //logic plane and 
    #`FULL_CLOCK_CYCLE;
    adder_data_in_1	<=  32'h0;
    adder_data_in_2	<=  32'h0;
    sub			<=  1'b0;
    and_flag		<=  1'b1;
    xor_flag		<=  1'b0;
    or_flag		<=  1'b0;
    logic_plane_data_in_1 <= 32'hFFFF_FFFF;
    logic_plane_data_in_2 <= 32'hFF0F_0FF0;
    //logic plane xor unequal 
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    xor_flag		<=  1'b1;
    or_flag		<=  1'b0;
    logic_plane_data_in_1 <= 32'hF0FF_F0FF;
    logic_plane_data_in_2 <= 32'hF00F_0FF0;
    //logic plane or 
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    or_flag		<=  1'b1;
    logic_plane_data_in_1 <= 32'h0000_F0FF;
    logic_plane_data_in_2 <= 32'hF00F_0FF0;
    //logic plane xor equal 
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    xor_flag		<=  1'b1;
    or_flag		<=  1'b0;
    logic_plane_data_in_1 <= 32'hAAAA_BBBB;
    logic_plane_data_in_2 <= 32'hAAAA_BBBB;
    //unsigned comparasion, rs1<rs2 = 0
    #`FULL_CLOCK_CYCLE;
    and_flag		<=  1'b0;
    xor_flag		<=  1'b0;
    or_flag		<=  1'b0;
    logic_plane_data_in_1 <= 32'h0;
    logic_plane_data_in_2 <= 32'h0;
    unsigned_comp	<=  1'b1;
    comp_data_in_1 	<= 32'hFFFF;
    comp_data_in_2 	<= 32'h0;
    //signed comparasion, rs1<rs2 = 1
    #`FULL_CLOCK_CYCLE;
    unsigned_comp	<=  1'b0;
    comp_data_in_1 	<= 32'hFFFF_ABCD;
    comp_data_in_2 	<= 32'hABCD;
    //unsigned comparasion, rs1<rs2 = 1
    #`FULL_CLOCK_CYCLE;
    unsigned_comp	<=  1'b1;
    comp_data_in_1 	<= 32'hFFFF_0000;
    comp_data_in_2 	<= 32'hFFFF_0001;
    //signed comparasion, rs1<rs2 = 0
    #`FULL_CLOCK_CYCLE;
    unsigned_comp	<=  1'b0;
    comp_data_in_1 	<= 32'h0000_ABCD;
    comp_data_in_2 	<= 32'hF123_ABCD;
    //right logical shift
    #`FULL_CLOCK_CYCLE;
    unsigned_comp	<=  1'b0;
    comp_data_in_1 	<= 32'h0000_0000;
    comp_data_in_2 	<= 32'h0000_0000;
    shifter_data_in_1 	<= 32'hF000_0000;
    shifter_data_in_2	<= 32'd31;
    right_shift	<= 1'b1;
    logical_shift <= 1'b1;
    //left logical shift
    #`FULL_CLOCK_CYCLE;
    shifter_data_in_1 	<= 32'h0000_0001;
    shifter_data_in_2	<= 32'd31;
    right_shift	<= 1'b0;
    logical_shift <= 1'b1;
    //right arithmetic shift 1
    #`FULL_CLOCK_CYCLE;
    shifter_data_in_1 	<= 32'h8001_0001;
    shifter_data_in_2	<= 32'd16;
    right_shift	<= 1'b1;
    logical_shift <= 1'b0;
    //left arithmetic shift, invalid shift
    #`FULL_CLOCK_CYCLE;
    shifter_data_in_1 	<= 32'hDEAD_BEEF;
    shifter_data_in_2	<= 32'hDEAF_BE8D;
    right_shift	<= 1'b0;
    logical_shift <= 1'b0;
    //right arithmetic shift 2
    #`FULL_CLOCK_CYCLE;
    shifter_data_in_1 	<= 32'h0701_0001;
    shifter_data_in_2	<= 32'd16;
    right_shift	<= 1'b1;
    logical_shift <= 1'b0;
    //clear
    #`FULL_CLOCK_CYCLE;
    shifter_data_in_1 	<= 32'h0;
    shifter_data_in_2	<= 32'd0;
    right_shift	<= 1'b0;
    logical_shift <= 1'b0;
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
