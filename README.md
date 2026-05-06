# VHDL ALU — Projektaufgabe 3 (Gruppe G5)

Application-specific ALU project for the FHDW Hannover Digital Design module.  
Continuation of P2 (Stoppuhr-Controller). Two separate ALU designs, each with its own source, testbench, and Makefile.

---

## Repository Layout

```
vhdl_alu/
├── alu1/                   Teilaufgabe 1 — ALU 1
│   ├── src/
│   │   ├── alu1.vhd        ALU entity + architecture
│   │   └── alu1_tb.vhd     Testbench
│   ├── sim/                GHDL wave output (.ghw) — git-ignored
│   └── Makefile
│
├── alu2/                   Teilaufgabe 2 — ALU 2
│   ├── src/
│   │   ├── alu2.vhd        ALU entity + architecture
│   │   └── alu2_tb.vhd     Testbench
│   ├── sim/
│   └── Makefile
│
└── doc/
    ├── plan.md             Step-by-step implementation plan
    ├── alu1-spec.md        G5 specification for ALU 1
    └── alu2-spec.md        G5 specification for ALU 2
```

---

## Toolchain

| Tool | Purpose |
|---|---|
| GHDL (WSL2) | Compile + simulate `.vhd` files |
| GTKWave (WSL2) | Inspect `.ghw` waveform output |
| ISim (Xilinx ISE 14.7 VM) | Secondary simulation for submission screenshots |
| TerosHDL (VSCode) | Port viewer + syntax highlighting |

### WSL2 quick-start

```bash
# ALU 1
cd alu1
make simulate   # compile + run testbench
make view       # open GTKWave

# ALU 2
cd alu2
make simulate
make view
```

---

## Build targets (per ALU Makefile)

| Target | Action |
|---|---|
| `make all` | alias for `simulate` |
| `make compile` | analyse + elaborate only |
| `make simulate` | compile then run testbench, writes `.ghw` |
| `make view` | open GTKWave on latest `.ghw` |
| `make clean` | remove compiled artefacts and wave files |

---

## Implementation status

| Item | Status |
|---|---|
| Folder structure | Done |
| ALU 1 spec (`doc/alu1-spec.md`) | Done |
| ALU 2 spec (`doc/alu2-spec.md`) | Drafted — confirm G5 port widths + op set |
| `alu1.vhd` | Done — pure concurrent, 8 ops, carry output |
| `alu1_tb.vhd` | Done — 10 vectors, all pass GHDL |
| `alu2.vhd` | TODO |
| `alu2_tb.vhd` | TODO |
| ALU 1 GHDL simulation | Passing — `@200ns: Simulation complete -- all assertions passed` |
| ALU 2 GHDL simulation | TODO |
| ISim screenshots (both ALUs) | TODO |

---

## Group

**G5** — FHDW Hannover, Digital Design, SoSe 2026
