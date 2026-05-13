# ALU 13 — ASALU Specification (Teilaufgabe b)

## Gruppe / Entwurfsziel

| Parameter      | Wert                                  |
|----------------|---------------------------------------|
| Gruppe         | G5                                    |
| Device         | Spartan3E 500 (xc3s500e-5-vq100)      |
| Entwurfsziel   | Maximale Nebenläufigkeit              |
| Architektur    | `structural_v2` (TopLevel)            |
| Aufgabenblatt  | A_VHDL_P3-b_v_unlocked.pdf            |

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

### Synthese-Ergebnisse

| Strategie           | Kritischer Pfad | Fmax    |
|---------------------|-----------------|---------|
| Balanced (default)  | 8.295 ns        | 120 MHz |
| Timing Performance  | 7.446 ns        | 134 MHz |


| Logic Utilization            | Used | Utilization |
|------------------------------|------|-------------|
| Number of Slice Flip Flops   | 278  | 2%          |
| Number of Occupied Slices    | 326  | 7%          |
| Total Number of 4 input LUTs | 508  | 5%          |
| Number of bonded IOBs        | 45   | 68%         |
| Number ofMULT18X18SIOs       | 1    | 20%         |

---

## Entity ASALU — Ports

| Port    | Richt. | Breite | Beschreibung                                     |
|---------|--------|--------|--------------------------------------------------|
| CLK     | in     | 1      | Takt (steigende Flanke)                          |
| RST     | in     | 1      | Synchroner Reset (aktiv '1')                     |
| A       | in     | 8      | Operand A / RAM-Startadresse (CRC, CAN)          |
| B       | in     | 8      | Operand B / RAM-Adresse (WriteRAM) / Endadresse  |
| Cmd     | in     | 4      | Befehlscode (16 Ops, siehe Befehlstabelle)       |
| Flow    | out    | 8      | Ergebnis Low-Byte                                |
| FHigh   | out    | 8      | Ergebnis High-Byte (belegt bei MUL, CRC)         |
| Cout    | out    | 1      | Carry / Borrow / herausgeschobenes Bit           |
| Equal   | out    | 1      | A = B (kombinatorisch, taktunabhängig)           |
| OV      | out    | 1      | Signed Overflow (ADD / SUB / NEG)                |
| Sign    | out    | 1      | MSB des Ergebnisses                              |
| CB      | out    | 1      | CRCBusy — '1' während CRC_MEM                    |
| Ready   | out    | 1      | '0' während CRC_MEM / SendCANData, sonst '1'     |
| CAN     | out    | 1      | Serieller CAN-Datenausgang                       |

---

## Befehlstabelle

| Cmd  | Mnemonik     | Operation                       | Cout                              | OV         | Sign     | Equal | Comment                    |
|------|--------------|---------------------------------|-----------------------------------|------------|----------|-------|----------------------------|
| 0000 | ADD          | F = A + B                       | Carry                             | Signed OVF | MSB      | A = B | -                          |
| 0001 | SUB          | F = A − B                       | Borrow                            | Signed OVF | MSB      | A = B | -                          |
| 0010 | MUL2         | F = (A+B) × 2                   | A+B Carry or A+B[7]               | 0          | MSB      | A = B | -                          |
| 0011 | MUL4         | F = (A+B) × 4                   | A+B Carry or A+B[7] or A+B[6]     | 0          | MSB      | A = B | -                          |
| 0100 | NEG          | F = −A (Zweier-Komplement)      | F[7]                              | Signed OVF | MSB      | 0     | ov='0' bei NEG 0xF0 = 0xF0 |
| 0101 | SLL          | F = A << 1                      | A[7]                              | 0          | 0        | 0     | -                          |
| 0110 | SLR          | F = A >> 1                      | A[0]                              | 0          | 0        | 0     | -                          |
| 0111 | RLL          | F = rotate_left(A)              | 0                                 | 0          | 0        | 0     | not through carry          |
| 1000 | RLR          | F = rotate_right(A)             | 0                                 | 0          | MSB      | 0     | not through carry          |
| 1001 | MUL          | F = A × B → 16-bit              | 0                                 | 0          | FHigh[7] | 0     | -                          |
| 1010 | NAND         | F = NOT(A AND B)                | 0                                 | 0          | 0        | A = B | -                          |
| 1011 | XOR          | F = A XOR B                     | 0                                 | 0          | MSB      | 0     | -                          |
| 1100 | WriteRAM     | mem[B] ← A                      | 0                                 | 0          | 0        | 0     | -                          |
| 1101 | CRC_MEM      | CRC-15 von mem[A..B] → Flow     | 0                                 | 0          | MSB      | 0     | Stalls Pipeline            |
| 1110 | SendCANData  | Reg + mem[A..B] seriell → CAN   | 0                                 | 0          | 0        | 0     | Stalls Pipeline            |
| 1111 | Reserved     | —                               | 0                                 | 0          | 0        | 0     | -                          |

---

## Architektur: structural\_v2

Die gesamte Implementierung liegt in `alu13/src/alu13.vhd` als `architecture structural_v2 of ASALU`. Es gibt keine zusätzlichen Wrapper-Entities — Pipeline-Logik und FSM sind direkt im Top-Level integriert.

```
A, B ──► add, subtract, add_lls, add_lls_lls   ─┐
         negate, lls, lrs, llr, lrr              ├─► p1_pipe (Stage 1) ──► IDLE-Mux (Stage 2) ──► Flow, FHigh, Flags
         mul, bit_nand, bit_xor                  ─┘

A, B, Cmd ──► (direkt, kein Pipeline-Delay) ──► WriteRAM (WEA kombinatorisch)
                                              ──► CRC_MEM  (inline FSM, CB/Ready)
                                              ──► CAN_SEND (inline FSM, Ready/CAN)

A, B ──► Equal <= '1' when A = B else '0'  (kombinatorisch, kein CLK)
```

### Ausgabe-Routing

```
Equal  ← '1' when A = B else '0'       (kombinatorisch)
CB     ← '1' während CRC_COMPUTE, sonst '0'
Ready  ← '0' während CRC_COMPUTE / CAN_SEND, sonst '1'
CAN    ← can_out während CAN_SEND, sonst '0'

Flow, FHigh, Cout, OV, Sign ←
    Arithmetik-Ergebnis via p1_cmd (Stage 2, 2-Takt-Latenz)
    bzw. Ergebnis der FSM nach Abschluss von CRC_MEM / CAN_SEND
```

---

## Sub-Entity-Beschreibungen

Alle 12 Sub-Entities sind rein kombinatorisch und stammen aus `alu3/`. Jede hat die einheitliche Schnittstelle:
```
port(A, B : in  std_logic_vector(7 downto 0);
     f_low, f_high : out std_logic_vector(7 downto 0);
     c_out, equal, ov, sign : out std_logic)
```

| Entity        | Operation                            | Besonderheit                              |
|---------------|--------------------------------------|-------------------------------------------|
| `add`         | F = A + B                            | 9-bit intern für Carry/OV                 |
| `subtract`    | F = A − B                            | 9-bit intern für Borrow/OV                |
| `add_lls`     | F = (A+B) × 2 (MUL2)                 | Shift nach Addition                       |
| `add_lls_lls` | F = (A+B) × 4 (MUL4)                 | 2× Shift nach Addition                    |
| `negate`      | F = −A (Zweier-Komplement)           | `NOT('0'&A) + 1`, OV aus MSB-Vergleich    |
| `lls`         | F = A << 1 (SLL)                     | entity heißt `lls`, file heißt `sll.vhd`  |
| `lrs`         | F = A >> 1 (SLR)                     |                                           |
| `llr`         | F = rotate_left(A)                   |                                           |
| `lrr`         | F = rotate_right(A)                  |                                           |
| `mul`         | F = A × B → 16-bit (f\_high:f\_low)  | vorzeichenlos, Sign hardcoded '0'         |
| `bit_nand`    | F = NOT(A AND B)                     |                                           |
| `bit_xor`     | F = A XOR B                          |                                           |

Der `equal`-Ausgang aller Sub-Entities wird ignoriert. `Equal` wird stattdessen kombinatorisch auf Top-Level-Ebene berechnet.

---

## Pipeline — Detail

```
Takt N:   Cmd und A/B anlegen
          Sub-Entities berechnen kombinatorisch
          p1_pipe latcht: p1_cmd <= Cmd, p1_add_l <= add_res_l, ...

Takt N+1: IDLE-Mux liest p1_cmd
          wählt passendes p1_*-Register
          schreibt Flow, FHigh, Flags
```

Die Pipeline hat keinen Stall-Mechanismus für FSM-Operationen. CRC_MEM, SendCANData und WriteRAM reagieren auf den unverzögerten `Cmd`-Eingang direkt im IDLE-State und umgehen die Pipeline vollständig.

---

## Block RAM (RAMB4\_S8\_S8)

Der Speicher ist als Xilinx-Primitiv `RAMB4_S8_S8` eingebunden (Wrapper: `RAM.vhd` aus alu3). Beide Ports laufen auf der steigenden CLK-Flanke.

| Port   | Verwendung                                              |
|--------|---------------------------------------------------------|
| Port A | Schreiben (WriteRAM, cmd=1100), `WEA` kombinatorisch    |
| Port B | Lesen (CRC\_MEM und CAN\_SEND), 1 Takt Read-Latenz      |

Da das Primitiv UNISIM-Bibliotheken benötigt, ist die Simulation ausschließlich mit Xilinx ISim möglich. GHDL wird für einen Syntax-Check ohne `RAM.vhd` verwendet.

`ADDRB` wird im IDLE-Takt auf `'0' & A` vorgeladen, sodass `DOB = mem[A]` beim ersten CRC\_COMPUTE-Takt bereits gültig ist.

---

## State Machine

```
IDLE ──[Cmd=1101]──► CRC_COMPUTE ──(crc_addr = crc_end)──► IDLE
IDLE ──[Cmd=1110]──► CAN_SEND   ──(alle Bits gesendet) ──► IDLE
```

**CRC\_COMPUTE:** 1 Byte pro Takt, CAN-CRC-15 (Polynom 0x4599, ISO 11898). Die 8 Bits eines Bytes werden per `for`-Schleife als Variable in einem Takt verarbeitet. Ergebnis: `Flow = CRC[7:0]`, `FHigh = '0' & CRC[14:8]`. CB='1' und Ready='0' während der Berechnung.

**CAN\_SEND Phase 0:** Das CAN-Header-Register (`can_reg_20a` für 2.0A, 19 bit; `can_reg_20b` für 2.0B, 39 bit) wird MSB-first über den CAN-Pin serialisiert. Baudrate: 500 Takte pro Bit (1 Mbit/s bei 2 ns Taktperiode gemäß UCF).

**CAN\_SEND Phase 1:** Die Datenbytes `mem[A..B]` werden MSB-first serialisiert. `ADDRB` lädt während der laufenden Byte-Übertragung bereits die nächste Adresse vor, sodass kein Lücke zwischen den Bytes entsteht.

---

## Bekannte Einschränkungen

Die Implementierung zeigt die wesentlichen Funktionen der ALU einschließlich CRC-Berechnung und CAN-Übertragung. Einige Aspekte sind dabei vereinfacht oder noch nicht vollständig umgesetzt.

**CAN-Header nicht konfigurierbar:** `can_reg_20a` und `can_reg_20b` sind fest auf 0x000 initialisiert. Es gibt keinen Befehl, den Identifier zur Laufzeit zu setzen. Für eine vollständige Implementierung wäre ein eigener Ladebefehl (z.B. cmd=`"1111"`) notwendig, der den Header aus den Eingangsoperanden A und B zusammensetzt — beispielsweise Identifier[10:3] aus A und Identifier[2:0] sowie DLC[3:0] aus den unteren Bits von B.

**Bit-Stuffing fehlt:** Gemäß ISO 11898 muss nach fünf aufeinanderfolgenden gleichen Bits ein invertiertes Stuffing-Bit eingefügt werden. Der Serializer in `CAN_SEND` gibt die Bits ohne Stuffing-Logik aus, was für die Simulation ausreicht, auf echter Hardware jedoch zu Empfangsfehlern führen würde. Zur Behebung wäre ein Zähler einzuführen, der gleichwertige Bits zählt und bei einem Stand von fünf automatisch ein invertiertes Bit einschiebt, bevor der normale Bitstrom fortgesetzt wird.

**Kein CRC-Feld im CAN-Frame:** Die CRC-Berechnung ist als eigenständiger Befehl implementiert und verifiziert. Sie ist jedoch nicht in den CAN-Frame integriert — der gesendete Frame enthält kein CRC-Feld. Eine vollständige Lösung würde die CRC-15-Berechnung parallel zur Serialisierung durchführen, sodass nach den Nutzdaten automatisch die 15 Prüfbits sowie ein CRC-Delimiter-Bit angehängt werden.

**CAN-Idle-Pegel:** Wenn kein Frame gesendet wird, liegt `CAN = '0'` (dominant). Gemäß ISO 11898 ist der Bus-Idle-Zustand rezessiv, also `'1'`. Für die Simulation ist das unerheblich, auf echter Hardware würde der Ausgang jedoch dauerhaft einen dominanten Pegel treiben und den Bus blockieren. Die Korrektur wäre trivial: Default-Zuweisung `CAN <= '1'` statt `'0'` in Reset und IDLE.

**CAN-Modus nicht umschaltbar:** `can_mode` ist fest auf `'0'` (2.0A, Standard Frame) initialisiert. Es gibt keinen Befehl zum Wechsel auf 2.0B (Extended Frame). Cmd=`"1111"` ist als Reserved eingetragen und könnte dafür genutzt werden — zusammen mit dem fehlenden Header-Load-Command.

**MUL Sign-Flag:** Das Sign-Flag bei der Multiplikation ist auf `'0'` festgesetzt, da ausschließlich vorzeichenlose Multiplikation implementiert ist. Falls vorzeichenbehaftete Multiplikation gefordert wäre, müsste das Flag aus dem MSB des 16-bit-Ergebnisses abgeleitet und `mul.vhd` entsprechend angepasst werden.

---

## Simulation (ISim)

Die Simulation setzt Xilinx ISim (ISE 14.7) voraus, da `RAM.vhd` das UNISIM-Primitiv `RAMB4_S8_S8` verwendet.

Top-Level-Konfiguration: `cfg_structural_v2` (in `alu13_tb.vhd`)

Ergebnis: alle 27 Testvektoren bestanden, inklusive CRC-Test (`CRC(0xFF) = 0x0095`) und CAN-Test (35-bit-Frame: 19 Header-Bits + 0xFF + 0xAA).

Für den Syntax-Check ohne ISim steht ein GHDL-Target im Makefile zur Verfügung, das `RAM.vhd` ausschließt:
```
make check
```
