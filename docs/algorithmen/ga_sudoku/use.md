# Verwendung des genetischen Sudoku Solvers

## Entity: `ga_sudoku`

```vhdl
use work.pkg_sudoku.all;

entity ga_sudoku is
    generic (
        pop_size : natural := 64;
        k : natural := 4;
        mut_bits : natural := 4;
        max_gen : natural := 1000
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const : in std_logic_vector(chr_size-1 downto 0);

        best_chr : out std_logic_vector(chr_size-1 downto 0);
        best_fit : out std_logic_vector(fit_size-1 downto 0);
        done : out std_logic
    );
end entity;
```

### Generics/Konfiguration

| Generic  | Beschreibung                                                                                                                                             |
|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| pop_size | Anzahl der Individuen innerhalb der Population. Besonders bei schweren Sudokus wird eine hohe Populationsgröße empfohlen, um lokalen Optima vorzubeugen. |
| k        | Turniergröße für Selektionsphase.                                                                                                                        |
| mut_bits | Mutationswahrscheinlichkeit pro Block: `P(mut_bits) = 0.5 ^ mut_bits`.                                                                                   |
| max_gen  | Abbruchkriterium: Maximale Anzahl an Generationen, die durchlaufen werden, falls keine optimale Lösung gefunden wird.                                    |

> [!IMPORTANT] HINWEIS
> Die hier noch erkennbare Chromosomengröße `chr_size` sowie Fitnessgröße `fit_size` werden zentral über das `pkg_sudoku`-Package definiert und sollten hier nicht verändert werden.

### Ports

Alle Ports sind high-aktiv (aktive Flanke, Reset und Start bei `1` aktiv).

| Input-Port | Beschreibung                                                                                                                        |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| clk        | Taktsignal                                                                                                                          |
| rst        | synchroner Reset                                                                                                                    |
| start      | Start-Signal (Impuls für 1 Takt ausreichend). Startet den evolutionären Prozess, nachdem das Startsudoku an `const` angelegt wurde. |
| const      | Das ungelöste Sudoku-Starträtsel als flacher Vektor der Breite `chr_size` (324 Bit). Bleibt während des gesamten Laufs konstant.    |

| Output-Port  | Beschreibung                                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------------ |
| best_chr     | bisher bestes Chromosom (kontinuierliche Anpassung)                                                                      |
| best_fit     | Fitness des bisher besten Chromosoms (kontinuierliche Anpassung)                                                         |
| done         | Signalisiert mit '1' das Ende der Verarbeitung (entweder weil Fitness = 0 erreicht wurde oder `max_gen` abgelaufen ist). |

## Verhalten

### Datenvorverarbeitung & Schutzmaske

Ein Sudoku wird im System als flacher Vektor von 324 Bits abgebildet, bei dem jede der 81 Zellen exakt 4 Bits belegt (Zahlenwert 0 für leer, 1 bis 9 für besetzte Felder). Das ungelöste Startsudoku wird fest an den Eingang `const` angelegt. Intern erzeugt das Modul daraus eine unantastbare Schutzschablone (Maske). Jede Zelle des Startsudokus, die ungleich 0 ist, wird blockiert. Dies stellt sicher, dass die genetischen Operatoren (Crossover und Mutation) ausschließlich freie Felder verändern und die logischen Vorgaben des Sudokus zu jedem Zeitpunkt gewahrt bleiben.

Im Sudoku-Package befinden sich Funktionen zum **Serialisieren** und **Deserialisieren** von Sudoku-Feldern:

- `serialize_sudoku` konvertiert ein menschenlesbares Ganzzahl-Array (`t_human_sudoku`) in den flachen 324-Bit-Vektor (`std_logic_vector`), den der genetische Algorithmus für die Verarbeitung benötigt. Dieser Vektor kann direkt an `const` weitergegeben werden.

- `deserialize_sudoku` übernimmt die umgekehrte Aufgabe und wandelt den kompakten 324-Bit-Chromosomenvektor zurück in das 2D-Array-Format.

```vhdl
hs_unsolved := (
        (7, 0, 0,   5, 8, 2,   9, 3, 4),
        (2, 0, 5,   0, 1, 9,   0, 0, 7),
        (0, 0, 3,   0, 0, 0,   2, 0, 1),

        (0, 3, 7,   1, 0, 6,   4, 2, 5),
        (4, 9, 0,   7, 0, 0,   0, 1, 0),
        (0, 5, 2,   0, 3, 8,   7, 0, 0),

        (0, 2, 0,   0, 5, 7,   1, 9, 6),
        (5, 7, 9,   2, 6, 0,   0, 0, 3),
        (6, 0, 0,   0, 4, 3,   5, 7, 2)
    );

chr_const := serialize_sudoku(hs_unsolved);
const <= chr_const;
```

### Vorbereitung & Start

Zu Beginn wird ein System-Reset durchgeführt (`rst = '1'`) und `start = '0'` gesetzt. Das zu lösende Sudoku muss stabil am Port `const` anliegen.

Der Algorithmus wird durch einen Taktimpuls auf `start = '1'` initiiert. Da das Sudoku direkt über den Port `const` eingelesen wird, ist kein vorheriges sequentielles Beschreiben eines RAMs von außen notwendig. Sobald der Algorithmus läuft, beginnt die FSM mit der Initialisierung der Population und startet anschließend die evolutionäre Schleife über maximal `max_gen` Epochen.

> [!WARNING] HARDWARE-HINWEIS
> Uns ist bewusst, dass das Anlegen des Sudokus über den Port `const` auf echter Hardware so nicht möglich ist, da die verfügbaren Pins wahrscheinlich stark überschritten werden.
> Im Zuge der Simulation ist dies allerdings kein Problem und auch ein sequentielles Laden des Sudokus in den RAM, was eine Lösung darstellen würde, hätte keinen signifikanten Einfluss auf die Laufzeit. Eine spätere Optimierung blieb an dieser Stelle aus.

### Evolutionärer Zyklus

In jeder Generation koordiniert das Top-Level-Modul `ga_sudoku` folgende Schritte:

- **Evaluierung:** Das voll-pipelinete Modul `fitness_sudoku` berechnet parallel die Zeilen-, Spalten- und Blockkonflikte für die Individuen einer Generation.

- **Selektion:** Über das Modul `tournament_sel_sudoku` werden sequentiell anhand zweier Gruppen die besten Eltern in einem Turnier ermittelt.

- **Rekombination & Mutation:** Um die Evolution voranzutreiben, erfolgt ein blockweises Crossover der erzeugten Kinder, gefolgt von einer gezielten Swap-Mutation freigegebener Zellen.

Der Algorithmus stoppt und setzt `done <= '1'`, sobald entweder eine perfekte Lösung gefunden wurde (`best_fit = 0`) oder die durch `max_gen` definierte Epochenanzahl erreicht ist.

### Beispiel

Die konkrete Verwendung der Implementierung des genetischen Sudoku Solvers kann am Beispiel eines ungelösten Sudokus demonstriert werden.

Hierfür befinden sich im `/test/ga_sudoku`-Ordner einige `ga_sudoku__tb`-Beispiele.

::: warning WARNUNG
Da das Lösen eines Sudokus unter Umständen länger dauern kann und der gesamte Algorithmus auch nicht gerade wenig Signale beinhaltet, empfehlen wir dringendst die Sudoku-Testbenches ausschließlich über `run.sh` und **NICHT** mit der `wave`-Variante auszuführen.
:::

Nach jeder Generation wird über eine Konsolenausgabe das aktuell beste Individuum inklusive Fitness-Wert menschenlesebar ausgegeben.
Optional kann sich zudem visuell aufbereitet der aktuelle und historische Entwicklungsstand der Generationen im Browser angezeigt werden.
Die genaue Bedienung kann hier entnommen werden: [Live-Sudoku-UI](./live-sudoku-ui.md).

::: tip DEBUG-TIPP
Im Package `/src/util/util.vhd` gibt es Konstante `DEBUG_ENABLE`, über welche ein ausführliches Konsolen-Reporting aktiviert werden kann; die Simulation wird dadurch allerdings verlangsamt.
:::

### Performance

Um die Performance zu evaluieren, wurde die Ausführungszeit (Simulation) der Hardware mit einer Software-Implementierung verglichen. Als Basis für die Software diente ein angepasster Fork des Repositories von [chinyan/Genetic-Algorithm-based-Sudoku-Solver](https://github.com/chinyan/Genetic-Algorithm-based-Sudoku-Solver). An diesem wurden gezielt Änderungen vorgenommen, um ein möglichst ähnliches genetisches Verhalten zu erzeugen und so eine faire Vergleichbarkeit zu gewährleisten.

#### Leistungsvergleich
 
##### Sudoku-Easy `ga_sudoku_easy_tb`

| Implementierung       | Populationsgröße | Generationen bis zur Lösung | Benötigte Zeit |
| :-------------------- | :--------------: | :-------------------------: | -------------: |
| **Software** (Python) | 128              | 12                          | 3.080,00 ms    |
| **Hardware** (VHDL)   | 128              | 10                          | 0,73 ms        |

##### Sudoku-Medium `ga_sudoku_mid_tb`

| Implementierung       | Populationsgröße | Generationen bis zur Lösung   | Benötigte Zeit |
| :-------------------- | :--------------: | :---------------------------: | -------------: |
| **Software** (Python) | 1024             | 188                           | 49.340,00 ms   |
| **Hardware** (VHDL)   | 1024             | nach 27 stagniert; best_fit=3 | 16 ms          |

##### Sudoku-Hard `ga_sudoku_hard_tb`

| Implementierung       | Populationsgröße | Generationen bis zur Lösung   | Benötigte Zeit |
| :-------------------- | :--------------: | :---------------------------: | -------------: |
| **Software** (Python) | 2048             | 138                           | 534.080,00 ms  |
| **Hardware** (VHDL)   | 2048             | nach 47 stagniert; best_fit=2 | 43 ms          |

::: danger PROBLEM: STAGNATION & LOKALE OPTIMA
An dieser Stelle sei erneut darauf hinzuweisen, dass Sudokus sehr komplexe Probleme mit vielen Abhängigkeiten und Unbekannten sind.
Nach unseren Erkenntnissen neigt der evolutionäre Prozess vor allem bei schweren Sudokus mit vielen leeren Feldern zu einer kompletten Stagnation, sobald eine *"fast perfekte"* Lösung gefunden wurde. Beim Python-Fork ist dieses Problem teilweise durch intelligentes Backtracking gelöst.

Dennoch ist der immense Durchsatz-Vorteil des FPGAs beachtlich: Während die Software für das harte Sudoku fast 9 Minuten rechnet, hat die Hardware die evolutionäre Suche bis zum Stagnationspunkt bereits nach nur 43 ms komplett durchlaufen.
:::

Die Hardware-Implementierung erzielt auf dem Kintex-7 eine kritische Pfadlänge bzw. Taktperiode von `14.626 ns` (was einer Taktfrequenz von ca. `68.37 MHz` entspricht).
Damit ist die Hardware-Implementierung bei dem einfachen Sudoku-Beispiel um einen Faktor von über **4200** schneller als die Software. Ein modernerer FPGA mit höherer nativer Taktfrequenz und kürzeren Signallaufzeiten würde diesen Vorsprung rein rechnerisch noch einmal deutlich vergrößern können.

Auch beim genetischen Algorithmus für Sudoku Solver lässt sich somit eine sehr deutliche Beschleunigung bei der Hardware-Implementierung gegenüber einer Software-Implementierung feststellen.

Ergänzend sei noch zu erwähnen, dass das Optimierungspotential des Sudoku-Solvers immer noch nicht komplett ausgenutzt ist und es weiterhin Stellen und Möglichkeiten gibt, an denen noch etwas mehr Geschwindigkeit rausgeholt werden kann.

