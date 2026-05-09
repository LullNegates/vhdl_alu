# Implementation Plan — vhdl_alu (G5)

## Design goal: Maximale Nebenläufigkeit

All ALU operations are computed simultaneously as concurrent signal assignments (dataflow style).
A `with opcode select` muxes the result. No `process` blocks anywhere in the RTL — this is the
purest expression of concurrent VHDL and maps directly to parallel combinational logic in hardware.

---

## Phase 0 — Specs

- [x] Confirmed G5 device: Spartan3E 500
- [x] Confirmed G5 Entwurfsziel: Maximale Nebenläufigkeit
- [x] ALU 1 spec confirmed (8-bit, 3-bit opcode, 8 ops, carry output)
- [ ] **ALU 2 spec: confirm exact port widths, operation set, and required flags from G5 assignment sheet**

---

## Phase 1 — ALU 1 ✓ COMPLETE

### 1a. `alu1/src/alu1.vhd`
- [x] Port interface: a, b (8-bit), opcode (3-bit), result (8-bit), carry (1-bit)
- [x] All 8 operations as concurrent intermediate signals (9-bit res_add/res_sub for carry)
- [x] `with opcode select` mux for result and carry
- [x] Zero processes — pure concurrent/dataflow architecture
- [x] `ieee.numeric_std` for arithmetic

### 1b. `alu1/src/alu1_tb.vhd`
- [x] 10 test vectors — every opcode + edge cases (carry, underflow)
- [x] `wait for 20 ns` between stimulus changes
- [x] `assert` + `severity failure` on every expected output
- [x] GHDL result: `@200ns: Simulation complete -- all assertions passed`

### 1c. `alu1/Makefile`
- [x] GHDL std=08, compile order enforced, `make simulate` / `make view`

---

## Phase 2 — ALU 2

### Design approach (confirmed: same Maximale Nebenläufigkeit style)

ALU 2 extends ALU 1 with a **full 4-flag status register** computed as concurrent
signal assignments. The operation datapath is identical to ALU 1; the only additions
are the four output flags and an internal `result_i` signal to allow flags to read
the mux output without a feedback loop.

```
a, b ──┬──► [ADD 9-bit]────┐
       ├──► [SUB 9-bit]────┤
       ├──► [AND]──────────┤
       ├──► [OR] ──────────┼──► with opcode select ──► result_i ──► result
       ├──► [XOR]──────────┤                                │
       ├──► [NOT]──────────┤                                ├──► Z = (result_i = 0)
       ├──► [SHL]──────────┤                                ├──► N = result_i(7)
       └──► [SHR]──────────┘          C ◄── carry mux ──── ┘
                                      V ◄── overflow logic (concurrent)
opcode ──────────────────────────────────────────────────► selects
```

### Flag definitions

| Flag | Port | Computation | Notes |
|------|------|-------------|-------|
| C — Carry    | `c : out std_logic` | `res_add(8)` for ADD, `res_sub(8)` for SUB, `'0'` otherwise | `with opcode select` |
| Z — Zero     | `z : out std_logic` | `'1' when result_i = x"00" else '0'`                       | conditional concurrent |
| N — Negative | `n : out std_logic` | `result_i(7)`                                               | simple concurrent slice |
| V — Overflow | `v : out std_logic` | Signed overflow from sign bits of a, b, result_i            | `with opcode select` |

### Signed overflow (V) logic — fully concurrent

```
ADD:  V = (not a(7) and not b(7) and result_i(7))
          or (a(7) and b(7) and not result_i(7))

SUB:  V = (not a(7) and b(7) and result_i(7))
          or (a(7) and not b(7) and not result_i(7))

all other ops: V = '0'
```

This is expressed as a single `with opcode select` statement — no process.

### Port interface (assumed — CONFIRM from G5 sheet)

| Port    | Dir | Width | Description                          |
|---------|-----|-------|--------------------------------------|
| `a`     | in  | 8     | Operand A                            |
| `b`     | in  | 8     | Operand B                            |
| `opcode`| in  | 3     | Selects operation                    |
| `result`| out | 8     | Computed result                      |
| `c`     | out | 1     | Carry / borrow                       |
| `z`     | out | 1     | Zero flag                            |
| `n`     | out | 1     | Negative flag (sign bit of result)   |
| `v`     | out | 1     | Signed overflow flag                 |

### Operation set (assumed — same as ALU 1, CONFIRM from G5 sheet)

| Opcode | Op  | Expression              |
|--------|-----|-------------------------|
| `000`  | ADD | `a + b`                 |
| `001`  | SUB | `a - b`                 |
| `010`  | AND | `a and b`               |
| `011`  | OR  | `a or b`                |
| `100`  | XOR | `a xor b`               |
| `101`  | NOT | `not a`                 |
| `110`  | SHL | logical shift left 1    |
| `111`  | SHR | logical shift right 1   |

### 2a. `alu2/src/alu2.vhd`

- [ ] Declare ports: a, b (8-bit), opcode (3-bit), result (8-bit), c, z, n, v (1-bit each)
- [ ] Internal signals: res_add/res_sub (9-bit), res_and/or/xor/not/shl/shr (8-bit), result_i (8-bit)
- [ ] Concurrent assignments for all 8 ops (identical pattern to alu1)
- [ ] `with opcode select result_i <=` mux
- [ ] `result <= result_i`
- [ ] `with opcode select c <=` carry mux
- [ ] `z <= '1' when result_i = x"00" else '0'`
- [ ] `n <= result_i(7)`
- [ ] `with opcode select v <=` overflow logic

### 2b. `alu2/src/alu2_tb.vhd`

Test vectors must cover:

| Category          | Vectors needed                                      |
|-------------------|-----------------------------------------------------|
| ADD normal        | result, C=0, Z=0, N=0, V=0                         |
| ADD carry         | 0xFF+0x01 → C=1, Z=1, N=0, V=0                    |
| ADD signed OVF    | 0x7F+0x01 → C=0, Z=0, N=1, V=1                    |
| SUB normal        | result, C=0                                         |
| SUB borrow        | 0x00-0x01 → C=1, N=1                               |
| SUB signed OVF    | 0x80-0x01 → V=1                                    |
| AND               | Z=0 and Z=1 cases                                  |
| OR / XOR / NOT    | basic correctness + N flag check                   |
| SHL / SHR         | confirm N flag and Z flag propagate correctly       |
| Zero result       | any op that gives 0x00 → Z=1                       |

Minimum: ~14 test vectors. `SETTLE = 20 ns`, same pattern as alu1_tb.

### 2c. `alu2/Makefile`

Mirror of `alu1/Makefile` — change entity name from `alu1` to `alu2` and wave filename.

---

## Phase 3 — Submission prep

- [ ] Both testbenches pass GHDL with zero failures
- [ ] ISim screenshots taken for both ALUs (copy to VMShare)
- [ ] README status table updated
- [ ] Git commit + push

---

## Architecture rationale: why pure concurrent for "Maximale Nebenläufigkeit"

A `process` with a `case` statement is still concurrent at the VHDL simulator level but
synthesises to a priority MUX chain. A `with/select` without intermediate signals computes
all branches before selecting — but declaring each operation as a named intermediate signal
makes the parallelism explicit and readable, and forces the synthesiser to implement each
path as independent logic with no data dependency between them. This is the correct
interpretation of "maximale Nebenläufigkeit" in an FHDW context.

The `result_i` signal in ALU 2 (internal alias for the mux output) is necessary so that
Z, N, and V flags can read the selected result without creating a combinational feedback
loop on the `result` output port directly.
