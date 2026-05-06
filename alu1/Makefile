GHDL    := ghdl
STD     := --std=08
SIMDIR  := sim
TOP     := alu1_tb
WAVE    := $(SIMDIR)/alu1.ghw

SRCS := src/alu1.vhd \
        src/alu1_tb.vhd

.PHONY: all compile simulate view clean

all: simulate

compile: $(SRCS)
	$(GHDL) -a $(STD) src/alu1.vhd
	$(GHDL) -a $(STD) src/alu1_tb.vhd
	$(GHDL) -e $(STD) $(TOP)

simulate: compile
	mkdir -p $(SIMDIR)
	$(GHDL) -r $(STD) $(TOP) --wave=$(WAVE)

view: $(WAVE)
	gtkwave $(WAVE) &

clean:
	rm -rf *.cf e~$(TOP) $(SIMDIR)/*.ghw $(SIMDIR)/*.vcd
