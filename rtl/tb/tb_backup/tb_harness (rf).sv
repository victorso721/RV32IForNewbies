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

	//LSU input
	reg	[`PC_WIDTH-1:0]		lsu_rf_pc			[`SUPER_SCALAR_NUM-1:0];
	reg						lsu_rf_pipe_vld	[`SUPER_SCALAR_NUM-1:0];
	reg						lsu_rf_wen			[`SUPER_SCALAR_NUM-1:0];
	reg	[`RF_DEPTH_BIT-1:0]	lsu_rf_rd			[`SUPER_SCALAR_NUM-1:0]; 
	reg	[`DATA_WIDTH-1:0]	lsu_rf_wr_data		[`SUPER_SCALAR_NUM-1:0];

	//IDU input
	reg	[`RF_DEPTH_BIT-1:0]	idu_rf_rs1_idx		[`RF_READ_PORT_NUM-1:0];
	reg	[`RF_DEPTH_BIT-1:0]	idu_rf_rs2_idx		[`RF_READ_PORT_NUM-1:0];
	
	//IDU output
	wire	[`DATA_WIDTH-1:0]	rf_idu_rs1_data		[`RF_READ_PORT_NUM-1:0];
	wire	[`DATA_WIDTH-1:0]	rf_idu_rs2_data		[`RF_READ_PORT_NUM-1:0];
	wire	[`DATA_WIDTH-1:0]	rf_idu_byp_data		[`SUPER_SCALAR_NUM-1:0];
	wire						rf_idu_pipe_vld		[`SUPER_SCALAR_NUM-1:0];
	wire						rf_idu_rd_vld		[`SUPER_SCALAR_NUM-1:0];
	wire	[`RF_DEPTH_BIT-1:0]	rf_idu_rd			[`SUPER_SCALAR_NUM-1:0];
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_rf rf_test (
	.clk			(clk),
	.rst_n			(rst_n),
	.lsu_rf_pc		(lsu_rf_pc),
	.lsu_rf_pipe_vld	(lsu_rf_pipe_vld),
	.lsu_rf_wen		(lsu_rf_wen),			
	.lsu_rf_rd		(lsu_rf_rd),
	.lsu_rf_wr_data		(lsu_rf_wr_data),
	.idu_rf_rs1_idx		(idu_rf_rs1_idx),
	.idu_rf_rs2_idx		(idu_rf_rs2_idx),
	.rf_idu_rs1_data	(rf_idu_rs1_data),
	.rf_idu_rs2_data	(rf_idu_rs2_data),
	.rf_idu_byp_data	(rf_idu_byp_data),		
	.rf_idu_pipe_vld	(rf_idu_pipe_vld),		
	.rf_idu_rd_vld		(rf_idu_rd_vld),
	.rf_idu_rd		(rf_idu_rd)
	
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
		rf_test.rf_data_array[i] = i;
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
    //inst 0 write, inst 1 block by pipe vld
    #`FULL_CLOCK_CYCLE;
    lsu_rf_pc[0]	<= 32'hFFFF_FFFF;
    lsu_rf_pc[1]	<= 32'h1111_1111;
    lsu_rf_pipe_vld[0]	<= 1'b1;
    lsu_rf_pipe_vld[1]	<= 1'b0;
    lsu_rf_wen[0]	<= 1'b1;
    lsu_rf_wen[1]	<= 1'b1;
    lsu_rf_rd[0]	<= 5'd1;
    lsu_rf_rd[1]	<= 5'd2;
    lsu_rf_wr_data[0]	<= 32'd91;
    lsu_rf_wr_data[1]	<= 32'd132;
    idu_rf_rs1_idx[0]	<= 5'd1;
    idu_rf_rs1_idx[1]	<= 5'd2;
    idu_rf_rs2_idx[0]	<= 5'd18;
    idu_rf_rs2_idx[1]	<= 5'd31;
    //Both wen down
    #`FULL_CLOCK_CYCLE;
    lsu_rf_pc[0]	<= 32'hAAAA_AAAA;
    lsu_rf_pc[1]	<= 32'h2222_2222;
    lsu_rf_pipe_vld[0]	<= 1'b1;
    lsu_rf_pipe_vld[1]	<= 1'b1;
    lsu_rf_wen[0]	<= 1'b0;
    lsu_rf_wen[1]	<= 1'b0;
    lsu_rf_rd[0]	<= 5'd11;
    lsu_rf_rd[1]	<= 5'd21;
    lsu_rf_wr_data[0]	<= 32'd185;
    lsu_rf_wr_data[1]	<= 32'd2700;
    idu_rf_rs1_idx[0]	<= 5'd6;
    idu_rf_rs1_idx[1]	<= 5'd29;
    idu_rf_rs2_idx[0]	<= 5'd14;
    idu_rf_rs2_idx[1]	<= 5'd5;
    //Writing into same rd, inst1 overwrite inst0
    #`FULL_CLOCK_CYCLE;
    lsu_rf_pc[0]	<= 32'hBBBB_BBBB;
    lsu_rf_pc[1]	<= 32'h3333_3333;
    lsu_rf_pipe_vld[0]	<= 1'b1;
    lsu_rf_pipe_vld[1]	<= 1'b1;
    lsu_rf_wen[0]	<= 1'b1;
    lsu_rf_wen[1]	<= 1'b1;
    lsu_rf_rd[0]	<= 5'd7;
    lsu_rf_rd[1]	<= 5'd7;
    lsu_rf_wr_data[0]	<= 32'd999;
    lsu_rf_wr_data[1]	<= 32'd555;
    idu_rf_rs1_idx[0]	<= 5'd4;
    idu_rf_rs1_idx[1]	<= 5'd0;
    idu_rf_rs2_idx[0]	<= 5'd1;
    idu_rf_rs2_idx[1]	<= 5'd9;
    //Both wen up
    #`FULL_CLOCK_CYCLE;
    lsu_rf_pc[0]	<= 32'hcccc_cccc;
    lsu_rf_pc[1]	<= 32'h4444_4444;
    lsu_rf_pipe_vld[0]	<= 1'b1;
    lsu_rf_pipe_vld[1]	<= 1'b1;
    lsu_rf_wen[0]	<= 1'b1;
    lsu_rf_wen[1]	<= 1'b1;
    lsu_rf_rd[0]	<= 5'd27;
    lsu_rf_rd[1]	<= 5'd19;
    lsu_rf_wr_data[0]	<= 32'hFFFF_FFFF;
    lsu_rf_wr_data[1]	<= 32'h1111_1234;
    idu_rf_rs1_idx[0]	<= 5'd8;
    idu_rf_rs1_idx[1]	<= 5'd7;
    idu_rf_rs2_idx[0]	<= 5'd19;
    idu_rf_rs2_idx[1]	<= 5'd27;
    #`FULL_CLOCK_CYCLE;
    lsu_rf_pc[0]	<= 'b0;
    lsu_rf_pc[1]	<= 'b0;
    lsu_rf_pipe_vld[0]	<= 'b0;
    lsu_rf_pipe_vld[1]	<= 'b0;
    lsu_rf_wen[0]	<= 'b0;
    lsu_rf_wen[1]	<= 'b0;
    lsu_rf_rd[0]	<= 'b0;
    lsu_rf_rd[1]	<= 'b0;
    lsu_rf_wr_data[0]	<= 'b0;
    lsu_rf_wr_data[1]	<= 'b0;
    idu_rf_rs1_idx[0]	<= 'b0;
    idu_rf_rs1_idx[1]	<= 'b0;
    idu_rf_rs2_idx[0]	<= 'b0;
    idu_rf_rs2_idx[1]	<= 'b0;
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
