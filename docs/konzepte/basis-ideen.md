<strong><i>[Basis-Ideen/Voraussetzungen](basis-ideen.md)</i></strong> - [Auswahl Algorithmen](auswahl.md)

# Basis-Ideen/Voraussetzungen

## Parallelität
- mehrere Datenpunkte parallel berechnen
- SIMD
- Berechnung innerhalb Datenpunkt parallelisieren, falls möglich

## Pipelining
- mehrschrittige Berechnung für mehrere Datenpunkte in verschiedenen Phasen
- Pipelining auch von Operationen innerhalb Phase

## Streaming
- kontinuierliche Verarbeitung von Daten, möglichst ohne Speicherzugriffe
- -> in Pipeline weiter-/durchschieben
- -> kontinuierlicher Stream

## Arithmetik

Ausschlüsse:
- kein Floating-Point
- keine Division
- keine Wurzeln
- möglichst keine Potenzen (oder nur feste)?
- negative Zahlen/2er-Komplement bei Multiplikation?

Festlegungen:
- Fixed-Point (Format? Q16.8, Q32.16, Q20.12, Generic je nach Problem)
- 2er-Komplement/Signed
- 3 Operationen: Addition, Subtraktion, Multiplikation
- komplexe Funktionen mit Lookup-Table (evtl. auch für Wurzeln, falls notwendig)?

Addition/Subtraktion:
- Overflow/Carry!
- sonst unproblematisch mit Fixed-Point und 2er-Komplement
- unverändert zu Integer-Addition
- CLA?

Multiplikation:
- Overflow!
- über Integer-Multiplikation mit Shift und Cut
- Bsp. für Q5.3: 11011,011 * 10101,101 = 10 0100 1111,1111 11
  - wird zu <ins>10 010</ins>0 1111,111~~1 11~~ (Overflow und Verlust von Genauigkeit)
  - Verlust von Genauigkeit akzeptabel
  - Overflow problematisch wie Carry/Overflow bei Addition/Subtraktion
  - einfach ignorieren oder Meldung: Berechnung fehlerhaft?
    - Meldung parallel und weiter rechnen?
    - sonst einfach ignorieren
- Umgang mit 2er-Komplement/Signed
  - von IEEE Library in VHDL unterstützt
  - Problem: Erkennung Overflow (Unterschied positiv/negativ)
    - TODO

Fixed-Point:
- ca. 0,3 Nachkommastellen Genauigkeit je Fraction-Bit
- vermutlich 25x18 oder 18x18 Multiplier
  - 18 Bit nicht ausreichend
  - 2x18 Bit, also 36 Bit gesamt
- 36 Bit gesamt:
  - Q26.10 mit 134 217 727 + 3,0
  - Q24.12 mit 8 388 607 + 3,6
- besser: Generic je nach Problem bzw. Fraction-Size als Parameter
 - Notiz: implementiert (nur Multiplikation anders), funktioniert

| Fraction-Bits | Genauigkeit (Nachkommastellen) [`Bits * log10(2)`] |
| -- | -- |
| 8 | 2,4 |
| 10 | 3,0 |
| 12 | 3,6 |
| 14 | 4,2 |
| 16 | 4,8 |
| 18 | 5,4 |
| 20 | 6,0 |
| 22 | 6,6 |
| 24 | 7,2 |
| 26 | 7,8 |
| 28 | 8,4 |
| 30 | 9,0 |
| 32 | 9,6 |

| Integer-Bits | Maximum [`2^(Bits-1) - 1`] |
| -- | -- |
| 16 | 32 767 |
| 20 | 524 287 |
| 22 | 2 097 151 |
| 24 | 8 388 607 |
| 26 | 33 554 431 |
| 28 | 134 217 727 |
| 32 | 2 147 483 647 |

PRNG:
- LFSR
  - primitives Polynomen für maximale Periodenlänge
  - LFSR kombinieren: unterschiedliche Polynome/Seeds, Bit-Mixing
  - Whitening
- Xorshift
