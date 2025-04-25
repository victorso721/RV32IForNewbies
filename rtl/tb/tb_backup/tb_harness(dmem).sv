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
	reg [`DATA_MEM_DEPTH_BIT-1:0] lsu_dmem_addr;
	reg dmem_ren;
	reg [`DATA_MEM_WIDTH-1:0] lsu_dmem_extended_wen;
	reg [`DATA_MEM_WIDTH-1:0] lsu_dmem_extended_wr_data;
	wire [`DATA_MEM_WIDTH-1:0] dmem_lsu_rd_data;
//----------------------end----------------------//

//------------Module under test------------------//
/*submodule*/ /*module_name*/
u_DMem_512X128 dmem_test(
	.clk		(clk),
	.addr		(lsu_dmem_addr),
	.ren		(dmem_ren),
	.wen		(lsu_dmem_extended_wen),
	.wr_data	(lsu_dmem_extended_wr_data),
	.rd_data	(dmem_lsu_rd_data)
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
		dmem_test.mem[i] = i;
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
    //dmem read
    for (int i=0; i<`DATA_MEM_DEPTH; i++) begin
        #`FULL_CLOCK_CYCLE;
        dmem_ren	        <= 1'b1;
        lsu_dmem_addr   	<= i;
    end
    //dmem stop reading
    #`FULL_CLOCK_CYCLE;
    dmem_ren	        <= 1'b0;
    lsu_dmem_addr   	<= 9'h0;
    //dmem write
    #`FULL_CLOCK_CYCLE;
    lsu_dmem_addr   	        <= 9'd120;
    lsu_dmem_extended_wen       <= 128'hF0F0_FFFF_0F0F_0000_FF00_F00F_0FF0_00FF;
    lsu_dmem_extended_wr_data   <= 128'h1111_2222_3333_4444_5555_6666_7777_8888;

end
//----------------------end----------------------//

//-------------------Wave Dumping----------------//
`ifdef DUMP_FSDB
    initial begin
        #20000   //run time before calling finish, need to be long enough for all simulation
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
