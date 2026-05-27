# Genetischer Algorithmus für lineare Regression

## Steady State Genetic Algorithm

- Population = Array von Individuen
  - Individuum = Chromosom
    - Aufteilung in Blöcke/Gene (Koeffizienten)
    - Bitvektor

- Ablauf:
  - Intialisierung
    - zufällige Population generieren
    - Fitness für Population berechnen (im RAM speichern)
  - iteratives Training
    - separate Tournament Selections für Wahl von 2 Eltern
    - Crossover erzeugt Kind
    - Mutation vom Kind
    - Fitness vom Kind berechnen
    - Tournament Replacement
      - Tournament bestimmt schlechtestes Individuum
      - nur ersetzen, wenn Kind besser

- Module:
  - Loader: DP w
  - pop_init: (DP r), CHR r/w
  - Tournament Selection: CHR r
  - Crossover: -
  - Mutation: -
  - Fitness: DP r
  - Tournament Replacement: CHR r/w

- Crossover
  - 1-/n-Punkt-Crossover:
    - n=1 1. Hälfte von Parent 1, 2. Hälfte von Parent 2
    - n=2 Ausschnitt von Parent 1 übernehmen, den anderen von Parent 2
  - Uniform Crossover
    - je Gen/Bit zufällig Parent bestimmen (Maske)
  - mehrere Parents

- Mutation
  - Toggle/Bit-Flip
  - zufällig bestimmte Bereiche ersetzen
