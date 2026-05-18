# Implementation Plan — vhdl_alu (G5, Projektaufgabe 3)

## Entwurfsziel

| Parameter    | Wert                                                  |
|--------------|-------------------------------------------------------|
| Gruppe       | G5                                                    |
| Device       | Spartan-3E 500 (xc3s500e-5-vq100)                    |
| Aufgabe      | A_VHDL_P3-a_v_unlocked.pdf                            |
| Ziel         | Verhaltensbeschreibung + Strukturbeschreibung (ASALU) |
| Abgabe       | ISim-Screenshots + VHDL-Quellen                       |

---

## Entwicklungsverlauf (Mehrgleisig → Merge)

Das Projekt wurde parallel auf zwei Tracks entwickelt, die am Ende zu **alu13** zusammengeführt wurden.

### Track 1 — Darko (alu1 + alu2)

**alu1** (`alu1/src/alu1.vhd`): Verhaltensbeschreibung (`architecture behavioral`).
Vollständige ASALU-Implementierung: alle 16 Ops, FSM (IDLE / CRC_COMPUTE / CAN_SEND),
CAN-CRC-15 Engine, CAN-Serializer (two-phase, Header + Datenbytes), WriteRAM, synchroner Reset.
Simulation mit GHDL, 27/27 Testvektoren grün.

**alu2** (`alu2/src/alu2.vhd`): Strukturbeschreibung (`architecture structural`), ebenfalls von Darko.
7 eigene Sub-Entities (arith_unit, mul_unit, shift_unit, logic_unit, result_mux, …),
3-stufige Pipeline (ID/EX/WB) mit `mc_stall` für CRC/CAN-Blockade.
Latenz: 2 Takte pro Arithmetik-Op. 27/27 Testvektoren grün.

### Track 2 — Bjarne (alu3)

**alu3** (`alu3/`): Bjarne's Strukturbeschreibung mit eigenen Sub-Entities (`add`, `subtract`,
`add_lls`, `add_lls_lls`, `negate`, `lls`, `lrs`, `llr`, `lrr`, `mul`, `bit_nand`, `bit_xor`)
sowie `combinatorics.vhd` (Stage-1-Wrapper) und `resultSelect.vhd` (Stage-2-Mux).
RAM: Xilinx RAMB4_S8_S8 Dual-Port Block RAM. CRC/CAN als eigene Entities (`CRC_MEM.vhd`, `CAN.vhd`).
UCF: 3 ns Periode, Multi-Cycle-Path-Constraints.

### Team-Entscheidung: alu13 als finales Integrationsprojekt

Nach Abgleich beider Tracks wurde entschieden, **alu13** als gemeinsames Abgabe-Projekt zu bauen:
Bjarne's Sub-Entities (alu3) als strukturelle Basis + Darko's CRC/CAN-FSM-Logik (alu1) als
Top-Level-Integration. alu2's eigenständige Sub-Entities wurden damit nicht mehr weitergeführt.

**Anpassungen an alu3-Sub-Entities für alu13:**
Die Sub-Entities aus alu3 mussten für die Integration in alu13 angepasst werden — insbesondere
die Port-Schnittstellen und das Verhalten einzelner Einheiten wurden auf die gemeinsame
Entity-Spezifikation (ASALU) ausgerichtet. Bjarne's `combinatorics`/`resultSelect`-Wrapper-Struktur
wurde in alu13 nicht übernommen; stattdessen instanziiert `alu13.vhd` die Sub-Entities direkt
und implementiert das Pipelining inline (2-Stage, ohne zusätzliche Wrapper-Entities).

---

## Finale Architektur — alu13

**Verzeichnis:** `alu13/` (self-contained, kein externes alu1/ oder shared/ erforderlich)

### Enthaltene Architekturen

| Datei                  | Architecture         | Simulation |
|------------------------|----------------------|------------|
| `src/alu1_behavioral.vhd` | `behavioral`      | GHDL + ISim |
| `src/alu13.vhd`        | `structural_v2`      | ISim only (RAMB4) |

Konfiguration in ISE: `cfg_behavioral` bzw. `cfg_structural_v2`.

### Entity-Ports (ASALU)

| Port  | Richt. | Breite | Beschreibung                                    |
|-------|--------|--------|-------------------------------------------------|
| CLK   | in     | 1      | Takt (steigende Flanke)                         |
| RST   | in     | 1      | Synchroner Reset (aktiv '1')                    |
| A     | in     | 8      | Operand A / RAM-Startadresse                    |
| B     | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse |
| Cmd   | in     | 4      | Befehlscode (16 Ops)                            |
| Flow  | out    | 8      | Ergebnis Low-Byte                               |
| FHigh | out    | 8      | Ergebnis High-Byte (MUL, CRC)                   |
| Cout  | out    | 1      | Carry / Borrow / herausgeschobenes Bit          |
| Equal | out    | 1      | A = B (kombinatorisch)                          |
| OV    | out    | 1      | Signed Overflow (ADD / SUB)                     |
| Sign  | out    | 1      | MSB des Ergebnisses                             |
| CB    | out    | 1      | CRCBusy — '1' während CRC_MEM                  |
| Ready | out    | 1      | '0' während CRC_MEM / SendCANData               |
| CAN   | out    | 1      | Serieller CAN-Datenausgang                      |

### structural_v2 — Interne Struktur

```
A, B ──► [add] [subtract] [add_lls] [add_lls_lls]    ← 12 Sub-Entities
         [negate] [lls] [lrs] [llr] [lrr]               (alu3, kombinatorisch)
         [mul] [bit_nand] [bit_xor]
                │
         ┌──────▼──────────────────────────────┐
         │  Stage 1 (p1_pipe)                  │  ← Alle Ergebnisse + Cmd
         │  Registriert alle 12×(f_low,f_high, │    werden pro Takt gelatcht
         │  c_out, ov, sign) + Cmd             │
         └──────────────────┬──────────────────┘
                            │ p1_cmd / p1_*
         ┌──────────────────▼──────────────────┐
         │  Stage 2 (IDLE-Mux)                 │  ← Wählt per p1_cmd aus,
         │  Flow / FHigh / Cout / OV / Sign    │    schreibt in Output-Register
         └─────────────────────────────────────┘

FSM-Ops (CRC_MEM, SendCAN, WriteRAM) reagieren auf raw Cmd — kein Pipeline-Delay.
Equal: kombinatorisch direkt von A/B-Ports, taktunabhängig.
```

### 2-Stage Arithmetic Pipeline

- **Latenz:** 2 Takte (Arithmetik Cmd 0x0–0xB)
- **Durchsatz:** 1 Ergebnis/Takt nach Pipeline-Fill
- **FSM-Ops:** bypassen Pipeline, Latenz unverändert
- **Testbench:** 2× `wait until rising_edge(CLK)` pro Arithmetik-Assertion

### RAM

- **behavioral:** internes VHDL-Array (`ram_t`, 256×8 bit) — GHDL-kompatibel
- **structural_v2:** Xilinx RAMB4_S8_S8 Dual-Port Block RAM (`RAM.vhd`) — ISim only
  - Port A: Write (WriteRAM), Port B: Read (CRC/CAN), CLKA = CLKB = CLK
  - ADDRB-Vorausladung im IDLE-Takt kompensiert die 1-Takt-Lese-Latenz

### CAN-Serializer

- **behavioral:** 1 Bit pro Takt (kein Baudratengenerator)
- **structural_v2:** `CAN_DIV = 499` → 500 Systemtakte pro CAN-Bit @ 500 MHz = 1 Mbit/s
- Beide: Phase 0 = Header-Register (2.0A: 19-bit, 2.0B: 39-bit), Phase 1 = mem[A..B] MSB-first

### Synthese-Ergebnisse (structural_v2, xc3s500e-5-vq100, vor Pipeline)

| Strategie         | Min. Period | Max. Freq | Slices    | LUTs    | FFs   | BRAMs |
|-------------------|-------------|-----------|-----------|---------|-------|-------|
| Balanced (default)| 8.295 ns    | 120.5 MHz | 241 (5%)  | 453 (4%)| 98    | 1/20  |
| Timing Performance| 7.446 ns    | 134.3 MHz | 233 (5%)  | 438 (4%)| 126   | 1/20  |

Kritischer Pfad (beide): RAMB4→DOB → CRC-XOR-Kette → `crc_reg`.
Nach Pipeline-Einbau: RAMB4→crc_reg-Pfad durch p1-Stage entkoppelt — Verbesserung erwartet.

---

## Status

- [x] alu1 behavioral — 27/27 Testvektoren grün
- [x] alu2 structural (3-Stage Pipeline) — 27/27 Testvektoren grün
- [x] alu3 Sub-Entities — von Bjarne, als Basis für alu13
- [x] alu13 structural_v2 (Integration) — ISim grün, Synthese sauber
- [x] alu13 2-Stage Pipeline eingebaut
- [x] UCF korrigiert (NET "CLK" nach BUFG-Removal)
- [x] Synchroner Reset in Entity + beide Architekturen
- [x] behavioral nach alu13/src/ integriert — alu13 ist self-contained
- [ ] ISim-Screenshots für Abgabe
- [ ] doc/plan.md finalisiert ← dieser Stand
