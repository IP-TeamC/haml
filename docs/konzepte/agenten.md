# Agenten

## Definition

- autonomes System zur Bearbeitung bestimmter Aufgaben
- autonome Verarbeitungseinheit zur Lösung von (Teil-)Problemen
- 1 Agent = 1 FPGA

## Umsetzungsmöglichkeiten für Genetische Algorithmen

### Agent je Individuum

- viel zu kleines Teil-Problem
- zu hoher Ressourcenbedarf (sehr viele FGPAs)
- <strong>NEIN</strong>

### Agent je Teil-Population

- gesamte Population aufteilen
- Agent je Teil-Population
- Mutation und Bewertung für Generation aufteilen
- globaler Speicher für Population/Vergleich
  - nur die besten überleben

### Agent je gesamter Population

- Agents = Inseln mit eigener Population
- Evolution innerhalb der Inseln
- Migration nach einer bestimmten Anzahl Generationen kombinieren
  - beste Individuen besuchen andere/nächste Insel (Ring-"Invasion")
  - Mischen der Individuen
  - globale Auswahl der besten Individuen (dann gleicher Start für alle)

### Migration

- periodisch (nach einer bestimmten Anzahl Generationen)?
- asynchron ohne globalen Takt?
- Ring statt fully-connected oder zufällig
- minimal: nur Genome übertragen
- besser nur kleinen Anteil austauschen
