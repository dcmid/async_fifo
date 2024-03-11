MODULE := async_fifo
WORK_DIR := work

$(WORK_DIR)/runsim: hdl/$(MODULE).sv sim/$(MODULE)_tb.sv | $(WORK_DIR)
	cd sim; iverilog -g2012 -o ../$(WORK_DIR)/runsim $(MODULE)_tb.sv
	cd $(WORK_DIR); vvp runsim
	
$(WORK_DIR):
	mkdir $(WORK_DIR)

clean:
	rm -rf ./$(WORK_DIR)/*

PHONY: clean