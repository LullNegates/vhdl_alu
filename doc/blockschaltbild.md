---
title: ASALU — Top-Level Blockschaltbild
date: 2026-05-09
tags: [vhdl, alu, blockschaltbild, asalu, embedded-systems]
---

# ASALU — Top-Level Blockschaltbild

Gilt für beide Architekturen (ALU 1: `behavioral`, ALU 2: `structural`).
Die Sub-Blöcke entsprechen den VHDL-Entities in ALU 2.

---

## Entity-Grenze (Blackbox)

```
           ┌──────────────────────────────────────────────┐
  CLK  ───►│                                              ├──► Flow[7:0]
  A[7:0] ─►│                  ASALU                       ├──► FHigh[7:0]
  B[7:0] ─►│                                              ├──► Cout
 Cmd[3:0] ►│                                              ├──► Equal
           │                                              ├──► OV
           │                                              ├──► Sign
           │                                              ├──► CB
           │                                              ├──► Ready
           │                                              ├──► CAN
           └──────────────────────────────────────────────┘
```

---

## Interne Struktur

```
  CLK   A[7:0]   B[7:0]   Cmd[3:0]
   │       │        │         │
   │       └───┬────┘         │
   │           │              │
   │    ┌──────┼──────────────┼──────────────┐
   │    │      │              │              │
   │    ▼      ▼              ▼              ▼
   │  ┌──────────┐   ┌──────────────┐   ┌───────────────────────────────────┐
   │  │Arithmetik│   │ Shift/Rotate │   │  Speicher & Kommunikation         │
   │  │          │   │              │   │                                   │
   │  │ADD   SUB │   │ SLL   SLR    │   │  RAM 256×8                        │
   │  │(A+B)×2×4 │   │ RLL   RLR    │   │  WriteRAM : mem[B] ← A            │
   │  │NEG       │   │              │   │  CRC_MEM  : liest mem[A..B]       │
   │  │MUL 8×8   │   └──────┬───────┘   │  SendCAN  : liest mem[A..B]       │
   │  │→ 16 bit  │          │           └────────────────────┬──────────────┘
   │  └─────┬────┘    ┌─────▼──────┐                         │
   │        │         │ Logic Unit │              ┌────────────▼─────────────────┐
   │        │         │ NAND   XOR │              │       State Machine          │
   │        │         └─────┬──────┘              │                              │
   │        │               │                     │  IDLE ──[1101]──► CRC_COMPUTE│
   │        └───────────────┘                     │  CRC_COMPUTE ──(done)──► IDLE│
   │                        │                     │                              │
   │               ┌────────▼────────────┐        │  IDLE ──[1110]──► CAN_SEND   │
   │               │    Output-MUX       │        │  CAN_SEND ──(done)──► IDLE   │
   │               │  (Cmd[3:0]-gesteu.) │        │                              │
   │               └────────┬────────────┘        │  CRC-15 Engine (0x4599)      │
   │                        │                     │  · 1 Byte / Takt             │
   │               ┌────────▼───────────┐         │  · CB='1', Ready='0'         │
   │               │    Flag Generator  │         │                              │
   │               │  Cout  OV  Sign    ├────────►│  CAN-Serializer              │
   │               │  CB    Ready       │         │  · 1 Bit / Takt, MSB first   │
   │               └────────────────────┘         │  · Ready='0' während Send    │
   │                                              └──────────────────────────────┘
   │
   └──► Equal = (A = B)   [kombinatorisch, taktunabhängig]
```

---

## State-Machine-Detail

```
              ┌──────────────────────────────────────────┐
              │                IDLE                      │
              └───┬──────────────────────────────┬───────┘
                  │ Cmd=1101                     │ Cmd=1110
                  ▼                              ▼
        ┌─────────────────┐            ┌──────────────────┐
        │   CRC_COMPUTE   │            │    CAN_SEND      │
        │                 │            │                  │
        │ 1 Byte/Takt     │            │ 1 Bit/Takt       │
        │ CRC-15 (0x4599) │            │ MSB first        │
        │ CB='1'          │            │ Ready='0'        │
        │ Ready='0'       │            │ CAN = aktuelles  │
        │ addr++ bis end  │            │       Bit        │
        └─────┬───────────┘            └──────┬───────────┘
              │ addr > end                    │ alle Bits gesendet
              ▼                               ▼
              └──────────────► IDLE ◄──────────┘
```

---

## Port-Tabelle

| Port    | Richt. | Breite | Beschreibung                                    |
|---------|--------|--------|-------------------------------------------------|
| CLK     | in     | 1      | Takt                                            |
| A       | in     | 8      | Operand A / RAM-Startadresse                    |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse |
| Cmd     | in     | 4      | Befehlscode (Befehlstabelle 1+2, 16 Ops)        |
| Flow    | out    | 8      | Ergebnis Low-Byte                               |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL, CRC)        |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit          |
| Equal   | out    | 1      | A = B (kombinatorisch)                          |
| OV      | out    | 1      | Signed Overflow (ADD / SUB)                     |
| Sign    | out    | 1      | MSB des Ergebnisses                             |
| CB      | out    | 1      | CRCBusy — '1' während CRC_MEM                  |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'   |
| CAN     | out    | 1      | Serieller CAN-Datenausgang                      |

---

## Befehlstabelle

| Cmd  | Mnemonik        | Operation                     | Cout            | OV          | Sign        |
|------|-----------------|-------------------------------|-----------------|-------------|-------------|
| 0000 | ADD             | F = A + B                     | Carry           | Signed OVF  | MSB         |
| 0001 | SUB             | F = A − B                     | Borrow          | Signed OVF  | MSB         |
| 0010 | MUL2            | F = (A+B) × 2                 | sum[8]\|[7]     | 0           | MSB         |
| 0011 | MUL4            | F = (A+B) × 4                 | sum[8]\|[7]\|[6]| 0           | MSB         |
| 0100 | NEG             | F = −A (2er-Komplement)       | Sign            | 0           | MSB         |
| 0101 | SLL             | F = A << 1                    | A[7]            | 0           | MSB         |
| 0110 | SLR             | F = A >> 1                    | A[0]            | 0           | 0           |
| 0111 | RLL             | F = rotate_left(A)            | 0               | 0           | MSB         |
| 1000 | RLR             | F = rotate_right(A)           | 0               | 0           | MSB         |
| 1001 | MUL             | F = A × B → 16 bit            | 0               | 0           | FHigh[7]    |
| 1010 | NAND            | F = NOT(A AND B)              | 0               | 0           | MSB         |
| 1011 | XOR             | F = A XOR B                   | 0               | 0           | MSB         |
| 1100 | WriteRAM        | mem[B] ← A                    | 0               | 0           | 0           |
| 1101 | CRC_MEM         | CRC-15 von mem[A..B] → Flow   | 0               | 0           | MSB         |
| 1110 | SendCANData     | mem[A..B] seriell → CAN       | —               | —           | —           |
| 1111 | Reserved        | —                             | 0               | 0           | 0           |

**MUL:** FHigh = oberes Byte, Flow = unteres Byte.
**CRC_MEM:** FHigh[7]='0' (Padding), da CRC-15 nur 15 Bit belegt. CRC-Polynom: 0x4599 (ISO 11898 / CAN).
**SendCANData:** CRC wird *nicht* automatisch angehängt — CRC_MEM und SendCANData sind eigenständige Befehle.

---

## Interne Signale (Referenz)

| Signal            | Breite     | Zweck                                  |
|-------------------|------------|----------------------------------------|
| mem               | 256 × 8 b  | Interner Speicherblock                 |
| state             | enum       | IDLE / CRC\_COMPUTE / CAN\_SEND        |
| crc\_reg          | 15 b       | CRC-Schieberegister                    |
| crc\_addr/crc\_end| 8 b        | Laufende / End-Adresse CRC             |
| can\_addr/can\_end| 8 b        | Laufende / End-Adresse CAN-Send        |
| can\_byte/can\_bit| 8 b / int  | Aktuelles Byte und Bit-Position        |
