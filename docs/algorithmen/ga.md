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
- agentenbasiert sehr gut möglich
  - z.B. Teil-Populationen
