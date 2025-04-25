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
	reg [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_matrix_mem_rd_idx;
	reg [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_matrix_mem_rs1_idx;
	reg [`MATRIX_MEM_DEPTH_BIT-1:0] idu_alphaTensor_matrix_mem_rs2_idx;
	reg idu_alphaTensor_matrix_mul_vld;

	//ALU input
	reg iex_alphaTensor_bru_vld_0;
	reg iex_alphaTensor_bru_flush_0;
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_alphaTensor alphaTensor_test (
	.clk									(clk),
	.rst_n									(rst_n),
	.idu_alphaTensor_rd						(idu_alphaTensor_matrix_mem_rd_idx),
	.idu_alphaTensor_rs1					(idu_alphaTensor_matrix_mem_rs1_idx),
	.idu_alphaTensor_rs2					(idu_alphaTensor_matrix_mem_rs2_idx),
	.idu_alphaTensor_mul_vld				(idu_alphaTensor_matrix_mul_vld),
	.iex_alphaTensor_bru_vld_0				(iex_alphaTensor_bru_vld_0),
	.iex_alphaTensor_bru_flush_0			(iex_alphaTensor_bru_flush_0)
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
	for(int i=0; i<`MATRIX_MEM_DEPTH; i++) begin
		alphaTensor_test.dmem.mem[i] = i;
	end

	alphaTensor_test.dmem.mem[3][(0*`MATRIX_MEM_DATA_LENGTH)+31:0*`MATRIX_MEM_DATA_LENGTH] = 32'd1;
	alphaTensor_test.dmem.mem[3][(1*`MATRIX_MEM_DATA_LENGTH)+31:1*`MATRIX_MEM_DATA_LENGTH] = 32'd2;
	alphaTensor_test.dmem.mem[3][(2*`MATRIX_MEM_DATA_LENGTH)+31:2*`MATRIX_MEM_DATA_LENGTH] = 32'd3;
	alphaTensor_test.dmem.mem[3][(3*`MATRIX_MEM_DATA_LENGTH)+31:3*`MATRIX_MEM_DATA_LENGTH] = 32'd4;
	alphaTensor_test.dmem.mem[3][(4*`MATRIX_MEM_DATA_LENGTH)+31:4*`MATRIX_MEM_DATA_LENGTH] = 32'd5;
	alphaTensor_test.dmem.mem[3][(5*`MATRIX_MEM_DATA_LENGTH)+31:5*`MATRIX_MEM_DATA_LENGTH] = 32'd6;
	alphaTensor_test.dmem.mem[3][(6*`MATRIX_MEM_DATA_LENGTH)+31:6*`MATRIX_MEM_DATA_LENGTH] = 32'd7;
	alphaTensor_test.dmem.mem[3][(7*`MATRIX_MEM_DATA_LENGTH)+31:7*`MATRIX_MEM_DATA_LENGTH] = 32'd8;
	alphaTensor_test.dmem.mem[3][(8*`MATRIX_MEM_DATA_LENGTH)+31:8*`MATRIX_MEM_DATA_LENGTH] = 32'd9;
	alphaTensor_test.dmem.mem[3][(9*`MATRIX_MEM_DATA_LENGTH)+31:9*`MATRIX_MEM_DATA_LENGTH] = 32'd10;
	alphaTensor_test.dmem.mem[3][(10*`MATRIX_MEM_DATA_LENGTH)+31:10*`MATRIX_MEM_DATA_LENGTH] = 32'd11;
	alphaTensor_test.dmem.mem[3][(11*`MATRIX_MEM_DATA_LENGTH)+31:11*`MATRIX_MEM_DATA_LENGTH] = 32'd12;
	alphaTensor_test.dmem.mem[3][(12*`MATRIX_MEM_DATA_LENGTH)+31:12*`MATRIX_MEM_DATA_LENGTH] = 32'd13;
	alphaTensor_test.dmem.mem[3][(13*`MATRIX_MEM_DATA_LENGTH)+31:13*`MATRIX_MEM_DATA_LENGTH] = 32'd14;
	alphaTensor_test.dmem.mem[3][(14*`MATRIX_MEM_DATA_LENGTH)+31:14*`MATRIX_MEM_DATA_LENGTH] = 32'd15;
	alphaTensor_test.dmem.mem[3][(15*`MATRIX_MEM_DATA_LENGTH)+31:15*`MATRIX_MEM_DATA_LENGTH] = 32'd16;

	alphaTensor_test.dmem.mem[2][(0*`MATRIX_MEM_DATA_LENGTH)+31:0*`MATRIX_MEM_DATA_LENGTH] = 32'd3;
	alphaTensor_test.dmem.mem[2][(1*`MATRIX_MEM_DATA_LENGTH)+31:1*`MATRIX_MEM_DATA_LENGTH] = 32'd9;
	alphaTensor_test.dmem.mem[2][(2*`MATRIX_MEM_DATA_LENGTH)+31:2*`MATRIX_MEM_DATA_LENGTH] = 32'd8;
	alphaTensor_test.dmem.mem[2][(3*`MATRIX_MEM_DATA_LENGTH)+31:3*`MATRIX_MEM_DATA_LENGTH] = 32'd1;
	alphaTensor_test.dmem.mem[2][(4*`MATRIX_MEM_DATA_LENGTH)+31:4*`MATRIX_MEM_DATA_LENGTH] = 32'd5;
	alphaTensor_test.dmem.mem[2][(5*`MATRIX_MEM_DATA_LENGTH)+31:5*`MATRIX_MEM_DATA_LENGTH] = 32'd6;
	alphaTensor_test.dmem.mem[2][(6*`MATRIX_MEM_DATA_LENGTH)+31:6*`MATRIX_MEM_DATA_LENGTH] = 32'd9;
	alphaTensor_test.dmem.mem[2][(7*`MATRIX_MEM_DATA_LENGTH)+31:7*`MATRIX_MEM_DATA_LENGTH] = 32'd1;
	alphaTensor_test.dmem.mem[2][(8*`MATRIX_MEM_DATA_LENGTH)+31:8*`MATRIX_MEM_DATA_LENGTH] = 32'd33;
	alphaTensor_test.dmem.mem[2][(9*`MATRIX_MEM_DATA_LENGTH)+31:9*`MATRIX_MEM_DATA_LENGTH] = 32'd41;
	alphaTensor_test.dmem.mem[2][(10*`MATRIX_MEM_DATA_LENGTH)+31:10*`MATRIX_MEM_DATA_LENGTH] = 32'd6161;
	alphaTensor_test.dmem.mem[2][(11*`MATRIX_MEM_DATA_LENGTH)+31:11*`MATRIX_MEM_DATA_LENGTH] = 32'd3434;
	alphaTensor_test.dmem.mem[2][(12*`MATRIX_MEM_DATA_LENGTH)+31:12*`MATRIX_MEM_DATA_LENGTH] = 32'd32535;
	alphaTensor_test.dmem.mem[2][(13*`MATRIX_MEM_DATA_LENGTH)+31:13*`MATRIX_MEM_DATA_LENGTH] = 32'd12313;
	alphaTensor_test.dmem.mem[2][(14*`MATRIX_MEM_DATA_LENGTH)+31:14*`MATRIX_MEM_DATA_LENGTH] = 32'd124124;
	alphaTensor_test.dmem.mem[2][(15*`MATRIX_MEM_DATA_LENGTH)+31:15*`MATRIX_MEM_DATA_LENGTH] = 32'd46456;
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
    //initialization
    #`FULL_CLOCK_CYCLE;
    idu_alphaTensor_matrix_mem_rd_idx  	<=   'h0;
    idu_alphaTensor_matrix_mem_rs1_idx  <=   'h0;
    idu_alphaTensor_matrix_mem_rs2_idx  <=   'h0;
    idu_alphaTensor_matrix_mul_vld  	<=   'b0;
    iex_alphaTensor_bru_vld_0		<=   'b0;
    iex_alphaTensor_bru_flush_0		<=   'b0;

    //mul invld, dmem read test

    //mul vld 
    #`FULL_CLOCK_CYCLE;
    idu_alphaTensor_matrix_mem_rd_idx  	<=   'h1;
    idu_alphaTensor_matrix_mem_rs1_idx  <=   'h2;
    idu_alphaTensor_matrix_mem_rs2_idx  <=   'h3;
    idu_alphaTensor_matrix_mul_vld  	<=   'b1;
    iex_alphaTensor_bru_vld_0		<=   'b0;
    iex_alphaTensor_bru_flush_0		<=   'b0;
    #`FULL_CLOCK_CYCLE;
    idu_alphaTensor_matrix_mem_rd_idx  	<=   'h0;
    idu_alphaTensor_matrix_mem_rs1_idx  <=   'h0;
    idu_alphaTensor_matrix_mem_rs2_idx  <=   'h0;
    idu_alphaTensor_matrix_mul_vld  	<=   'b0;
    iex_alphaTensor_bru_vld_0		<=   'b0;
    iex_alphaTensor_bru_flush_0		<=   'b0;
    //mul vld and bru flush

//
 


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
