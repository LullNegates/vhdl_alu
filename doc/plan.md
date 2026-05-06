# Implementation Plan — vhdl_alu (G5)

## Design goal: Maximale Nebenläufigkeit

All ALU operations are computed simultaneously as concurrent signal assignments (dataflow style). A `with opcode select` muxes the result. No process blocks anywhere in the RTL — this is the purest expression of concurrent VHDL and maps directly to parallel combinational logic in hardware.

---

## Phase 0 — Specs (partially complete)

- [x] Confirmed G5 device: Spartan3E 500
- [x] Confirmed G5 Entwurfsziel: Maximale Nebenläufigkeit
- [ ] Confirm exact bit widths and operation set from Teilaufgabe 1 table (currently using 8-bit / 3-bit opcode / 8 ops as placeholder)
- [ ] Fill in `doc/alu2-spec.md` once Teilaufgabe 2 requirements are available

---

## Phase 1 — ALU 1 (active)

### 1a. Entity + architecture (`alu1/src/alu1.vhd`)

- [x] Port interface declared (a, b: 8-bit; opcode: 3-bit; result: 8-bit; carry: 1-bit)
- [x] All 8 operations as concurrent intermediate signals
- [x] `with opcode select` mux for result and carry
- [x] Zero processes — pure concurrent/dataflow architecture
- [x] `ieee.numeric_std` for arithmetic (no `std_logic_arith`)

### 1b. Testbench (`alu1/src/alu1_tb.vhd`)

- [x] Instantiate `alu1` as DUT with named port map
- [x] 10 test vectors covering every opcode + edge cases (carry, underflow)
- [x] `wait for 20 ns` between stimulus changes (combinational settle time)
- [x] `assert` + `severity failure` on every expected output
- [x] `"Simulation complete — all assertions passed"` at end

### 1c. Makefile (`alu1/Makefile`)

- [x] GHDL std=08, compile order: alu1.vhd → alu1_tb.vhd → elaborate → simulate
- [x] `make simulate` → `make view` workflow matching stopwatch pattern

---

## Phase 2 — ALU 2

- [ ] Read Teilaufgabe 2 spec once available
- [ ] Fill `doc/alu2-spec.md`
- [ ] Implement `alu2/src/alu2.vhd` and `alu2_tb.vhd`
- [ ] Create `alu2/Makefile`

---

## Phase 3 — Submission prep

- [ ] Both testbenches pass GHDL with zero failures
- [ ] ISim screenshots taken for both ALUs
- [ ] README status table updated
- [ ] Git commit + push

---

## Architecture rationale: why pure concurrent for "Maximale Nebenläufigkeit"

A `process` with a `case` statement is still concurrent at the VHDL simulator level but synthesises to a priority MUX chain. A `with/select` without intermediate signals computes all branches before selecting — but declaring each operation as a named intermediate signal makes the parallelism explicit and readable, and forces the synthesiser to implement each path as independent logic with no data dependency between them. This is the correct interpretation of "maximale Nebenläufigkeit" in an FHDW context.
