# k-Nearest-Neighbors Classifier

## Umsetzbarkeit

- guter erster Kandidat für eine Umsetzung in VHDL
- größtenteils voneinander unabhängige Berechnungen für verschiedene Datenpunkte
  - gut parallelisierbar
  - Pipelining und Streaming sehr gut möglich
  - finden bester Kandidaten während Berechnung
- Arithmetik passend
  - Vergleich der Distanzen bei Fixed-Point = Subtraktion
  - Distanzberechnung (euklidisch)
    - Wurzel: Verzicht, da nur Vergleich
    - Quadrat: entspricht Multiplikation mit sich selbst, gut möglich
    - Addition, Subtraktion: trivial

## Struktur

- Idee: erstmal MVP
- zuerst Speicherung zu klassifizierender Datenpunkt
- Eingang Datenpunkt (später mit Flag: neu)
- TODO

## MVP

TODO: Kommunikation mit CPU

- Idee Kommunikation: Testbench, die Signale verbindet? Start-Daten und CPU in Testbench simulieren?
  Voraussetzung: Datensatz in RAM geladen

1. neuen, zu klassifizierenden Datenpunkt übermitteln
2. für jeden vorhandenen Datenpunkt
   1. Datenpunkt lesen
   2. Distanzberechnung
   3. Einsortieren
