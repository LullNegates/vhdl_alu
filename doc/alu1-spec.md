# ALU 1 — G5 Specification (Teilaufgabe 1)

## Group parameters (confirmed from G5table.png)

| Parameter | Value |
|---|---|
| Device | Spartan3E 500 |
| Entwurfsziel | **Maximale Nebenläufigkeit** |

**Maximale Nebenläufigkeit** means every operation is computed simultaneously as a concurrent signal assignment. A final `with opcode select` muxes the pre-computed result. Zero processes in the architecture.

---

## Port interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `a` | in | 8 bits | Operand A |
| `b` | in | 8 bits | Operand B |
| `opcode` | in | 3 bits | Selects operation (8 ops) |
| `result` | out | 8 bits | Computed result |
| `carry` | out | 1 bit | Carry/borrow from ADD/SUB; '0' for all other ops |

> **Confirm with assignment sheet:** bit widths and exact operation set for G5 Teilaufgabe 1.  
> The implementation below uses standard 8 ops — swap in/out as needed.

---

## Operation table

| Opcode | Mnemonic | Expression |
|---|---|---|
| `000` | ADD | `a + b` (carry = bit 8) |
| `001` | SUB | `a - b` (carry = borrow bit 8) |
| `010` | AND | `a and b` |
| `011` | OR  | `a or b` |
| `100` | XOR | `a xor b` |
| `101` | NOT | `not a` (b ignored) |
| `110` | SHL | `a` shifted left 1, LSB = '0' |
| `111` | SHR | `a` shifted right 1, MSB = '0' |

---

## Architecture: Maximale Nebenläufigkeit

All intermediate results are declared as internal signals and driven by concurrent signal assignments — hardware computes all 8 operations in parallel every clock-less cycle. A single `with opcode select` muxes `result` and `carry` from the pre-computed values. No `process` blocks.

```
a, b ──┬──► [ADD]──────┐
       ├──► [SUB]──────┤
       ├──► [AND]──────┤
       ├──► [OR] ──────┼──► with opcode select ──► result
       ├──► [XOR]──────┤
       ├──► [NOT]──────┤
       ├──► [SHL]──────┤
       └──► [SHR]──────┘
opcode ─────────────────────► select
```

---

## Test vectors (used in alu1_tb.vhd)

| a (hex) | b (hex) | opcode | Expected result (hex) | carry | Note |
|---|---|---|---|---|---|
| `0x0F` | `0x01` | `000` | `0x10` | '0' | ADD no carry |
| `0xFF` | `0x01` | `000` | `0x00` | '1' | ADD overflow → carry=1 |
| `0x10` | `0x01` | `001` | `0x0F` | '0' | SUB no borrow |
| `0x00` | `0x01` | `001` | `0xFF` | '1' | SUB underflow → borrow=1 |
| `0xAA` | `0x0F` | `010` | `0x0A` | '0' | AND |
| `0xA0` | `0x0F` | `011` | `0xAF` | '0' | OR |
| `0xFF` | `0x0F` | `100` | `0xF0` | '0' | XOR |
| `0xAA` | `0x00` | `101` | `0x55` | '0' | NOT a |
| `0x01` | `0x00` | `110` | `0x02` | '0' | SHL |
| `0x80` | `0x00` | `111` | `0x40` | '0' | SHR |
