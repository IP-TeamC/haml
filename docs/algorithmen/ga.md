# Genetische Algorithmen

## Umsetzbarkeit

- ja, aber später mit Einschärnkungen
- Probleme:
  - Zufallszahlen: LFSR
  - evtl. hoher Speicherbedarf
  - Auswahl bester Individuen aufwändig (vereinfachte Auswahl, verschiedene Möglichkeiten)
- sehr gute Parallelisierung
  - parallele Anpassung der Population (Mutation, Crossover)
  - parallele Berechnung der Fitness-Funktion
  - Einschränkung: RAM
- agentenbasiert sehr gut möglich
  - z.B. Teil-Populationen

## Idee

- Population = Array von Individuen
  - Individuum = Chromosom
    - Aufteilung in Blöcke/Gene
    - Bitvektor (Aufteilung je nach Variante bei Fitness/Crossover/Mutation)
    - einheitliche Entity, mehrere Architectures (Interface?)

- Ablauf:
  - Fitness berechnen
  - Selektion der besten
  - Crossover von ausgewählten
  - Mutation der Kinder
  - Austausch der Population

- Fitness:
  - Funktion individuell je Problem: liefert Fixed-Point
  - Fitness mit Individuum speichern
    - parallele Berechnung

- Selektion:
  - k-Top (Elite)
  - Tournament: zufällige Teilnehmer, besten auswählen
    - parallel
  - Kombination k-Top und Tournament

- Crossover: parallel
  - generell:
    - 1-/n-Punkt-Crossover:
      - n=1 1. Hälfte von Parent 1, 2. Hälfte von Parent 2
      - n=2 Ausschnitt von Parent 1 übernehmen, den anderen von Parent 2
    - Uniform Crossover
      - je Gen/Bit zufällig Parent bestimmen (Maske)
    - mehrere Parents
  - Permutationen
    - Position-based Crossover: bestimmte Stellen von Parent 1 übernehmen, fehlende
    - Order Crossover: Ausschnitt von Parent 1 übernehmen, nicht vorhandene von Parent 2 auffüllen (z.B. Travelling Salesman)

- Mutation: parallel
  - generell:
    - Toggle/Bit-Flip
    - zufällig bestimmte Bereiche ersetzen
  - Permutationen
    - Swap (innerhalb Chromosom, z.B. Travelling Salesman)
    - Inversion (innerhalb Chromosom, z.B. Travelling Salesman)
    - zufällig bestimmte Bereiche tauschen

- Austausch der Population:
  - Ping-Pong-RAM (genug RAM vorhanden?): A lesen, B schreiben -> danach B lesen, A schreiben -> ...
  - kompletter Austausch durch Kinder
    - Variante: k-Top bleiben, Rest austauschen
  - nur einige austauschen:
    - schlechteste, zufällige, Tournament
  - Teil-Populationen: Planeten/Inseln
    - Migration der besten

- Parallelisierung
  - Population auf mehrere RAM-Blöcke aufteilen
  - je RAM ein "Agent"

- verschiedene Probleme:
  - unterschiedliche Fitnessfunktionen (gleiche Entity, andere Architektur)
    - sehr problem-spezifisch
    - Idee: "Interface"
  - unterschiedliche Crossover-/Mutations-Methoden (gleiche Entity, andere Architektur)
    - Problem-Kategorien: Permutation, "unabhängige" Features
    - Berücksichtigung von Constraints
    - Idee: "Interface"
  - TSP: jede Stadt ein Gen (enthält Position) oder jede Position ein Gen (enthält Stadt)
  - Knapsack: jedes Item ein Gen (enthält Anzahl)
  - Sudoku: jedes Feld ein Gen (enthält Zahl)
  - math. Funktion: jeder Koeffizient ein Gen (enthält FP)
