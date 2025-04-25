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
	//control flag
	reg sb;
	reg sh;
	reg sw;
	//address
	reg [`DATA_MEM_WIDTH_BIT-1:0] addr;
	//original data from Dmem
	reg [`DATA_WIDTH-1:0] wr_data;
	//selecteddata output
	wire [`DATA_MEM_WIDTH-1:0] extended_wr_data;
	wire [`DATA_MEM_WIDTH-1:0] extended_wen;
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_lsu_store_data_extensor store_data_extensor(
	.sb					(sb),
	.sh					(sh),
	.sw					(sw),
	.addr				(addr[`DATA_MEM_WIDTH_BIT-1:0]),
	.wr_data			(wr_data),
	.extended_wr_data	(extended_wr_data),
	.extended_wen		(extended_wen)
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
    for(int i=0; i<`DATA_MEM_DEPTH; i++) begin
		//dmem_test.mem[i] = i;
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
    //sb
    #`FULL_CLOCK_CYCLE;
    wr_data             <=  32'h1234_5678;
    sb                  <=  'b1;
    sh                  <=  'b0;
    sw                  <=  'b0;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //sh
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    #`FULL_CLOCK_CYCLE;
    wr_data             <=  32'h1234_5678;
    sb                  <=  'b0;
    sh                  <=  'b1;
    sw                  <=  'b0;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //sw
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    #`FULL_CLOCK_CYCLE;
    wr_data             <=  32'h1234_5678;
    sb                  <=  'b0;
    sh                  <=  'b0;
    sw                  <=  'b1;
    for (int i=0; i<16; i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #10000   //run time before calling finish, need to be long enough for all simulation
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
