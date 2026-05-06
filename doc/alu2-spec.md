# ALU 2 — G5 Specification (Teilaufgabe 2)

> Items marked **[CONFIRM]** need verification against the G5 assignment sheet before coding.

---

## Group parameters

| Parameter      | Value                       |
|----------------|-----------------------------|
| Device         | Spartan3E 500               |
| Entwurfsziel   | Maximale Nebenläufigkeit    |

---

## Port interface **[CONFIRM widths from G5 sheet]**

| Port     | Direction | Width | Description                               |
|----------|-----------|-------|-------------------------------------------|
| `a`      | in        | 8     | Operand A                                 |
| `b`      | in        | 8     | Operand B                                 |
| `opcode` | in        | 3     | Selects operation (8 ops → 3 bits)        |
| `result` | out       | 8     | Computed result                           |
| `c`      | out       | 1     | Carry flag (ADD overflow / SUB borrow)    |
| `z`      | out       | 1     | Zero flag  (`result = 0x00`)              |
| `n`      | out       | 1     | Negative flag (MSB of result)             |
| `v`      | out       | 1     | Signed overflow flag                      |

---

## Operation table **[CONFIRM opcode encoding from G5 sheet]**

| Opcode | Mnemonic | Expression              | C       | Z              | N           | V                   |
|--------|----------|-------------------------|---------|----------------|-------------|---------------------|
| `000`  | ADD      | `a + b`                 | bit 8   | result = 0     | result(7)   | signed OVF formula  |
| `001`  | SUB      | `a - b`                 | bit 8   | result = 0     | result(7)   | signed OVF formula  |
| `010`  | AND      | `a and b`               | `'0'`   | result = 0     | result(7)   | `'0'`               |
| `011`  | OR       | `a or b`                | `'0'`   | result = 0     | result(7)   | `'0'`               |
| `100`  | XOR      | `a xor b`               | `'0'`   | result = 0     | result(7)   | `'0'`               |
| `101`  | NOT      | `not a`                 | `'0'`   | result = 0     | result(7)   | `'0'`               |
| `110`  | SHL      | `a(6:0) & '0'`          | `'0'`   | result = 0     | result(7)   | `'0'`               |
| `111`  | SHR      | `'0' & a(7:1)`          | `'0'`   | result = 0     | result(7)   | `'0'`               |

---

## Architecture: Maximale Nebenläufigkeit

All intermediate results are declared as internal signals and driven by concurrent signal
assignments. An internal `result_i` signal holds the mux output so that Z, N, V flags
can be derived from it without a feedback loop on the output port.

```
a, b ──┬──► [ADD 9-bit] ─────────────────────────────────► res_add(8:0)
       ├──► [SUB 9-bit] ─────────────────────────────────► res_sub(8:0)
       ├──► [AND]  ──────────────────────────────────────► res_and
       ├──► [OR]   ──────────────────────────────────────► res_or
       ├──► [XOR]  ──────────────────────────────────────► res_xor
       ├──► [NOT]  ──────────────────────────────────────► res_not
       ├──► [SHL]  ──────────────────────────────────────► res_shl
       └──► [SHR]  ──────────────────────────────────────► res_shr

opcode ─────────────────────────────────────────────────► with/select
                                                               │
                                         result_i (8-bit) ◄───┘
                                                │
                              ┌─────────────────┼───────────────┐
                              ▼                 ▼               ▼
                           result             Z, N flag       V flag
                                           (concurrent)    (concurrent)

                C ◄── carry with/select (opcode=ADD→res_add(8), SUB→res_sub(8), else '0')
```

### Signed overflow (V) logic

```
ADD:  V = (not a(7) and not b(7) and result_i(7))
          or (a(7) and b(7) and not result_i(7))

SUB:  V = (not a(7) and b(7) and result_i(7))
          or (a(7) and not b(7) and not result_i(7))

all other ops: V = '0'
```

Expressed as a single `with opcode select v <=` — no process.

---

## Test vectors (for alu2_tb.vhd)

| a      | b      | op    | result | C | Z | N | V | Note                           |
|--------|--------|-------|--------|---|---|---|---|--------------------------------|
| `0x0F` | `0x01` | `000` | `0x10` | 0 | 0 | 0 | 0 | ADD normal                     |
| `0xFF` | `0x01` | `000` | `0x00` | 1 | 1 | 0 | 0 | ADD unsigned overflow, Z=1     |
| `0x7F` | `0x01` | `000` | `0x80` | 0 | 0 | 1 | 1 | ADD signed overflow, N=1, V=1  |
| `0x10` | `0x01` | `001` | `0x0F` | 0 | 0 | 0 | 0 | SUB normal                     |
| `0x00` | `0x01` | `001` | `0xFF` | 1 | 0 | 1 | 0 | SUB borrow, N=1                |
| `0x80` | `0x01` | `001` | `0x7F` | 0 | 0 | 0 | 1 | SUB signed overflow, V=1       |
| `0xAA` | `0x0F` | `010` | `0x0A` | 0 | 0 | 0 | 0 | AND                            |
| `0xFF` | `0xFF` | `010` | `0xFF` | 0 | 0 | 1 | 0 | AND N=1                        |
| `0xA0` | `0x0F` | `011` | `0xAF` | 0 | 0 | 1 | 0 | OR N=1                         |
| `0xFF` | `0x0F` | `100` | `0xF0` | 0 | 0 | 1 | 0 | XOR N=1                        |
| `0xFF` | `0xFF` | `100` | `0x00` | 0 | 1 | 0 | 0 | XOR Z=1                        |
| `0xAA` | `0x00` | `101` | `0x55` | 0 | 0 | 0 | 0 | NOT                            |
| `0xFF` | `0x00` | `101` | `0x00` | 0 | 1 | 0 | 0 | NOT Z=1                        |
| `0x80` | `0x00` | `110` | `0x00` | 0 | 1 | 0 | 0 | SHL MSB lost, Z=1              |
| `0x01` | `0x00` | `111` | `0x00` | 0 | 1 | 0 | 0 | SHR LSB lost, Z=1              |
