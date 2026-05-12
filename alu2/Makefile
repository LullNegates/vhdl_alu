GHDL    := ghdl
STD     := --std=08
SIMDIR  := sim
TOP     := ASALU_structural_tb
WAVE    := $(SIMDIR)/alu2.ghw
SHARED  := ../shared/asalu_entity.vhd

.PHONY: all compile simulate view clean

all: simulate

compile:
	$(GHDL) -a $(STD) $(SHARED)
	$(GHDL) -a $(STD) src/alu2.vhd
	$(GHDL) -a $(STD) src/alu2_tb.vhd
	$(GHDL) -e $(STD) $(TOP)

simulate: compile
	mkdir -p $(SIMDIR)
	$(GHDL) -r $(STD) $(TOP) --wave=$(WAVE)

view: $(WAVE)
	gtkwave $(WAVE) &

clean:
	rm -rf *.cf e~$(TOP) $(SIMDIR)/*.ghw $(SIMDIR)/*.vcd
