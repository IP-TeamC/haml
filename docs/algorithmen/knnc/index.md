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
  - **ram**: RAM je Feature und zusätzlich für die Klasse
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

## Komponenten

### knnc

Das Top-Level-Modul des k-Nearest-Neighbors Classifiers bündelt den Classifier mit den Block-RAMs, in denen der Datensatz gespeichert wird.
Dieses Modul ermöglicht zusätzlich das initiale Laden des Datensatzes in den RAM,
wobei jedes Feature bzw. die Klasse separat nacheinander in die RAM-Blöcke (Part) geschrieben wird (Schreiben nur vor dem Start oder nach Beendigung der Klassifikation erlaubt).
Ansonsten ist dieses Modul lediglich eine Top-Level-Strukturbeschreibung, die den `classifier` und die verschiedenen `ram`-Blöcke enthält.

### ram

Je Block-RAM wird ein Feature gespeichert. Ein weiterer Block-RAM enthält die Klassen der Datenpunkte.
Die Zeile nach der mit `mark_end` in `knnc` markierten Adresse enthält den zu klassifizieren Datenpunkt (Klasse unbekannt/nicht vorhanden).
Es wird ein Single-Port Block-RAM verwendet.

### classifier

Der `classifier` ist der Controller für den RAM-Zugriff (`ram`), die Distanzberechnung (`signed_dist`), den Komparator (`ktop`) und den Selektor (`kselect`).
Hier findet die tatsächliche Berechnung/Klassifikation in einer Pipeline der drei zuletzt genannten Komponenten statt.
Anfangs wird der zu klassifizierende Datenpunkt aus dem RAM geladen und in einem Register gespeichert.
Anschließend werden alle bekannten/klassifizierten Datenpunkte des Datensatzes (neuer Datenpunkt je Takt) aus dem RAM geladen und der Distanzberechnung übergeben.
Diese besteht intern ebenfalls aus einer Pipeline und gibt die Klasse sowie Distanz des bekannten Datenpunktes zum zu klassifizierenden Datenpunkt anschließend an den Komparator weiter,
welcher lediglich die k besten Kandidaten speichert und diese Liste an den Selektor weitergibt.
Im Selektor wird die häufigste Klasse bestimmt, welche das Ergebnis der Klassifikation darstellt.

### signed_dist

Die Distanzberechnung ermittelt das Quadrat der euklidischen Distanz zwischen zwei Datenpunkten (Vektoren) in einer Pipeline.
(aufgrund des Verzichts auf das Ziehen der Wurzel zur Performance-Optimierung, da die Distanz lediglich zum Vergleich genutzt wird).
Zunächst wird in der 1. Pipeline-Stage für jedes Feature die Differenz der beiden Datenpunkte ermittelt.
Dann werden die Differenzen in der 2. Pipeline-Stage quadriert und abschließend alle in der 3. Pipeline-Stage addiert.
Um eine Addition sehr vieler Werte in einem Takt zu verhindern, wird die 3. Pipeline-Stage zusätzlich im Adder-Tree gepipelined (weitere Pipeline-Stufen).

### adder_tree, adder_tree_stage

Der Adder-Tree besteht aus mehreren Adder-Tree-Stages.
Jede Adder-Tree-Stage addiert 2 Werte (bzw. gibt die einzige Eingabe weiter bei einer ungeraden Anzahl zu addierender Werte).
Daraus ergibt sich ein binärer Additionsbaum, der aus `ceil(log2(n))` Stufen besteht (mit n = Anzahl zu addierender Werte).
Zusätzlich können in jeder Stufe Daten zusätzlich mitgegeben werden, welche mit der Summe synchron wieder unverändert ausgegeben werden.
Beim k-Nearest-Neighbors Classifier ist das die Klasse des Datenpunktes für den die Distanz zum zu klassifierenden Datenpunkt berechnet wird,
so dass die Distanz und Klasse aus der Distanzberechnung direkt an den Komparator weitergegeben werden können.

### ktop, ktop_stage

Der Komparator besteht aus k Stages, die insgesamt die k besten Distanzen mit der dazugehörigen Klasse speichern.
Kontinuierlich (mit jedem Takt, wenn das Startsignal gesetzt ist) erhält die erste der Stages eine neue Distanz/Klasse aus der Distanzberechnung.
Ist diese neue Distanz besser/kleiner als die aktuell gespeicherte, wird die aktuelle gespeicherte an die nächste Stage weitergegeben und die neue Distanz/Klasse gespeichert.
Ansonsten wird die neue Distanz an die nächste Stage weitergegeben und die aktuell gespeichert bleibt unverändert.
Schlechte/große Distanzen werden also durch den Komparator durchgeschoben, ohne dass sie einen Wert ersetzen.
Damit ist keine konkrete Reihenfolge garantiert, jedoch aber dass die Liste die k besten/kürzesten Distanzen/Klassen enthält.

### kselect

Der Selektor wählt aus der Liste der k besten Distanzen/Klassen des Komparators die am häufigsten auftretende Klasse aus.
Dafür wird jede Klasse gezählt und anschließend der größte Wert bestimmt.
Die Wahl bei gleich häufig auftretenden Klassen ist nicht explizit definiert.
In der Implementierung wird hierbei jedoch die Klasse mit der geringsten binären Kodierung gewählt.
