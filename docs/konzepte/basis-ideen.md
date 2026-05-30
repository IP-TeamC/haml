# Basis-Ideen/Voraussetzungen

Die Basis-Ideen beschreiben grundlegende Voraussetzungen sowie Festlegungen,
um eine Implementierung von Machine-Learning-Algorithmen auf einem FPGA effizient/sinnvoll gestalten zu können.
Inhaltlich entsprechen diese Ideen größtenteils den Vorüberlegungen zu Beginn des Projekts und wurden nur minimal überarbeitet.
Die hier kurz beschriebenen Überlegungen zu Parallelität, Pipelining, Streaming und Arithmetik wurden tatsächlich sehr ähnlich umgesetzt.

## Parallelität

- mehrere Datenpunkte parallel berechnen
- SIMD
- Berechnung innerhalb Datenpunkt parallelisieren, falls möglich

## Pipelining

- mehrschrittige Berechnung für mehrere Datenpunkte in verschiedenen Phasen
- Pipelining auch von Operationen innerhalb einer Phase

## Streaming

- kontinuierliche Verarbeitung von Daten, möglichst ohne Speicherzugriffe
- -> in Pipeline weiter-/durchschieben
- -> kontinuierlicher Stream
- -> möglichst keine Verzweigungen

## Arithmetik

Ausschlüsse:

- kein Floating-Point
- keine Division
- keine Wurzeln
- möglichst keine Potenzen

Festlegungen:

- Fixed-Point
- 2er-Komplement/Signed
- 3 Operationen: Addition, Subtraktion, Multiplikation
- komplexe Funktionen mit Lookup-Table (nicht notwendig, daher nicht umgesetzt)

Addition/Subtraktion mit Fixed-Point:

- unproblematisch mit Fixed-Point und 2er-Komplement
- unverändert zu Integer-Addition

Multiplikation mit Fixed-Point:

- Multiplikation von Fixed-Point identisch zu Integer
  - lediglich Verschiebung des Kommas (nur Interpretation)
  - optional Verlust von Genauigkeit mit Abschneiden der Ergebnis-LSBs
- Umgang mit 2er-Komplement/Signed unproblematisch
  - von IEEE Library in VHDL unterstützt

Fixed-Point:

- ca. 0,3 Nachkommastellen Genauigkeit je Fraction-Bit
- vermutlich 25x18 bzw. 18x18 Multiplier
  - 18 Bit meist ausreichend als Operanden
  - 36 Bit Ergebnisse nach der Multiplikation:
- Generic je nach Problem
  - Fraction-Size als konfigurierbarer Parameter

PRNG:

- LFSR
  - primitives Polynomen für maximale Periodenlänge
  - optional LFSR kombinieren: unterschiedliche Polynome/Seeds, Bit-Mixing (nicht umgesetzt)
  - optional Whitening (nicht umgesetzt)
- optional Xorshift (nicht umgesetzt)

## Agentenbasiert

- Teil-Problem muss groß genug sein
- Verteilung von Teil-Problemen an Agenten (einzelne FPGAs)
  - z.B. Teil-Population zur Evolution
  - Cluster
  - möglichst unabhängige Berechnungen der Agenten
  - Kommunikation minimieren
  - Planetensystem
