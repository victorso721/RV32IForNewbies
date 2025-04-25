#rtl files
#MacroFile
../rtl/top/define.v
#tb files
../rtl/tb/tb_harness.sv
#Core wrapper
../rtl/top/coreWrapper.v
#CSR
../rtl/csr/csr.v
#Memory
../rtl/mem/Dmem.v
../rtl/mem/Imem.v
#IFU
../rtl/ifu/2ff_synchronizer.v
../rtl/ifu/pc_generator.v
../rtl/ifu/ifu.v
#IDU
../rtl/idu/instBuffer.v
../rtl/idu/instDecode.v
../rtl/idu/bypassMUX.v
../rtl/idu/dispatcher.v
../rtl/idu/idu.v
../rtl/idu/iduWrapper.v
#IEX
../rtl/iex/adder.v
../rtl/iex/logicPlane.v
../rtl/iex/comparator.v
../rtl/iex/shifter.v
../rtl/iex/bru.v
../rtl/iex/alu.v
../rtl/iex/iexWrapper.v
#LSU
../rtl/lsu/storeDataExtensor.v
../rtl/lsu/loadDataSelector.v
../rtl/lsu/lsu.v
../rtl/lsu/lsuWrapper.v
#RF
../rtl/rf/rf.v
#AlphaTensor
../rtl/alphaTensor/preadder.v
../rtl/alphaTensor/postadder.v
../rtl/alphaTensor/multiplier.v
../rtl/alphaTensor/matrixMem.v
../rtl/alphaTensor/alphaTensor.v

