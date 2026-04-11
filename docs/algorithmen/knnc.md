# k-Nearest-Neighbors Classifier

## Umsetzbarkeit

- ja, guter erster Kandidat
- größtenteils voneinander unabhängige Berechnungen für verschiedene Datenpunkte
  - gut parallelisierbar
  - Pipelining und Streaming wahrscheinlich auch gut möglich
  - finden bester Kandidaten während Berechnung
- Arithmetik passend
  - Vergleich der Distanzen bei Fixed-Point = Subtraktion
  - Distanzberechnung (euklidisch)
    - Wurzel: Verzicht, da nur Vergleich!
    - Quadrat: entspricht Multiplikation mit sich selbst, möglich
    - Addition, Subtraktion: trivial
- agentenbasiert möglich

## Struktur

- Idee: erstmal MVP
- zuerst Speicherung zu klassifizierender Datenpunkt
- Eingang Datenpunkt (später mit Flag: neu)
- TODO

## MVP

Voraussetzung: Datensatz in RAM geladen

1. neuen, zu klassifizierenden Datenpunkt übermitteln
2. für jeden vorhandenen Datenpunkt
   1. Datenpunkt lesen
   2. Distanzberechnung
   3. Einsortieren
