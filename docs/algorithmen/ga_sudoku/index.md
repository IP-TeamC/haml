# Genetischer Sudoku Solver

## Umsetzbarkeit

Die Umsetzbarkeit kann analog zu den Überlegung der linearen Regression betrachtet werden: [Lineare Regression: Umsetzbarkeit](/algorithmen/ga_linreg/#umsetzbarkeit)

Auch wenn die Umsetzung zunächst einigermaßen vielversprechend klingt, hat sich schnell gezeigt, dass ein genetischer Algorithmus zum lösen eines Sudokus keinesfalls optimal ist.

Im Zuge der Entwicklung wurden zunächst eine nicht unbedingt problemspezifischen Lösung verfolgt, mit der Hoffnung, etwaige Komponenten wie bspw. Mutations- oder Tournament-Module in anderen genetischen Algorithmen wiederverwenden zu können. Dies führte jedoch dazu, dass selbst nach stundenlanger Simulation nur ein geringer Erfolg erkennbar war und selbst leichte Sudokus nicht gelöst werden konnten, da der Algorithmus in einer Vielzahl lokaler Optima gefangen blieb. Erst durch eine Änderung der Mutations- und Crossover-Strategie von reinem Zufall hin zu einer blockweisen Operation konnten erste Erfolge erzielt werden.

Häufig erreicht das System zügig ein Individuum mit nur noch sehr wenigen verbleibenden Konflikten (z. B. 2 oder 3 verbleibende Fehler). Um diese letzten Fehler aufzulösen, wäre mathematisch jedoch eine temporäre, drastische Verschlechterung der Fitness notwendig, da bestehende Teil-Lösungen wieder aufgebrochen werden müssten. Da die Selektionsstrategie des Genetischen Algorithmus primär auf die Erhaltung der besten Fitnesswerte ausgerichtet ist, werden solche temporären Verschlechterungen systematisch unterdrückt. Die Population fluktuiert in der Folge nur noch minimal um diesen Zustand herum und der Algorithmus stagniert vollständig in einem lokalen Optimum. Leichte Sudokus sind davon weniger betroffen, als schwerere.

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
├─ chr_init_sudoku: Erzeugt zufällige Start-Individuen
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

Das Modul [`ga_sudoku`](./#ga_sudoku) bildet die zentrale Steuereinheit. Es koordiniert als Finite State Machine den gesamten evolutionären Ablauf. Die Verwaltung der der Individuen (Chromosomen) erfolgt über ein Ping-Pong-Dual-RAM-Verfahren, bei dem die aktuelle Generation gelesen und die neu erzeugte Generation parallel an anderer Stelle geschrieben wird. Der allgemeine Ablauf lässt sich zyklisch in vier+1 zentrale Phasen unterteilen:

### 0. Initialisierungsphase (`S_INIT_...`)

Nach dem Anlegen des `start`-Signals wird das vorgegebene, unvollständige Sudoku (`const`) eingelesen. Das Modul [`chr_init_sudoku`](./#chr_init_sudoku) generiert bis zur vorgegebenen Populationsgröße (`pop_size`) zufällige initiale Individuen und legt diese im [`pop_mem_sudoku`](./#pop_mem_sudoku) ab.
Feste, vom Rätsel vorgegebene Zellen werden dabei über eine Konstanten-Maske (`const_mask`) fixiert. Alle anderen leeren Zellen werden blockweise mit zufälligen Werten initialisiert.

### 1. Evaluationsphase (`S_EVAL_...`)

Diese Phase dient zur Evaluierung bzw. Bewertung der Güte/Konfliktfelder (`fitness`) jedes einzelnen Individuums der aktuellen Generation. Die FSM liest nacheinander alle Chromosomen einer Generation aus dem Speicher und übergibt sie an das Modul [`fitness_sudoku`](./#fitness_sudoku), welches für die genaue Fitnessberechnung verantwortlich ist. Die evaluierte Fitness wird im Zusammenhang mit dem Individuum abgespeichert. Wird ein neues, historisches bestes Individuum gefunden, wird dieses zusätzlich in den Registern `best_chr_r` und `best_fit_r` vermerkt, um es für den späteren Elitismus bereitzuhalten oder am Ende des Suchprozesses als Lösung auszugeben.

### 2. Abbruch- und Kontrollphase (`S_CHECK`)

Am Ende jeder Generation prüft die FSM, ob ein Abbruchkriterium erfüllt ist:

- **Erfolg:** Hat das beste Individuum eine Fitness von `0` erreicht, ist das Sudoku gelöst. Das gelöste Sudoku wird an `best_chr` ausgegeben und das `done`-Signal wird gesetzt.
- **Limit:** Wird die maximale Generationsanzahl `max_gen` erreicht, stoppt der Prozess, um Endlosschleifen bei extrem schweren oder nicht lösbaren Rätseln zu verhindern.
- Anderenfalls wir der Generationszähler (`gen_ctr`) inkrementiert und die Evolution fortgesetzt.

### 3. Elitismus und Selektionsphase (`S_ELITE_..., S_SEL_...`)

Um einen evolutionären Fortschritt zu sichern, wird zunächst das absolut beste Individuum der alten Generation unverändert an Slot 0 der neuen Generation kopiert. Für alle weiteren freien Plätze wird eine Turnierauswahl durchgeführt. Das Modul [`tournament_sel_sudoku`](./#tournament_sel_sudoku) ließt die Fitnesswerte von `k` zufälligen Kandidaten aus dem RAM und lässt diese gegeneinander antreten. Dieser Prozess läuft zweimal parallel ab, um zwei fitte Elternteile (`idx_a_buf` und `idx_b_buf`) zu bestimmen.

### 4. Reproduktionsphase (`S_REPR_..., S_CX_..., S_MUT_..., S_WRITE_...`)

Die ausgewählten Elternteile werden aus dem Speicher geladen, um genetisch variierte Nachkommen zu zeugen.

- **Crossover ([`crossover_sudoku`](./#crossover_sudoku)):** Die Gitter der beiden Eltern werden blockweise miteinander kombiniert. Ein Zufallsvektor (`rnd_cx`) entscheidet pro Block, ob die Daten getauscht werden. Hierbei entstehen gleichzeitig zwei Kinder (Kind A und Kind B).

- **Mutation ([`mutation_sudoku`](./#mutation_sudoku)):** Unter Berücksichtigung der unantastbaren Startmaske werden zufällige Werte innerhalb der Blöcke vertauscht.

- **Schreiben:** Die beiden modifizierten Kinder werden im Anschluss auf die Plätze `repr_ctr` und `repr_ctr + 1` der neuen Generation geschrieben.

Nach dem Schreiben der neuen Kinder ins RAM wird geprüft, ob die neue Generation vollständig bevölkert ist.

- **Falls die neue Generation noch nicht voll ist,** wird direkt in Phase 3 zurückgesprungen und es werden erneut zwei neue Eltern selektiert und die nächsten Kinder gezeugt. Die Schleife aus Selektion und Reproduktion wiederholt sich so lange, bis alle `pop_size` Plätze der neuen Generation besetzt sind.

- **Falls die neue Generation voll ist,** wird der `ping_pong`-Zeiger invertiert, wodurch die eben geschriebene, neue Generation zur aktuellen wird. Die FSM springt zurück in Phase 1, um den nächsten vollständigen Evolutionszyklus zu starten.

## Komponenten

### ga_sudoku

Dies ist das Top-Level-Steuermodul, welches den gesamten Evolutionsprozess koordiniert. Es verwaltet den Zugriff auf das Populations-RAM und steuert den Datenfluss zwischen der Fitness-Evaluierung, der Selektion und des Crossovers sowie der Mutation. Das Modul iteriert über Generationen hinweg, überwacht den Abbruch des Algorithmus bei Erreichen einer fehlerfreien Lösung.

### pop_mem_sudoku

Die zentrale Speichereinheit verwaltet die gesamte Population. Sie kombiniert das Chromosom und den dazugehörigen Fitnesswert zu einem gemeinsamen Datenwort (`chr_size + fp_size`). Die Komponente instanziiert ein Dual-Port-RAM (`dual_ram`), bei dem die Adressbreite künstlich um 1 Bit erhöht ist. Dieses zusätzliche Bit dient als `ping_pong`-Zeiger: Während ein Port die aktuelle Generation stabil für die Selektion und Evaluation bereitstellt, kann der zweite Port zeitgleich und völlig konfliktfrei die neu erzeugten Kinder der nächsten Generation an die andere Speicherhälfte schreiben.

### chr_init_sudoku

Diese Komponente übernimmt die Generierung eines initialen Individuums bzw. der Start-Population. Das unvollständige Sudoku (`const` & `const_mask`) wird zunächst blockweise gescannt und existierende Ziffern werden aus der Liste der verfügbaren Block-Ziffern herausgefiltert. Leere Zellen werden anschließend mit den verbleibenden Ziffern in zufälliger Reihenfolge aufgefüllt, indem Zufallsbits der `rng_bank` als Auswahl-Index dienen.

::: info
Dies garantiert, dass bereits bei der Initialisierung jeder 3×3-Block eine gültige Permutation der Zahlen 1 bis 9 enthält. Zusammen mit der Mutationsstrategie werden dadurch lokale Optima signifikant verringert.
:::

### fitness_sudoku

Diese Einheit bewertet die Güte eines Sudoku-Individuums, indem sie die Anzahl der Regelverstöße zählt. Sobald `start` anliegt, werden zeitgleich alle doppelten Zahlen in allen Zeilen, Spalten und Blöcken berechnet. Um die Summe der Konfliktsignale schnell und taktfrequenz-optimiert zu berechnen, leitet das Modul die Werte in eine pipelined Addierer-Baumstruktur (`adder_tree`). Ist das Chromosom ungültig, weil bspw. feste Zellen des Sudokus verändert wurden, wird die Fitness auf das Maximum gesetzt; andernfalls entspricht das Ergebnis der Summe aller Konflikte, wobei eine Fitness von `0` die perfekte Lösung bedeutet.

### tournament_sel_sudoku

Dieses Modul ermittelt zwei Elternteile für die Reproduktion über das Verfahren der Turnierauswahl. Über den Eingang `cand_in` erhält die Komponente zwei Gruppen von je `k` zufälligen Populations-Indizes. Die übergeordnete FSM liest nacheinander die Fitnesswerte dieser Kandidaten aus dem RAM und füttert sie sequentiell über `fit_in` in dieses Modul ein. Die Komponente vergleicht die Werte innerhalb der beiden Turniere und speichert jeweils den Index mit der geringsten Konfliktanzahl (der besten Fitness) ab. Am Ende werden die Indizes der beiden Turniersieger (`idx_a`: Eltern A und `idx_b`: Eltern B) ausgegeben.

### crossover_sudoku

Diese Einheit kombiniert das Erbgut zweier selektierter Elternteile (`parent_a`, `parent_b`), um gleichzeitig zwei neue Kinder zu zeugen. Die Kreuzung erfolgt rein blockbasiert in einem einzigen Taktzyklus: Ein Zufallsvektor (`rnd_blk`) liefert für jeden der 9 Sudoku-Blöcke ein Bit. Ist das Bit `1`, werden die gesamten 3×3-Blöcke zwischen den Eltern getauscht (Kind A erhält den Block von Eltern B, Kind B den von Eltern A). Ist das Bit `0`, bleiben die Blöcke unverändert.

::: info
Die fest vorgegebenen Zellen des Sudokus werden durch diese Crossover-Strategie beibehalten. Ebenfalls beleibt die fundamentale Eigenschaft (Zahlen 1–9 pro Block) fehlerfrei erhalten.
:::

### mutation_sudoku

Dieses Modul ist für die Gen-Mutation eines Kindes verantwortlich. Zuerst prüft das Modul, ob die Mutationswahrscheinlichkeit (`mut_bits`) für diesen Durchlauf überhaupt zutrifft. Wenn ja, wird über `rnd_blk` ein zufälliger 3×3-Block ausgewählt. Innerhalb dieses Blocks bestimmt das Modul mithilfe von `rnd_pos_a` und `rnd_pos_b` zwei Zellen. Sofern beide Zellen laut Maske frei veränderbar sind, werden ihre Werte vertauscht.

::: info
Da dieser "Swap" innerhalb desselben Blocks stattfindet, bleibt auch hier die Block-Integrität (keine doppelten Zahlen im Block) gewährleistet.
:::

### pkg_sudoku

Dient als zentrales Package und fungiert als Abstraktionsschicht, indem es ein einheitliches Datenformat, das Aussehen des Sudokus und zentrale Funktionen definiert. Es enthält unter anderem Funktionen zum **Data-Mapping**, **Konflikterkennung**, **Constraint-Management** und **Debugging**.
