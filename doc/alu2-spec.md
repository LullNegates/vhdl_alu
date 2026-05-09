# ALU 2 — G5 Specification (Teilaufgabe 2)

> Fill from the P3-a assignment sheet before writing any VHDL.

---

## Port interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `a` | in | **[G5: TBD]** bits | Operand A |
| `b` | in | **[G5: TBD]** bits | Operand B |
| `opcode` | in | **[G5: TBD]** bits | Selects operation |
| `result` | out | **[G5: TBD]** bits | Computed result |
| `carry_out` | out | 1 bit | Include only if spec requires |

---

## Operation table

| Opcode (binary) | Operation | Expression |
|---|---|---|
| TBD | | |

---

## Architecture decision

- **Style:** Combinational (`with opcode select`) — unless spec requires clocked outputs
- **Overflow/carry:** TBD once spec confirmed

---

## Test vectors (for testbench)

| a | b | opcode | Expected result | Notes |
|---|---|---|---|---|
| | | | | Fill after operations confirmed |
