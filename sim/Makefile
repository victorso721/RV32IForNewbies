all: com_fsdb run verdi
#------------------------------------
cmp:
	vcs \
	-f ../filelist/tb_filelist.f \
	-timescale=1ns/1ps \
	-full64 \
	+v2k \
	-sverilog \
	+lint=TFIPC-L\
	-Mupdate \
	+define+DUMP_FSDB \
	-debug_acc+all -debug_region+cell+encrypt \
	|tee compile.log
#-------------------------------------
run:
	./simv |tee sim.log
#-------------------------------------
verdi:
	verdi \
	-f ../filelist/tb_filelist.f \
	&
#--------------------------------------
clean:
	rm -rf csrc DVEfiles novas* *.log simv* *fsdb* ucli.key *.vpd verdilog
