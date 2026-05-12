WORKDIR = work
GHDL    = ghdl
TOP     = ASALU_structural_v2_tb

# RAM.vhd excluded from GHDL check (UNISIM/RAMB4 = ISim only)
SRC_CHECK = \
	src/asalu_entity.vhd \
	src/add.vhd \
	src/subtract.vhd \
	src/add_lls.vhd \
	src/add_lls_lls.vhd \
	src/negate.vhd \
	src/sll.vhd \
	src/lrs.vhd \
	src/llr.vhd \
	src/lrr.vhd \
	src/mul.vhd \
	src/bit_nand.vhd \
	src/bit_xor.vhd \
	src/alu13.vhd \
	src/alu13_tb.vhd

# Full source list for ISE (includes RAM.vhd)
SRC_ISE = src/asalu_entity.vhd src/RAM.vhd src/add.vhd src/subtract.vhd \
          src/add_lls.vhd src/add_lls_lls.vhd src/negate.vhd src/sll.vhd \
          src/lrs.vhd src/llr.vhd src/lrr.vhd src/mul.vhd \
          src/bit_nand.vhd src/bit_xor.vhd src/alu13.vhd src/alu13_tb.vhd

.PHONY: all check sim clean

all: check

$(WORKDIR):
	mkdir -p $(WORKDIR)

# Syntax check (RAM.vhd excluded — UNISIM/RAMB4 requires ISim)
check: $(WORKDIR)
	$(GHDL) -a --workdir=$(WORKDIR) $(SRC_CHECK)
	@echo "Syntax check passed. Simulate in ISim (ISE 14.7)."

# Reminder: simulation requires ISim
sim:
	@echo "Simulation requires Xilinx ISim (ISE 14.7)."
	@echo "Load all src/*.vhd files into an ISE project and run ISim."
	@echo "Top-level configuration: cfg_structural_v2"

clean:
	rm -rf $(WORKDIR) $(TOP)
