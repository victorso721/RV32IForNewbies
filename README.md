# RV32IForNewbies
Project description: 
A simplified in-order superscalar processor Verilog implementation for new learners.

ISA support:
RV32I

File structure:
Filelist: storing filelist of RTL file created
RTL: all verilog RTL and testbench file created in project
sim: MAKE script for compilation, simulation and waveform checking

Environment setup:
Tool requirement: gcc, g++, VCS, Verdi (Modifiy MAKE script in sim if other software is used)
1. "make cmp" for compilation
2. "make run" for simulation
3. "make verdi" for Verdi waveform checking
