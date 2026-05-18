# ALU 1 — ASALU Specification (Teilaufgabe a)

## Gruppe / Entwurfsziel

| Parameter      | Wert                       |
|----------------|----------------------------|
| Gruppe         | G5                         |
| Device         | Spartan3E 500              |
| Entwurfsziel   | Verhaltensbeschreibung     |
| Architektur    | `behavioral` (TopLevel)    |
| Aufgabenblatt  | A_VHDL_P3-a_v_unlocked.pdf |

---

## Entity ASALU — Ports

| Port    | Richt. | Breite | Beschreibung                                      |
|---------|--------|--------|---------------------------------------------------|
| CLK     | in     | 1      | Takt (steigende Flanke)                           |
| RST     | in     | 1      | Synchroner Reset (aktiv '1')                      |
| A       | in     | 8      | Operand A / RAM-Startadresse (CRC, CAN)           |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse   |
| Cmd     | in     | 4      | Befehlscode (16 Ops, Befehlstabelle 1+2)          |
| Flow    | out    | 8      | Ergebnis Low-Byte                                 |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL, CRC)          |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit            |
| Equal   | out    | 1      | A = B (kombinatorisch, taktunabhängig)            |
| OV      | out    | 1      | Signed Overflow (ADD / SUB)                       |
| Sign    | out    | 1      | MSB des Ergebnisses                               |
| CB      | out    | 1      | CRCBusy — '1' während CRC_MEM                    |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'     |
| CAN     | out    | 1      | Serieller CAN-Datenausgang                        |

---

## Befehlstabelle

| Cmd  | Mnemonik     | Operation                       | Cout              | OV         | Sign     |
|------|--------------|---------------------------------|-------------------|------------|----------|
| 0000 | ADD          | F = A + B                       | Carry             | Signed OVF | MSB      |
| 0001 | SUB          | F = A − B                       | Borrow            | Signed OVF | MSB      |
| 0010 | MUL2         | F = (A+B) × 2                   | sum[8]\|[7]       | 0          | MSB      |
| 0011 | MUL4         | F = (A+B) × 4                   | sum[8]\|[7]\|[6]  | 0          | MSB      |
| 0100 | NEG          | F = −A (Zweier-Komplement)      | F[7]              | 0          | MSB      |
| 0101 | SLL          | F = A << 1                      | A[7]              | 0          | MSB      |
| 0110 | SLR          | F = A >> 1                      | A[0]              | 0          | 0        |
| 0111 | RLL          | F = rotate_left(A)              | 0                 | 0          | MSB      |
| 1000 | RLR          | F = rotate_right(A)             | 0                 | 0          | MSB      |
| 1001 | MUL          | F = A × B → 16-bit              | 0                 | 0          | FHigh[7] |
| 1010 | NAND         | F = NOT(A AND B)                | 0                 | 0          | MSB      |
| 1011 | XOR          | F = A XOR B                     | 0                 | 0          | MSB      |
| 1100 | WriteRAM     | mem[B] ← A, Flow ← A           | 0                 | 0          | 0        |
| 1101 | CRC_MEM      | CRC-15 von mem[A..B] → Flow     | 0                 | 0          | MSB      |
| 1110 | SendCANData  | Reg + mem[A..B] seriell → CAN  | —                 | —          | —        |
| 1111 | Reserved     | —                               | 0                 | 0          | 0        |

**MUL:** FHigh = High-Byte, Flow = Low-Byte (16-bit unsigned).  
**NEG:** OV ist in dieser Implementierung hardcoded '0'. In alu13 berechnet `negate.vhd` OV korrekt aus dem MSB-Vergleich.  
**CRC_MEM:** CAN-CRC-15, Polynom 0x4599 (ISO 11898). FHigh[7] = '0' (Padding, da 15-bit).  
**SendCANData:** Serialisiert zuerst CAN-Register (2.0A: 19-bit, 2.0B: 39-bit), dann mem[A..B]. Kein Baudratengenerator — 1 Bit pro Takt. CRC wird nicht automatisch angehängt.  
**WriteRAM:** Schreibt A nach mem[B] und gibt zusätzlich A auf Flow aus.

---

## Interne Signale

| Signal        | Breite     | Zweck                                     |
|---------------|------------|-------------------------------------------|
| mem           | 256 × 8 b  | RAM-Speicherblock (internes Array)        |
| state         | enum       | IDLE / CRC\_COMPUTE / CAN\_SEND           |
| crc\_reg      | 15 b       | CRC-Schieberegister                       |
| crc\_addr/end | 8 b        | Lauf- / End-Adresse CRC                   |
| can\_reg\_20a | 19 b       | CAN 2.0A Frame-Header (Standard Frame)    |
| can\_reg\_20b | 39 b       | CAN 2.0B Frame-Header (Extended Frame)    |
| can\_mode     | 1 b        | '0' = 2.0A, '1' = 2.0B                   |
| can\_phase    | 1 b        | '0' = Header senden, '1' = mem senden    |
| can\_reg\_ptr | int 0..38  | Bit-Position im CAN-Register              |
| can\_addr/end | 8 b        | Lauf- / End-Adresse CAN-Send              |
| can\_byte/bit | 8 b / int  | Aktuelles Byte und Bit-Position           |

Der RAM ist als VHDL-Array implementiert (`ram_t`), nicht als Xilinx-Primitiv. Damit ist die Simulation vollständig mit GHDL möglich.

---

## State Machine

```
IDLE ──[Cmd=1101]──► CRC_COMPUTE ──(addr=end)──► IDLE
IDLE ──[Cmd=1110]──► CAN_SEND   ──(alle Bits)──► IDLE
```

- **CRC_COMPUTE:** 1 Byte/Takt, CAN-CRC-15 (0x4599), CB='1', Ready='0'
- **CAN_SEND Phase 0:** CAN-Register MSB-first, 1 Bit/Takt, Ready='0'
- **CAN_SEND Phase 1:** mem[A..B] MSB-first, 1 Bit/Takt, Ready='0'

CAN\_SEND hat keinen Baudratengenerator — jedes Bit wird genau 1 Takt gehalten. In alu13 werden dagegen 500 Takte pro Bit verwendet (1 Mbit/s bei 2 ns Taktperiode).

---

## GHDL Simulation

```
ghdl -a --std=08 src/alu1.vhd
ghdl -a --std=08 src/alu1_tb.vhd
ghdl -e --std=08 ASALU_tb
ghdl -r --std=08 ASALU_tb --wave=sim/alu1.ghw
```

Ergebnis: `@476ns: Simulation complete -- all assertions passed` (27 Testvektoren)
