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

- **knnc**: Top-Level-Modul für k-Nearest-Neighbors
  - **ram**: RAM für die Klassen und je Feature
  - **classifier**: Controller für RAM-Zugriff, Distanzberechnung, Komparator, Selektor
    - **signed_dist**: Distanzberechnung zwischen zwei Datenpunkten/Vektoren
      - **adder_tree**: Adder-Tree zum Pipelining vieler akkumulierter Additionen
        - **adder_tree_stage**: Pipeline-Stage des Adder-Trees
    - **ktop**: Komparator hält eine Liste der k kürzesten Distanzen
      - **ktop_stage**: Pipeline-Stage und Listen-Eintrag des Komparators
    - **kselect**: Selektor der häufigsten Klasse

## Funktionsweise

Voraussetzung: Datensatz und zu klassifizierender Datenpunkt bereits in den RAM geladen

1. `classifier` liest zu klassifizierenden Datenpunkt aus dem RAM
2. `classifier` liest ersten Datenpunkt X aus dem RAM und startet `signed_dist`
3. `signed_dist` berechnet die Distanz zwischen zu klassifizierendem Datenpunkt und Datenpunkt X und startet `ktop`
4. `ktop` nimmt die Distanz und Klasse des Datenpunkts X auf (wenn kürzer als vorhandene) und startet `kselect`
5. `kselect` wählt die häufigste Klasse in der k-Top-Liste aus und gibt an, dass ein erstes gültiges Ergebnis vorliegt
6. wiederhole ab **2.** bis zum Erreichen der letzten Adresse
7. gebe letztes gültiges Ergebnis aus

Zwischen **2.** und **5.** wird intensiv auf Pipelining und Streaming gesetzt.
Die Berechnungen sind in viele Pipeline-Stages aufgeteilt, um die Taktfrequenz zu erhöhen.
Zudem wird kontinuierlich mit jedem Takt ein neuer Datenpunkt aus dem RAM der Pipeline zur Verarbeitung übergeben.
