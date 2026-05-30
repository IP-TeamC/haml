# Sudoku Solver

## Struktur

```
ga_sudoku: Top-Level-Modul für genetischen Sudoku-Solver (FSM)
│
├─ rng_bank: Liefert einen Bus an Zufallsbits für alle benötigten Vorgänge 
│  └─ n × lfsr: Bestehend aus mehreren linear rückgekoppelten Schieberegistern
│
├─ pop_mem_sudoku: Zentrale Speichereinheit für die Population
│  └─ dual_ram: Dual-Port-RAM, das Chromosomen und deren Fitness-Werte sichert
│
├─ chr_init_sudoku: Erzeugt zufällige Start-Population
│
├─ fitness_sudoku: Einheit zur Bewertung der Richtigkeit eines Sudokus
│  └─ adder_tree: Adder-Tree zum Pipelining vieler akkumulierter Additionen 
│     └─ adder_tree_stage: Pipeline-Stage des Adder-Trees
│
├─ tournament_sel_sudoku: Turnierauswahl der besten Individuen
│
├─ crossover_sudoku: Crossover-Einheit; kombiniert blockweise Gene zweier Eltern 
│
├─ mutation_sudoku (Kind A): Mutationseinheit für das erste erzeugte Kind
└─ mutation_sudoku (Kind B): Mutationseinheit für das zweite erzeugte Kind
:
└─ pkg_sudoku: Zentrales Sudoku-Package für generelle Funktionen und Konstanten
```
