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

	reg [`DATA_WIDTH-1:0] rf_idu_rs1_data;
	reg [`DATA_WIDTH-1:0] rf_idu_rs2_data;
	reg [`DATA_WIDTH-1:0] iex_idu_byp_data [`SUPER_SCALAR_NUM-1:0];
	reg [`DATA_WIDTH-1:0] lsu_idu_byp_data [`SUPER_SCALAR_NUM-1:0];
	reg [`DATA_WIDTH-1:0] rf_idu_byp_data [`SUPER_SCALAR_NUM-1:0];
	reg [`RF_DEPTH_BIT-1:0] iex_idu_byp_rd [`SUPER_SCALAR_NUM-1:0];
	reg iex_idu_rd_vld [`SUPER_SCALAR_NUM-1:0];
	reg iex_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0];
	reg iex_idu_is_load [`SUPER_SCALAR_NUM-1:0];
	reg [`RF_DEPTH_BIT-1:0] lsu_idu_byp_rd [`SUPER_SCALAR_NUM-1:0];
	reg lsu_idu_rd_vld [`SUPER_SCALAR_NUM-1:0];
	reg lsu_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0];
	reg lsu_idu_is_load [`SUPER_SCALAR_NUM-1:0];
	reg [`RF_DEPTH_BIT-1:0] rf_idu_byp_rd [`SUPER_SCALAR_NUM-1:0];
	reg rf_idu_rd_vld [`SUPER_SCALAR_NUM-1:0];
	reg rf_idu_pipe_vld [`SUPER_SCALAR_NUM-1:0];
	reg [`RF_DEPTH_BIT-1:0] idu_rf_rs1_idx;
	reg [`RF_DEPTH_BIT-1:0] idu_rf_rs2_idx;
	reg inst_rs1_idx_vld;
	reg inst_rs2_idx_vld;
	wire [`DATA_WIDTH-1:0] idu_iex_rs1_data;
	wire [`DATA_WIDTH-1:0] idu_iex_rs2_data;
	wire idu_dispatcher_stall_vld;
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_idu_bypassMUX bypassMUX_test (

	.rf_idu_rs1_data			(rf_idu_rs1_data),
	.rf_idu_rs2_data			(rf_idu_rs2_data),
	.iex_idu_byp_data			(iex_idu_byp_data),
	.lsu_idu_byp_data			(lsu_idu_byp_data),
	.rf_idu_byp_data			(rf_idu_byp_data),
	.iex_idu_byp_rd				(iex_idu_byp_rd),
	.iex_idu_rd_vld				(iex_idu_rd_vld),
	.iex_idu_pipe_vld			(iex_idu_pipe_vld),
	.iex_idu_is_load			(iex_idu_is_load),
	.lsu_idu_byp_rd				(lsu_idu_byp_rd),
	.lsu_idu_rd_vld				(lsu_idu_rd_vld),
	.lsu_idu_pipe_vld			(lsu_idu_pipe_vld),
	.lsu_idu_is_load			(lsu_idu_is_load),
	.rf_idu_byp_rd				(rf_idu_byp_rd),
	.rf_idu_rd_vld				(rf_idu_rd_vld),
	.rf_idu_pipe_vld			(rf_idu_pipe_vld),
	.inst_rs1_idx				(idu_rf_rs1_idx),
	.inst_rs2_idx				(idu_rf_rs2_idx),
	.inst_rs1_idx_vld			(inst_rs1_idx_vld),
	.inst_rs2_idx_vld			(inst_rs2_idx_vld),
	.idu_iex_rs1_data			(idu_iex_rs1_data),
	.idu_iex_rs2_data			(idu_iex_rs2_data),
	.idu_dispatcher_stall_vld	(idu_dispatcher_stall_vld)

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
    //ALL rd same, pick ALU 2
    #`FULL_CLOCK_CYCLE;
    rf_idu_rs1_data	    <= 32'h1111_1111;
    rf_idu_rs2_data     <= 32'h2222_2222;
    iex_idu_byp_data[0]	<= 32'hAAAA_AAAA;
    iex_idu_byp_data[1]	<= 32'hBBBB_BBBB;
    lsu_idu_byp_data[0]	<= 32'hCCCC_CCCC;
    lsu_idu_byp_data[1]	<= 32'hDDDD_DDDD;
    rf_idu_byp_data[0]	<= 32'hEEEE_EEEE;
    rf_idu_byp_data[1]	<= 32'hFFFF_FFFF;

    idu_rf_rs1_idx    	<= 5'h3;
    idu_rf_rs2_idx    	<= 5'h3;
    
    iex_idu_byp_rd[0]	<= 5'h3;
    iex_idu_byp_rd[1]	<= 5'h3;

    lsu_idu_byp_rd[0]	<= 5'h3;
    lsu_idu_byp_rd[1]	<= 5'h3;

    rf_idu_byp_rd[0]	<= 5'h3;
    rf_idu_byp_rd[1]	<= 5'h3;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b1;

    iex_idu_rd_vld[0]	<= 1'b1;
    iex_idu_rd_vld[1]	<= 1'b1;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b0;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b1;
    lsu_idu_is_load[0]	<= 1'b0;
    lsu_idu_is_load[1]	<= 1'b0;

    rf_idu_rd_vld[0]	<= 1'b1;
    rf_idu_rd_vld[1]	<= 1'b1;
    rf_idu_pipe_vld[0]	<= 1'b1;
    rf_idu_pipe_vld[1]	<= 1'b1;

    //LOAD instruction: rs1 == rd in LSU, stall
    //ALU rd invalid, ignore bypass
    //RS2 bypass RF data
    #`FULL_CLOCK_CYCLE;
    idu_rf_rs1_idx    	<= 5'h3;
    idu_rf_rs2_idx	<= 5'h4;
    
    iex_idu_byp_rd[0]	<= 5'h3;
    iex_idu_byp_rd[1]	<= 5'h3;

    lsu_idu_byp_rd[0]	<= 5'h3;
    lsu_idu_byp_rd[1]	<= 5'h3;

    rf_idu_byp_rd[0]	<= 5'h3;
    rf_idu_byp_rd[1]	<= 5'h4;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b1;

    iex_idu_rd_vld[0]	<= 1'b0;
    iex_idu_rd_vld[1]	<= 1'b0;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b0;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b1;
    lsu_idu_is_load[0]	<= 1'b0;
    lsu_idu_is_load[1]	<= 1'b1;

    rf_idu_rd_vld[0]	<= 1'b1;
    rf_idu_rd_vld[1]	<= 1'b1;
    rf_idu_pipe_vld[0]	<= 1'b1;
    rf_idu_pipe_vld[1]	<= 1'b1;
    //LOAD instruction: rs1 != rd in LSU, ignore
    //LOAD instruction: rs2 == rd but pipe invalid, ignore
    #`FULL_CLOCK_CYCLE;    
    iex_idu_byp_rd[0]	<= 5'h5;
    iex_idu_byp_rd[1]	<= 5'h4;

    lsu_idu_byp_rd[0]	<= 5'h6;
    lsu_idu_byp_rd[1]	<= 5'h4;

    rf_idu_byp_rd[0]	<= 5'h3;
    rf_idu_byp_rd[1]	<= 5'h4;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b1;

    iex_idu_rd_vld[0]	<= 1'b0;
    iex_idu_rd_vld[1]	<= 1'b0;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b0;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b0;
    lsu_idu_is_load[0]	<= 1'b1;
    lsu_idu_is_load[1]	<= 1'b1;

    rf_idu_rd_vld[0]	<= 1'b0;
    rf_idu_rd_vld[1]	<= 1'b1;
    rf_idu_pipe_vld[0]	<= 1'b1;
    rf_idu_pipe_vld[1]	<= 1'b0;
    //LOAD instruction: rs1 == rd in LSU, bypass rs1 == rd in ALU, bypass and ignore stall
    #`FULL_CLOCK_CYCLE;
    iex_idu_byp_rd[0]	<= 5'h3;
    iex_idu_byp_rd[1]	<= 5'h3;

    lsu_idu_byp_rd[0]	<= 5'h3;
    lsu_idu_byp_rd[1]	<= 5'h3;

    rf_idu_byp_rd[0]	<= 5'h3;
    rf_idu_byp_rd[1]	<= 5'h4;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b1;

    iex_idu_rd_vld[0]	<= 1'b1;
    iex_idu_rd_vld[1]	<= 1'b1;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b0;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b1;
    lsu_idu_is_load[0]	<= 1'b1;
    lsu_idu_is_load[1]	<= 1'b0;

    rf_idu_rd_vld[0]	<= 1'b0;
    rf_idu_rd_vld[1]	<= 1'b1;
    rf_idu_pipe_vld[0]	<= 1'b1;
    rf_idu_pipe_vld[1]	<= 1'b0;
    //LOAD instruction: rs1 == rd in LSU, stall rs1 == rd in ALU
    #`FULL_CLOCK_CYCLE;
    iex_idu_byp_rd[0]	<= 5'h3;
    iex_idu_byp_rd[1]	<= 5'h3;

    lsu_idu_byp_rd[0]	<= 5'h3;
    lsu_idu_byp_rd[1]	<= 5'h3;

    rf_idu_byp_rd[0]	<= 5'h3;
    rf_idu_byp_rd[1]	<= 5'h4;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b1;

    iex_idu_rd_vld[0]	<= 1'b1;
    iex_idu_rd_vld[1]	<= 1'b1;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b1;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b1;
    lsu_idu_is_load[0]	<= 1'b1;
    lsu_idu_is_load[1]	<= 1'b0;

    rf_idu_rd_vld[0]	<= 1'b0;
    rf_idu_rd_vld[1]	<= 1'b1;
    rf_idu_pipe_vld[0]	<= 1'b1;
    rf_idu_pipe_vld[1]	<= 1'b0;
    //ALU 0,1 rd == rs1, pick ALU 1
    //rs2 invalid
    #`FULL_CLOCK_CYCLE;
    iex_idu_byp_rd[0]	<= 5'h3;
    iex_idu_byp_rd[1]	<= 5'h3;

    lsu_idu_byp_rd[0]	<= 5'h4;
    lsu_idu_byp_rd[1]	<= 5'h4;

    rf_idu_byp_rd[0]	<= 5'h8;
    rf_idu_byp_rd[1]	<= 5'h9;

    inst_rs1_idx_vld	<= 1'b1;
    inst_rs2_idx_vld    <= 1'b0;

    iex_idu_rd_vld[0]	<= 1'b1;
    iex_idu_rd_vld[1]	<= 1'b1;
    iex_idu_pipe_vld[0]	<= 1'b1;
    iex_idu_pipe_vld[1]	<= 1'b1;
    iex_idu_is_load[0]	<= 1'b0;
    iex_idu_is_load[1]	<= 1'b0;

    lsu_idu_rd_vld[0]	<= 1'b1;
    lsu_idu_rd_vld[1]	<= 1'b1;
    lsu_idu_pipe_vld[0]	<= 1'b1;
    lsu_idu_pipe_vld[1]	<= 1'b1;
    lsu_idu_is_load[0]	<= 1'b0;
    lsu_idu_is_load[1]	<= 1'b1;

    rf_idu_rd_vld[0]	<= 1'b0;
    rf_idu_rd_vld[1]	<= 1'b0;
    rf_idu_pipe_vld[0]	<= 1'b0;
    rf_idu_pipe_vld[1]	<= 1'b0;

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
