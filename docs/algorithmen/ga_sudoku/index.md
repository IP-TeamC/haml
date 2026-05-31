# Sudoku Solver

## Struktur

```
ga_sudoku: Top-Level-Modul für genetischen Sudoku-Solver (FSM)
│
├─ rng_bank: Liefert einen Bus an Zufallsbits für alle benötigten Vorgänge 
│  └─ n × lfsr: Bestehend aus mehreren linear rückgekoppelten Schieberegistern
│
├─ pop_mem_sudoku: Zentrale Speichereinheit für die Population
│  └─ dual_ram: Dual-Port-RAM, das Chromosomen und deren Fitness-Werte speichert
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

## Funktionsweise

Das Modul [`ga_sudoku`](./#ga_sudoku.vhd) bildet die zentrale Steuereinheit. Es koordiniert als Finite State Machine den gesamten evolutionären Ablauf. Die Verwaltung der der Individuen (Chromosomen) erfolgt über ein Ping-Pong-Dual-RAM-Verfahren, bei dem die aktuelle Generation gelesen und die neu erzeugte Generation parallel an anderer Stelle geschrieben wird. Der allgemeine Ablauf lässt sich zyklisch in vier+1 zentrale Phasen unterteilen:

### 0. Initialisierungsphase (`S_INIT_...`)

Nach dem Anlegen des `start`-Signals wird das vorgegebene, unvollständige Sudoku (`const`) eingelesen. Das Modul [`chr_init_sudoku`](./#chr_init_sudoku.vhd) generiert bis zur vorgegebenen Populationsgröße (`pop_size`) zufällige initiale Individuen und legt diese im [`pop_mem_sudoku`](./#pop_mem_sudoku.vhd) ab.
Feste, vom Rätsel vorgegebene Zellen werden dabei über eine Konstanten-Maske (`const_mask`) fixiert. Alle anderen leeren Zellen werden blockweise mit zufälligen Werten initialisiert.

### 1. Evaluationsphase (`S_EVAL_...`)

Diese Phase dient zur Evaluierung bzw. Bewertung der Güte/Konfliktfelder (`fitness`) jedes einzelnen Individuums der aktuellen Generation. Die FSM liest nacheinander alle Chromosomen einer Generation aus dem Speicher und übergibt sie an das Modul [`fitness_sudoku`](./#fitness_sudoku.vhd), welches für die genaue Fitnessberechnung verantwortlich ist. Die evaluierte Fitness wird im Zusammenhang mit dem Individuum abgespeichert. Wird ein neues, historisches bestes Individuum gefunden, wird dieses zusätzlich in den Registern `best_chr_r` und `best_fit_r` vermerkt, um es für den späteren Elitismus bereitzuhalten oder am Ende des Suchprozesses als Lösung auszugeben.

### 2. Abbruch- und Kontrollphase (`S_CHECK`)

Am Ende jeder Generation prüft die FSM, ob ein Abbruchkriterium erfüllt ist:

- **Erfolg:** Hat das beste Individuum eine Fitness von `0` erreicht, ist das Sudoku gelöst. Das gelöste Sudoku wird an `best_chr` ausgegeben und das `done`-Signal wird gesetzt.
- **Limit:** Wird die maximale Generationsanzahl `max_gen` erreicht, stoppt der Prozess, um Endlosschleifen bei extrem schweren oder nicht lösbaren Rätseln zu verhindern.
- Anderenfalls wir der Generationszähler (`gen_ctr`) inkrementiert und die Evolution fortgesetzt.

### 3. Elitismus und Selektionsphase (`S_ELITE_..., S_SEL_...`)

Um einen evolutionären Fortschritt zu sichern, wird zunächst das absolut beste Individuum der alten Generation unverändert an Slot 0 der neuen Generation kopiert. Für alle weiteren freien Plätze wird eine Turnierauswahl durchgeführt. Das Modul [`tournament_sel_sudoku`](./#tournament_sel_sudoku.vhd) ließt die Fitnesswerte von `k` zufälligen Kandidaten aus dem RAM und lässt diese gegeneinander antreten. Dieser Prozess läuft zweimal parallel ab, um zwei fitte Elternteile (`idx_a_buf` und `idx_b_buf`) zu bestimmen.

### 4. Reproduktionsphase (`S_REPR_..., S_CX_..., S_MUT_..., S_WRITE_...`)

Die ausgewählten Elternteile werden aus dem Speicher geladen, um genetisch variierte Nachkommen zu zeugen.

- **Crossover ([`crossover_sudoku`](./#crossover_sudoku.vhd)):** Die Gitter der beiden Eltern werden blockweise miteinander kombiniert. Ein Zufallsvektor (`rnd_cx`) entscheidet pro Block, ob die Daten getauscht werden. Hierbei entstehen gleichzeitig zwei Kinder (Kind A und Kind B).

- **Mutation ([`mutation_sudoku`](./#mutation_sudoku.vhd)):** Unter Berücksichtigung der unantastbaren Startmaske werden zufällige Werte innerhalb der Blöcke vertauscht.

- **Schreiben:** Die beiden modifizierten Kinder werden im Anschluss auf die Plätze `repr_ctr` und `repr_ctr + 1` der neuen Generation geschrieben.

Nach dem Schreiben der neuen Kinder ins RAM wird geprüft, ob die neue Generation vollständig bevölkert ist.

- Falls die neue Generation noch nicht voll ist, wird direkt in Phase 3 zurückgesprungen und es werden erneut zwei neue Eltern selektiert und die nächsten Kinder gezeugt. Die Schleife aus Selektion und Reproduktion wiederholt sich so lange, bis alle `pop_size` Plätze der neuen Generation besetzt sind.

- Falls die neue Generation voll ist, wird der `ping_pong`-Zeiger invertiert, wodurch die eben geschriebene, neue Generation zur aktuellen wird. Die FSM springt zurück in Phase 1, um den nächsten vollständigen Evolutionszyklus zu starten.
