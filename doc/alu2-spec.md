# ALU 2 — ASALU Specification (Teilaufgabe b)

## Gruppe / Entwurfsziel

| Parameter      | Wert                      |
|----------------|---------------------------|
| Gruppe         | G5                        |
| Device         | Spartan3E 500             |
| Entwurfsziel   | Maximale Nebenläufigkeit  |
| Architektur    | `structural` (TopLevel)   |
| Aufgabenblatt  | A_VHDL_P3-b_v_unlocked.pdf |

---

## Geschwindigkeit durch Parallelisierung
### Parallelisierungsansätze
Es wurde eine Pipeline mit zwei Stages umgesetzt:
1. Berechnung von F und Flags
2. Selektierung von F und Flag-satz durch MUX

Durch weitere Stages ist kein Performance-Gewinn möglich.
Lediglich Logisch-Arithmetische Befehle werden in der Pipeline parallel ausgeführt, WRITE_RAM läuft komplett unabhängig durch kombinatorische Berechnung von Addresse und Enable-Signalen, CRC_MEM und SEND_CAN stoppen die Pipeline.

Während dies bei CRC_MEM nötig ist, da dieser Befehl das F-Register nach einer variablen (erst zur Laufzeit bestimmbaren) Anzahl Takte belegt, nutzt SEND_CAN nach maximal 8 Takten RAM-Zugriff keine weiteren geteilten Ressourcen der ALU, somit könnten weitere Befehle bearbeitet werden, dies konnte jedoch aus Zeitgründen nicht umgesetzt werden. Ferner könnte die RAM-Zugriffszeit wiederrum durch Verwendung der Dual-Port-Funktionalität des RAMs: somit könnten gleichzeitig zwei Byte ausgelesen werden, und die maimale Zeit, die SEND_CAN (bei 8 Data-Bytes) den RAM blockiert auf 4 Takte reduziert werden.

Die Logisch-Arithmetische Kombinatorik (inklusive Ergebnis-MUX) könnte mit einer Frequenz von <2ns Taktperiode betrieben werden. Somit könnten langsamere Abläufe wie bspw. RAM-Zugriff oder eine Bytewise-Kombinatorik für Berechnung des CRCs also Multi-Cycle-Paths markiert werden:
```
INST "ram_1/RAMB4_S8_S8_inst" TNM = RAM;                   -- declare ram instance
TIMESPEC TS_RAM_2_CYCLES = FROM "RAM" TO "FFS" TS_CLK * 2; -- all signals from RAM to any FlipFlop can take 2 cycles
INST "crc_mem_1/*" TNM = crc_mem_combinatorials;
TIMESPEC TS_CRC_MEM_4_CYCLES = FROM "crc_mem_combinatorials" TO "FFS" TS_CLK * 4 DATAPATHONLY;
```
Dies wurde implementiert, die Taktfrequenz konnte so von ca. 7ns auf `Minimum period:   2.481ns` reduziert werden. Allerdings werden Multi-Cycle-Paths nicht in der Simulation abgebildet, weswegen testen der Pipeline nicht inklusive RAM Zugriff getestet werden konnte, Multi-Cycle-Paths wurden daraufhin verworfen, weswegen längere kritische Pfade die Performance jetzt massiv verschlechtern. Folglich ist die Pipeline nicht mehr zweckmäßig, da in einer Taktperiode genug Zeit für Arithmetische Kombinatorik und Selektierung des Ergebnisses wären. Für mögliche zukünftige Verbesserungen wurde dennoch an der Pipeline festgehalten.

### Taktperiode
(Beispielwert, kann je nach Heuristik um 1.5ns abweichen)
Design statistics:
Minimum period:  6.640ns{1}   (Maximum frequency:  150.602MHz)
Maximum path delay from/to any node:   6.640ns

---

## Ressourcen


| Logic Utilization            | Used | Utilization |
|------------------------------|------|-------------|
| Number of Slice Flip Flops   | 278  | 2%          |
| Number of Occupied Slices    | 326  | 7%          |
| Total Number of 4 input LUTs | 508  | 5%          |
| Number of bonded IOBs        | 45   | 68%         |
| Number ofMULT18X18SIOs       | 1    | 20%         |

---

## Entity ASALU — Ports

Identisch mit ALU 1 (behavioral):

| Port    | Richt. | Breite | Beschreibung                                      |
|---------|--------|--------|---------------------------------------------------|
| CLK     | in     | 1      | Takt (steigende Flanke)                           |
| A       | in     | 8      | Operand A / RAM-Startadresse (CRC, CAN)           |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse   |
| Cmd     | in     | 4      | Befehlscode (16 Ops, Befehlstabelle)              |
| Flow    | out    | 8      | Ergebnis Low-Byte                                 |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL, CRC)          |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit            |
| Equal   | out    | 1      | A = B (kombinatorisch, taktunabhängig)            |
| OV      | out    | 1      | Signed Overflow (ADD / SUB)                       |
| Sign    | out    | 1      | MSB des Ergebnisses                               |
| CB      | out    | 1      | CRCBusy — '1' während CRC_MEM                      |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'     |
| CAN     | out    | 1      | Serieller CAN-Datenausgang                        |

---

## Befehlstabelle

Identisch mit ALU 1:

| Cmd  | Mnemonik     | Operation                       | Cout                          | OV         | Sign     | Equal | Comment                    |
|------|--------------|---------------------------------|-------------------------------|------------|----------|-------|----------------------------|
| 0000 | ADD          | F = A + B                       | Carry                         | Signed OVF | MSB      | A = B | -                          |
| 0001 | SUB          | F = A − B                       | Borrow                        | Signed OVF | MSB      | A = B | -                          |
| 0010 | MUL2         | F = (A+B) × 2                   | A+B Carry or A+B[7]           | 0          | MSB      | A = B | -                          |
| 0011 | MUL4         | F = (A+B) × 4                   | A+B Carry or A+B[7] or A=B[6] | 0          | MSB      | A = B | -                          |
| 0100 | NEG          | F = −A (2er-Komplement)         | F[7]                          | Signed OVF | MSB      | 0     | ov='0' bei NEG 0xF0 = 0xF0 |
| 0101 | SLL          | F = A << 1                      | A[7]                          | 0          | 0        | 0     | -                          |
| 0110 | SLR          | F = A >> 1                      | A[0]                          | 0          | 0        | 0     | -                          |
| 0111 | RLL          | F = rotate_left(A)              | 0                             | 0          | 0        | 0     | not through carry          |
| 1000 | RLR          | F = rotate_right(A)             | 0                             | 0          | MSB      | 0     | not through carry          |
| 1001 | MUL          | F = A × B → 16-bit              | 0                             | 0          | FHigh[7] | 0     | -                          |
| 1010 | NAND         | F = NOT(A AND B)                | 0                             | 0          | 0        | A = B | -                          |
| 1011 | XOR          | F = A XOR B                     | 0                             | 0          | MSB      | 0     | -                          |
| 1100 | WriteRAM     | mem[B] ← A                      | 0                             | 0          | 0        | 0     | -                          |
| 1101 | CRC_MEM      | CRC-15 von mem[A..B] → Flow     | 0                             | 0          | MSB      | 0     | Stalls Pipeline            |
| 1110 | SendCANData  | Reg + mem[A..B] seriell → CAN   | 0                             | 0          | 0        | 0     | Stalls Pipeline            |
| 1111 | Reserved     | —                               | 0                             | 0          | 0        | 0     | -                          |

---

## Architektur: structural — 7 Sub-Entities

Jede einzelzyklische Operation wird **gleichzeitig** in einer eigenen Sub-Entity berechnet.
Der `result_mux` wählt per `with Cmd select` das Ergebnis aus.
`mem_ctrl` verwaltet alle mehrzyklischen Operationen (Cmd 1100–1110).

```
A, B ──┬──► arith_unit ──► sum9(8:0), diff9(8:0), res_mul2, res_mul4, res_neg
       ├──► mul_unit   ──► product(15:0)
       ├──► shift_unit ──► res_sll, res_slr, res_rll, res_rlr
       └──► logic_unit ──► res_nand, res_xor

Cmd ───────► result_mux ──► s_flow(7:0), s_fhigh(7:0)
                          │
             flag_gen ◄───┘ (sum9, diff9, res_neg, product, flow_out)
                          │
                          ▼
                    Cout, OV, Sign

CLK, A, B, Cmd ──► mem_ctrl ──► mc_flow, mc_fhigh, mc_cout, mc_ov,
                                 mc_sign, mc_cb, mc_ready, mc_can,
                                 mc_active
```

### Ausgabe-Routing

```
Equal  ← '1' when A = B else '0'   (rein kombinatorisch, kein CLK)
CB     ← mc_cb
Ready  ← mc_ready
CAN    ← mc_can

Flow   ← mc_flow   when mc_active='1' else s_flow
FHigh  ← mc_fhigh  when mc_active='1' else s_fhigh
Cout   ← mc_cout   when mc_active='1' else s_cout
OV     ← mc_ov     when mc_active='1' else s_ov
Sign   ← mc_sign   when mc_active='1' else s_sign
```

**mc_active** (kombinatorisch in mem_ctrl):
```
mc_active = '1' when (state ≠ IDLE) or (Cmd = "1100" or "1101" or "1110")
```

---

## Sub-Entity-Beschreibungen

### arith_unit
Berechnet ADD, SUB, MUL2, MUL4, NEG alle gleichzeitig:
- `sum9 = ('0' & A) + ('0' & B)` — 9-bit für Carry-Erkennung
- `diff9 = ('0' & A) − ('0' & B)` — 9-bit für Borrow-Erkennung
- `res_mul2 = sum9(6:0) & '0'`
- `res_mul4 = sum9(5:0) & "00"`
- `res_neg = -signed(A)` (2er-Komplement)

### mul_unit
`product = unsigned(A) * unsigned(B)` — 16-bit unsigned Multiplikation.

### shift_unit
- `res_sll = A(6:0) & '0'`
- `res_slr = '0' & A(7:1)`
- `res_rll = A(6:0) & A(7)`
- `res_rlr = A(0) & A(7:1)`

### logic_unit
- `res_nand = not (A and B)`
- `res_xor = A xor B`

### result_mux
`with Cmd select flow_out` — wählt das Ergebnis-Byte aus allen Sub-Units.
`fhigh_out` ist nur bei MUL (product(15:8)) belegt, sonst 0x00.

### flag_gen
Berechnet Cout, OV, Sign kombinatorisch aus den Sub-Unit-Outputs:

**Cout:**
| Cmd | Quelle |
|-----|--------|
| 0000 ADD | sum9(8) |
| 0001 SUB | diff9(8) |
| 0010 MUL2 | sum9(8) or sum9(7) |
| 0011 MUL4 | sum9(8) or sum9(7) or sum9(6) |
| 0100 NEG | res_neg(7) |
| 0101 SLL | A(7) |
| 0110 SLR | A(0) |
| sonst | '0' |

**OV (Signed Overflow):**
```
ADD: (not A(7) and not B(7) and sum9(7)) or (A(7) and B(7) and not sum9(7))
SUB: (not A(7) and B(7) and diff9(7)) or (A(7) and not B(7) and not diff9(7))
sonst: '0'
```

**Sign:**
- SLR → immer '0'
- MUL → product(15)
- sonst → flow_out(7)

### mem_ctrl
Verwaltet RAM (256×8 bit), CRC-Engine und CAN-Serializer.
Läuft in einem getakteten Prozess; alle Outputs defaulten zu 0/1/0 in IDLE.

**Interne Signale:**

| Signal        | Breite     | Zweck                                     |
|---------------|------------|-------------------------------------------|
| mem           | 256 × 8 b  | RAM-Speicherblock                         |
| state         | enum       | IDLE / CRC\_COMPUTE / CAN\_SEND           |
| crc\_reg      | 15 b       | CRC-Schieberegister                       |
| crc\_addr/end | 8 b        | Lauf- / End-Adresse CRC                   |
| can\_reg\_20a | 19 b       | CAN 2.0A Frame-Header (Standard Frame)    |
| can\_reg\_20b | 39 b       | CAN 2.0B Frame-Header (Extended Frame)    |
| can\_mode     | 1 b        | '0' = 2.0A, '1' = 2.0B                   |
| can\_phase    | 1 b        | '0' = Header senden, '1' = mem senden    |
| can\_reg\_ptr | int 0..38  | Bit-Position im CAN-Register              |
| can\_addr/end | 8 b        | Lauf- / End-Adresse CAN-Send             |
| can\_byte/bit | 8 b / int  | Aktuelles Byte und Bit-Position           |

---

## State Machine (in mem_ctrl)

```
IDLE ──[Cmd=1101]──► CRC_COMPUTE ──(addr=end)──► IDLE
IDLE ──[Cmd=1110]──► CAN_SEND   ──(alle Bits)──► IDLE
```

- **CRC_COMPUTE:** 1 Byte/Takt, CAN-CRC-15 (Polynom 0x4599, ISO 11898), CB='1', Ready='0'
- **CAN_SEND Phase 0:** CAN-Register seriell (MSB first), Ready='0'
- **CAN_SEND Phase 1:** mem[A..B] seriell (MSB first), Ready='0'

---

## GHDL Simulation

```
ghdl -a --std=08 src/alu2.vhd
ghdl -a --std=08 src/alu2_tb.vhd
ghdl -e --std=08 ASALU_tb
ghdl -r --std=08 ASALU_tb --wave=sim/alu2.ghw
```

Ergebnis: `@666ns: Simulation complete -- all assertions passed` (27 Testvektoren)
