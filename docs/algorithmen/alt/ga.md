# Genetische Algorithmen (alt)

## Umsetzbarkeit

- ja, aber später mit Einschärnkungen
- Probleme:
  - Zufallszahlen: LFSR
  - evtl. hoher Speicherbedarf
  - Auswahl bester Individuen aufwändig (vereinfachte Auswahl, verschiedene Möglichkeiten)
- sehr gute Parallelisierung
  - parallele Anpassung der Population (Mutation, Crossover)
  - parallele Berechnung der Fitness-Funktion
- agentenbasiert sehr gut möglich
  - z.B. Teil-Populationen

## Idee

- Agent je gesamter Population
- 1 Agent = 1 Insel
  - Evolution unabhängig voneinander
  - eigene Population (Crossover/Mutation), Selektion, Fitness
  - Migration/Austausch selten (zufällig mit Wahrscheinlichkeit)
  - Verzicht auf globalen Takt
- Ring-Invasion: beste n Individuen zum nächsten Agent im Ring migrieren
  - asynchron, Ring, n eher klein
- Auswahl der zu migrierenden Individuen
  - k-Top: n/2 beste Individuen (Elite)
  - Tournament: beste aus n/2 Runden
