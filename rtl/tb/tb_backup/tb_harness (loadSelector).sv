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
	reg lb;
	reg lh;
	reg lw;
    reg unsigned_data;
	reg [`DATA_MEM_WIDTH_BIT-1:0] addr;
	reg [`DATA_MEM_WIDTH-1:0] rd_data;
	wire [`DATA_WIDTH-1:0] selected_dmem_data;

//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_lsu_load_data_selector load_data_selector_test(
	.lb					(lb),
	.lh					(lh),
	.lw					(lw),
	.unsigned_data		(unsigned_data),
	.addr				(addr[`DATA_MEM_WIDTH_BIT-1:0]),
	.rd_data			(rd_data),
	.selected_dmem_data	(selected_dmem_data)
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
    //lb
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    rd_data             <=  128'h1122_3344_5566_7788_99AA_BBCC_DDEE_FF00;
    unsigned_data       <=  'b0;    
    lb                  <=  'b1;
    lh                  <=  'b0;
    lw                  <=  'b0;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //lh
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    rd_data             <=  128'h1122_3344_5566_7788_99AA_BBCC_DDEE_FF00;
    unsigned_data       <=  'b0;    
    lb                  <=  'b0;
    lh                  <=  'b1;
    lw                  <=  'b0;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //lw
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    rd_data             <=  128'h1122_3344_5566_7788_99AA_BBCC_DDEE_FF00;
    unsigned_data       <=  'b0;    
    lb                  <=  'b0;
    lh                  <=  'b0;
    lw                  <=  'b1;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //lbu
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    rd_data             <=  128'h1122_3344_5566_7788_99AA_BBCC_DDEE_FF00;
    unsigned_data       <=  'b1;    
    lb                  <=  'b1;
    lh                  <=  'b0;
    lw                  <=  'b0;
    for (int i=0; i<16;i++) begin
        #`FULL_CLOCK_CYCLE;
        addr   	<= i;
    end
    //lhu
    #`FULL_CLOCK_CYCLE;
    addr                <=  'h0;
    rd_data             <=  128'h1122_3344_5566_7788_99AA_BBCC_DDEE_FF00;
    unsigned_data       <=  'b1;    
    lb                  <=  'b0;
    lh                  <=  'b1;
    lw                  <=  'b0;
    for (int i=0; i<16;i++) begin
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
