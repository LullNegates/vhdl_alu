# VHDL ALU — Projektaufgabe 3 (Gruppe G5)

Anwendungsspezifische ALU für das FHDW-Modul Digital Design (SoSe 2026).  
Aufbauend auf P2 (Stoppuhr-Controller). Zwei separate ALU-Designs, gemeinsame Entity, je eigene Architektur, Testbench und Makefile.

- **Gruppe:** G5 — FHDW Hannover
- **Device:** Spartan3E 500 (xa3s100e-4cpg132)
- **Entwurfsziel:** Maximale Nebenläufigkeit

---

## Repository-Struktur

```
vhdl_alu/
├── shared/
│   └── asalu_entity.vhd        Entity ASALU (gemeinsam für ALU 1 + 2)
│
├── alu1/                        Teilaufgabe a — architecture behavioral
│   ├── src/
│   │   ├── alu1.vhd             architecture behavioral of ASALU
│   │   └── alu1_tb.vhd          Testbench (ASALU_behavioral_tb)
│   ├── sim/                     GHDL-Wellenformen (.ghw) — git-ignored
│   └── Makefile
│
├── alu2/                        Teilaufgabe b — architecture structural
│   ├── src/
│   │   ├── alu2.vhd             architecture structural of ASALU + 6 Sub-Entities
│   │   └── alu2_tb.vhd          Testbench (ASALU_structural_tb)
│   ├── sim/
│   └── Makefile
│
└── doc/
    ├── blockschaltbild.md       Top-Level-Blockschaltbild + Befehlstabelle
    ├── alu1-spec.md             Spezifikation ALU 1 (behavioral)
    ├── alu2-spec.md             Spezifikation ALU 2 (structural, Sub-Entities)
    └── plan.md                  Implementierungsplan
```

---

## Entity ASALU — Ports

| Port    | Richt. | Breite | Beschreibung                                          |
|---------|--------|--------|-------------------------------------------------------|
| CLK     | in     | 1      | Takt (steigende Flanke)                               |
| RST     | in     | 1      | Synchroner Reset, active-high (1 Takt genügt)         |
| A       | in     | 8      | Operand A / RAM-Startadresse (CRC_MEM, SendCANData)   |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse       |
| Cmd     | in     | 4      | Befehlscode (16 Ops, Befehlstabelle 1+2)              |
| Flow    | out    | 8      | Ergebnis Low-Byte                                     |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL und CRC_MEM)       |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit                |
| Equal   | out    | 1      | A = B (rein kombinatorisch, taktunabhängig)           |
| OV      | out    | 1      | Signed Overflow (ADD / SUB)                           |
| Sign    | out    | 1      | MSB des Ergebnisses                                   |
| CB      | out    | 1      | CRCBusy — '1' während CRC_MEM läuft                   |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'          |
| CAN     | out    | 1      | Serieller CAN-Datenausgang (1 Bit/Takt, MSB first)    |

---

## Befehlstabelle (beide ALUs)

| Cmd  | Mnemonik       | Operation                        | Cout              | OV         | Sign     |
|------|----------------|----------------------------------|-------------------|------------|----------|
| 0000 | ADD            | F = A + B                        | Carry             | Signed OVF | MSB      |
| 0001 | SUB            | F = A − B                        | Borrow            | Signed OVF | MSB      |
| 0010 | MUL2           | F = (A+B) × 2                    | sum[8]\|[7]       | 0          | MSB      |
| 0011 | MUL4           | F = (A+B) × 4                    | sum[8]\|[7]\|[6]  | 0          | MSB      |
| 0100 | NEG            | F = −A (2er-Komplement)          | Sign              | 0          | MSB      |
| 0101 | SLL            | F = A << 1                       | A[7]              | 0          | MSB      |
| 0110 | SLR            | F = A >> 1                       | A[0]              | 0          | 0        |
| 0111 | RLL            | F = rotate_left(A)               | 0                 | 0          | MSB      |
| 1000 | RLR            | F = rotate_right(A)              | 0                 | 0          | MSB      |
| 1001 | MUL            | F = A × B → 16-bit               | 0                 | 0          | FHigh[7] |
| 1010 | NAND           | F = NOT(A AND B)                 | 0                 | 0          | MSB      |
| 1011 | XOR            | F = A XOR B                      | 0                 | 0          | MSB      |
| 1100 | WriteRAM       | mem[B] ← A                       | 0                 | 0          | 0        |
| 1101 | CRC_MEM        | CAN-CRC-15 von mem[A..B] → Flow  | 0                 | 0          | MSB      |
| 1110 | SendCANData    | CAN-Reg + mem[A..B] → CAN-Pin    | —                 | —          | —        |
| 1111 | Reserved       | —                                | 0                 | 0          | 0        |

**MUL:** FHigh = High-Byte, Flow = Low-Byte (16-bit unsigned).  
**CRC_MEM:** Polynom 0x4599 (CAN-CRC-15, ISO 11898), 1 Byte/Takt, CB='1' während Berechnung.  
**SendCANData:** Serialisiert zuerst CAN-Frame-Header (19-bit 2.0A oder 39-bit 2.0B), dann mem[A..B] — 1 Bit/Takt, MSB first. CRC wird nicht automatisch angehängt.

---

## ALU 1 — architecture behavioral

Einprozess-Clocked-Design. Alle 16 Operationen in einem `case Cmd`-Block.  
Latenz: **1 Taktzyklus** pro Einzelbefehl.  
Multi-cycle-Ops (CRC_MEM, SendCANData) über synchrone State Machine mit synchronem Reset:

```
IDLE ──[Cmd=1101]──► CRC_COMPUTE ──(addr=end)──► IDLE
IDLE ──[Cmd=1110]──► CAN_SEND   ──(alle Bits)──► IDLE
     ◄──[RST=1]────────────────────────────────────
```

Interne CAN-Register: `can_reg_20a` (19-bit, Standard Frame) und `can_reg_20b` (39-bit, Extended Frame), wählbar über `can_mode`. Reset setzt beide auf 0.

---

## ALU 2 — architecture structural

Maximale Nebenläufigkeit durch zwei sich ergänzende Mechanismen:

**Räumliche Nebenläufigkeit:** Alle Sub-Entities berechnen jede Instruktion gleichzeitig in Hardware — `result_mux` wählt das Ergebnis per `Cmd` aus.

**Temporale Nebenläufigkeit (3-stufige Pipeline):**
```
Stage 1 (ID)  →  Stage 2 (EX)               →  Stage 3 (WB)
p1-Register      alle FUs parallel              p2-Register
latcht A,B,Cmd   arith+mul+shift+logic+mux      latcht Ergebnis → Ausgabe
```
- **Latenz:** 2 Taktzyklen (ID → WB)
- **Durchsatz:** 1 Instruktion/Takt nach Pipeline-Fill
- **Stall:** `mc_stall='1'` friert p1 + p2 bei CRC_MEM / SendCANData ein; WriteRAM stallt nicht

| Sub-Entity    | Funktion                                                            |
|---------------|---------------------------------------------------------------------|
| `arith_unit`  | ADD, SUB, MUL2, MUL4, NEG — alle gleichzeitig, rein kombinatorisch |
| `mul_unit`    | 8×8 → 16-bit unsigned Multiplikation                                |
| `shift_unit`  | SLL, SLR, RLL, RLR — alle gleichzeitig                              |
| `logic_unit`  | NAND, XOR — beide gleichzeitig                                      |
| `result_mux`  | Selektiert Flow/FHigh aus allen Sub-Units anhand Cmd                |
| `flag_gen`    | Cout, OV, Sign — kombinatorisch aus Sub-Unit-Outputs                |
| `mem_ctrl`    | RAM 256×8, CRC-Engine, CAN-Serializer — getaktet, eigener RST      |

`mem_ctrl` liest direkt von den Top-Level-Ports (nicht aus der Pipeline), um Re-Execution nach Multi-Cycle-Ops zu verhindern. `mc_active` übernimmt bei Cmd 1100–1110 oder laufender State Machine die Outputs.

---

## Toolchain

| Tool | Zweck                                                     |
|-----------------------------|------------------------------------|
| GHDL 4.1.0 (WSL2)           | Kompilierung + Simulation          |
| GTKWave 3.3.116 (WSL2)      | Wellenform-Analyse                 |
| ISim / Xilinx ISE 14.7 (VM) | Simulation für Abgabe-Screenshots  |
| TerosHDL (VSCode)           | Port-Viewer + Syntax-Highlighting  |

---

## WSL2 Quick-Start

```bash
# ALU 1 (behavioral)
cd alu1
make simulate   # kompiliert shared + alu1 + tb, startet GHDL
make view       # öffnet GTKWave

# ALU 2 (structural)
cd alu2
make simulate
make view
```

### Build-Targets (beide Makefiles)

| Target           | Aktion                                           |
|------------------|--------------------------------------------------|
| `make all`       | Alias für `simulate`                             |
| `make compile`   | Analyse + Elaboration                            |
| `make simulate`  | Kompilieren + GHDL-Simulation, schreibt `.ghw`   |
| `make view`      | GTKWave auf letztem `.ghw` öffnen                |
| `make clean`     | Artefakte und Wellenformen löschen               |

---

## Simulationsergebnisse

| ALU   | Architektur | Latenz        | Testvektoren | Ergebnis               | Sim-Zeit  |
|-------|-------------|---------------|:------------:|------------------------|-----------|
| ALU 1 | behavioral  | 1 Taktzyklus  | 27/27        | alle Assertions passed | @ 686 ns  |
| ALU 2 | structural  | 2 Taktzyklen  | 27/27        | alle Assertions passed | @ 946 ns  |

Getestet mit GHDL 4.1.0 (WSL2). Beide Testbenches beginnen mit 2-Takt-Reset-Sequenz.  
Die längere Sim-Zeit von ALU 2 ergibt sich aus 2-Takt-Latenz pro Einzelbefehl (Pipeline) plus Reset-Puls — beide Architekturen sind funktional identisch.
