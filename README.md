# VHDL ALU - Projektaufgabe 3 (Gruppe G5)

Anwendungsspezifische ALU für das FHDW-Modul Embedded Systems (SoSe 2026).  
Zwei Architekturen (`behavioral` + `structural_v2`), gemeinsame Entity, gemeinsames ISE-Projekt in `alu13/`.

- **Gruppe:** G5 - FHDW Hannover
- **Device:** Spartan-3E 500 (xc3s500e-5-vq100)
- **Entwurfsziel:** Verhaltensbeschreibung + Strukturbeschreibung mit maximaler Nebenläufigkeit

---

## Teilaufgaben-Übersicht (Projektaufgabe 3)

| Teilaufgabe | Beschreibung | Status |
|-------------|--------------|--------|
| a) | Verhaltensbeschreibung (architecture behavioral, TopLevel-Blockschaltbild) | `alu1_behavioral.vhd`, `doc/blockschaltbild.md` |
| b) | Strukturbeschreibung mit Optimierung auf Design-Ziel G5 (maximale Nebenläufigkeit) | `alu13.vhd` + 12 Sub-Entities |
| c) | Beide Versionen bis FirstSignOff (alle Assertions passed) | behavioral: 706 ns / structural_v2: 175616 ns |
| d) | Implementation + Design Summary (wichtige Parameter kommentiert) | Synthese: behavioral 123 MHz, structural_v2 128.7 MHz, siehe Tabelle unten |

---

## Design-Ziel G5 - Maximale Nebenläufigkeit

Gruppe G5 hat als Entwurfsziel **maximale Nebenläufigkeit** für die Strukturbeschreibung. Die folgenden Designentscheidungen wurden getroffen um dieses Ziel zu erfüllen:

### Räumliche Nebenläufigkeit - 12 parallele Sub-Entities

Alle 12 arithmetisch-logischen Operationen werden in **eigenen kombinatorischen Sub-Entities** berechnet, die permanent und gleichzeitig aktiv sind:

| Sub-Entity    | Operation         |
|---------------|-------------------|
| `add`         | A + B             |
| `subtract`    | A − B             |
| `add_lls`     | (A+B) × 2         |
| `add_lls_lls` | (A+B) × 4         |
| `negate`      | −A                |
| `lls`         | A << 1            |
| `lrs`         | A >> 1            |
| `llr`         | rotate_left(A)    |
| `lrr`         | rotate_right(A)   |
| `mul`         | A × B → 16-bit    |
| `bit_nand`    | NOT(A AND B)      |
| `bit_xor`     | A XOR B           |

Jede Sub-Entity berechnet ihr Ergebnis jeden Takt, unabhängig vom aktuellen Cmd. Der Output-Mux in Stage 2 wählt das relevante Ergebnis aus.

### Temporale Nebenläufigkeit - 2-stufige Pipeline

```
Stage 1 (p1_pipe):          Stage 2 (IDLE-Mux):
Registriert alle 12     →   Wählt per p1_cmd das
Ergebnisse + Cmd            Ergebnis aus → Outputs
```

- **Latenz:** 2 Taktzyklen
- **Durchsatz:** 1 Instruktion/Takt (nach Pipeline-Fill)

Die Pipeline spart keine Latenz, verkürzt aber den **kritischen Pfad**: statt der gesamten kombinatorischen Kette (Sub-Entity → Mux → Output) in einem Takt muss jede Stage nur ihre Hälfte innerhalb der Taktperiode abschließen. Das erlaubt eine höhere Maximalfrequenz bei gleichem Durchsatz:

| Architektur   | Kritischer Pfad | Max. Freq  |
|---------------|----------------|------------|
| behavioral    | 8.226 ns       | 121.6 MHz  |
| structural_v2 | 7.769 ns       | 128.7 MHz  |

### Einheitliche Sub-Entity-Schnittstelle

Alle Sub-Entities teilen dieselbe Port-Signatur (`A`, `B`, `F_low`, `F_high`, `Cout`, `OV`, `Sign`, `Equal`). Das vereinfacht das Top-Level-Muxing und macht die Struktur konsistent erweiterbar. Ungenutzte Ports (z.B. `B` bei NEG/Shift) werden von XST automatisch wegoptimiert.

### FSM-Bypass

CRC_MEM, WriteRAM und SendCANData reagieren direkt auf `Cmd` ohne Pipeline-Verzögerung. Diese Operationen benötigen sofortigen RAM-Zugriff und wären mit 2-Takt-Latenz nicht korrekt steuerbar.

### RAMB4_S8_S8 Dual-Port Block RAM

Xilinx Block RAM mit zwei unabhängigen Ports: Port A für WriteRAM (synchrones Schreiben), Port B für CRC/CAN-Lesen. Ermöglicht parallelen Zugriff ohne Arbitrierung.

### CAN-Baudratengenerator

500 Systemtakte pro CAN-Bit bei 500 MHz Zielfrequenz → 1 Mbit/s. Die FSM zählt intern, die restliche Logik läuft parallel weiter.

---

## Repository-Struktur

```
vhdl_alu/
├── alu13/                       Abgabe-Projekt - beide Architekturen in einem ISE-Projekt
│   ├── src/
│   │   ├── asalu_entity.vhd     Entity ASALU (gemeinsam)
│   │   ├── alu1_behavioral.vhd  architecture behavioral of ASALU
│   │   ├── alu1_tb.vhd          Testbench behavioral  (cfg_behavioral)
│   │   ├── alu13.vhd            architecture structural_v2 of ASALU
│   │   ├── alu13_tb.vhd         Testbench structural_v2  (cfg_structural_v2)
│   │   ├── RAM.vhd              RAMB4_S8_S8 Dual-Port Block RAM (ISim only)
│   │   └── add.vhd, subtract.vhd, ...   12 kombinatorische Sub-Entities (von alu3)
│   ├── ALU.ucf                  Constraints: NET "CLK" PERIOD 2ns
│   └── Makefile
│
├── alu1/                        Entwicklungshistorie - behavioral (Darko)
├── alu2/                        Entwicklungshistorie - structural 3-Stage-Pipeline (Darko)
├── alu3/                        Entwicklungshistorie - Sub-Entities + Wrapper (Bjarne)
├── shared/
│   └── asalu_entity.vhd
└── doc/
    ├── blockschaltbild.md       Top-Level-Blockschaltbild + Befehlstabelle
    ├── alu1-spec.md             Spezifikation behavioral
    ├── alu2-spec.md             Spezifikation structural
    ├── alu13-spec.md            Spezifikation structural_v2 (Integrationsarchitektur)
    └── plan.md                  Implementierungsplan + Entwicklungsverlauf
```

---

## Entity ASALU - Ports

| Port    | Richt. | Breite | Beschreibung                                          |
|---------|--------|--------|-------------------------------------------------------|
| CLK     | in     | 1      | Takt (steigende Flanke)                               |
| RST     | in     | 1      | Synchroner Reset, active-high                         |
| A       | in     | 8      | Operand A / RAM-Startadresse (CRC_MEM, SendCANData)   |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse       |
| Cmd     | in     | 4      | Befehlscode (16 Ops, Befehlstabelle 1+2)              |
| Flow    | out    | 8      | Ergebnis Low-Byte                                     |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL und CRC_MEM)       |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit                |
| Equal   | out    | 1      | A = B (rein kombinatorisch, taktunabhängig)           |
| OV      | out    | 1      | Signed Overflow (ADD / SUB)                           |
| Sign    | out    | 1      | MSB des Ergebnisses                                   |
| CB      | out    | 1      | CRCBusy - '1' während CRC_MEM läuft                   |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'          |
| CAN     | out    | 1      | Serieller CAN-Datenausgang (MSB first)                |

---

## Befehlstabelle

| Cmd  | Mnemonik    | Operation                           | Cout             | OV         | Sign     |
|------|-------------|-------------------------------------|------------------|------------|----------|
| 0000 | ADD         | F = A + B                           | Carry            | Signed OVF | MSB      |
| 0001 | SUB         | F = A − B                           | Borrow           | Signed OVF | MSB      |
| 0010 | MUL2        | F = (A+B) × 2                       | sum[8]\|[7]      | 0          | MSB      |
| 0011 | MUL4        | F = (A+B) × 4                       | sum[8]\|[7]\|[6] | 0          | MSB      |
| 0100 | NEG         | F = −A (2er-Komplement)             | Sign             | 0          | MSB      |
| 0101 | SLL         | F = A << 1                          | A[7]             | 0          | MSB      |
| 0110 | SLR         | F = A >> 1                          | A[0]             | 0          | 0        |
| 0111 | RLL         | F = rotate_left(A)                  | 0                | 0          | MSB      |
| 1000 | RLR         | F = rotate_right(A)                 | 0                | 0          | MSB      |
| 1001 | MUL         | F = A × B → 16-bit                  | 0                | 0          | FHigh[7] |
| 1010 | NAND        | F = NOT(A AND B)                    | 0                | 0          | MSB      |
| 1011 | XOR         | F = A XOR B                         | 0                | 0          | MSB      |
| 1100 | WriteRAM    | mem[B] ← A                          | 0                | 0          | 0        |
| 1101 | CRC_MEM     | CAN-CRC-15 von mem[A..B] → Flow     | 0                | 0          | MSB      |
| 1110 | SendCANData | Header-Reg + mem[A..B] → CAN-Pin    | -                | -          | -        |
| 1111 | ToggleCAN   | can_mode ← NOT can_mode (2.0A↔2.0B) | 0                | 0          | 0        |

**MUL:** FHigh = High-Byte, Flow = Low-Byte (16-bit unsigned).  
**CRC_MEM:** Polynom 0x4599 (CAN-CRC-15 / ISO 11898), 1 Byte/Takt. CB='1' während Berechnung.  
**SendCANData:** Erst CAN-Frame-Header (2.0A: 19-bit, 2.0B: 39-bit), dann mem[A..B] MSB-first. CRC nicht automatisch angehängt.

---

## architecture behavioral (`alu1_behavioral.vhd`)

Einprozess-Clocked-Design. Alle 16 Operationen in einem `case Cmd`-Block, synchroner Reset.  
**Latenz:** 1 Taktzyklus pro Arithmetik-Op.  
**RAM:** internes VHDL-Array (256×8 bit) - GHDL-kompatibel.  
**CAN:** 1 Bit pro Systemtakt (kein Baudratengenerator).

State Machine:
```
IDLE ──[Cmd=1101]──► CRC_COMPUTE ──(addr=end)──► IDLE
IDLE ──[Cmd=1110]──► CAN_SEND    ──(alle Bits)──► IDLE
```

---

## architecture structural_v2 (`alu13.vhd`)

Maximale Nebenläufigkeit durch räumliche **und** temporale Nebenläufigkeit.

**Räumlich:** 12 Sub-Entities (von Bjarne / alu3) berechnen alle Ops gleichzeitig kombinatorisch:

| Sub-Entity      | Funktion                                  |
|-----------------|-------------------------------------------|
| `add`           | A + B                                     |
| `subtract`      | A − B                                     |
| `add_lls`       | (A+B) × 2                                 |
| `add_lls_lls`   | (A+B) × 4                                 |
| `negate`        | −A (2er-Komplement)                       |
| `lls` / `lrs`   | Shift left / right                        |
| `llr` / `lrr`   | Rotate left / right                       |
| `mul`           | A × B → 16-bit                            |
| `bit_nand`      | NOT(A AND B)                              |
| `bit_xor`       | A XOR B                                   |

**Temporal (2-stufige Pipeline):**
```
Stage 1 (p1_pipe)          Stage 2 (IDLE-Mux)
Registriert alle 12        Wählt per p1_cmd das
Sub-Entity-Ergebnisse  →   Ergebnis aus → Flow/FHigh/Flags
+ Cmd in p1_*-Registern
```
- **Latenz:** 2 Taktzyklen (Arithmetik Cmd 0x0–0xB)
- **Durchsatz:** 1 Instruktion/Takt nach Pipeline-Fill
- **FSM-Ops** (CRC_MEM, SendCAN, WriteRAM) bypassen die Pipeline - reagieren auf raw Cmd
- **RAM:** Xilinx RAMB4_S8_S8 Dual-Port Block RAM (ISim only, kein GHDL)
- **CAN:** Baudratengenerator - 500 Systemtakte/Bit bei 500 MHz = 1 Mbit/s

---

## Entwicklungsverlauf

Das Projekt entstand auf drei parallelen Tracks, die in `alu13` zusammengeführt wurden:

- **alu1** (Darko) - Verhaltensbeschreibung, vollständige ASALU inkl. CRC/CAN/FSM
- **alu2** (Darko) - Eigene Strukturbeschreibung: 7 Sub-Entities, 3-Stage-Pipeline (ID/EX/WB)
- **alu3** (Bjarne) - Alternative Sub-Entities + `combinatorics`/`resultSelect`-Wrapper, RAMB4

**Team-Entscheidung:** Bjarnes Sub-Entities (alu3) als strukturelle Basis + Darkos CRC/CAN-FSM-Logik (alu1) als Top-Level → `alu13` als gemeinsames Abgabe-Projekt. Die 2-Stage-Pipeline wurde direkt in `alu13.vhd` eingebaut (ohne Wrapper-Entities).

---

## Simulations- und Syntheseergebnisse

### Simulation (ISim, xc3s500e-5-vq100)

| Architektur    | Latenz       | Testvektoren | Ergebnis               |
|----------------|------------- |:------------:|------------------------|
| behavioral     | 1 Taktzyklus | 27/27        | alle Assertions passed |
| structural_v2  | 2 Taktzyklen | 27/27        | alle Assertions passed |

### Synthese (XST, xc3s500e-5-vq100)

| Architektur   | Strategie          | Min. Periode | Max. Freq  | Slices   | LUTs    | FFs  | BRAMs |
|---------------|--------------------|--------------|----------- |----------|---------|------|-------|
| behavioral    | Balanced           | 8.226 ns     | 121.6 MHz  | 379 (8%) | 728 (7%)| 89   | 2/20  |
| structural_v2 | Speed              | 7.769 ns     | 128.7 MHz  | 256 (5%) | 474 (5%)| 191  | 1/20  |

Kritischer Pfad (structural_v2): RAMB4→DOB → CRC-XOR-Kette → `crc_reg`.  
Der 2 ns UCF-Constraint (500 MHz) ist ein Test-Target - auf dem Device physikalisch nicht erreichbar.

---

## ISE Quick-Start (alu13)

1. Alle `alu13/src/*.vhd` in ein ISE-Projekt laden
2. UCF: `alu13/ALU.ucf`
3. Im Design-Panel **Simulation** wählen
4. Testbench anklicken (`ASALU_behavioral_tb` oder `ASALU_structural_v2_tb`)
5. **Simulate Behavioral Model** → ISim → `run all`

### Synthese umschalten (structural_v2)

1. Files-Tab → Rechtsklick auf `alu1_behavioral.vhd` → Properties → View Association: **Simulation**
2. Design-Panel → Implementation → `ASALU` anklicken
3. Processes → **Synthesize - XST** doppelklicken

### GHDL (nur behavioral, WSL2)

```bash
cd alu1
make simulate   # kompiliert + simuliert mit GHDL
make view       # GTKWave
```

---

## Toolchain

| Tool                        | Zweck                                      |
|-----------------------------|--------------------------------------------|
| GHDL 4.1.0 (WSL2)           | Kompilierung + Simulation (behavioral)     |
| GTKWave 3.3.116 (WSL2)      | Wellenform-Analyse                         |
| Xilinx ISE 14.7 / ISim (VM) | Simulation + Synthese (beide Architekturen)|
| TerosHDL (VSCode)           | Port-Viewer + Syntax-Highlighting          |

---

## Anhang: behavioral separat synthetisieren

Normalerweise nicht nötig — behavioral dient als Referenz/Simulation. Falls doch:

1. Files-Tab → Rechtsklick auf `alu1_behavioral.vhd` → Properties → View Association: **All**
2. Design-Panel → Implementation → `ASALU` anklicken
3. Processes → **Synthesize - XST** doppelklicken
