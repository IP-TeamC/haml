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
| start      | Start-Signal (Impuls für 1 Takt ausreichend). Startet den evolutionären Prozess, nachdem das Starträtsel an `const` angelegt wurde. |
| const      | Das ungelöste Sudoku-Starträtsel als flacher Vektor der Breite `chr_size` (324 Bit). Bleibt während des gesamten Laufs konstant.    |

| Output-Port  | Beschreibung                                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------------ |
| best_chr     | bisher bestes Chromosom (kontinuierliche Anpassung)                                                                      |
| best_fit     | Fitness des bisher besten Chromosoms (kontinuierliche Anpassung)                                                         |
| done         | Signalisiert mit '1' das Ende der Verarbeitung (entweder weil Fitness = 0 erreicht wurde oder `max_gen` abgelaufen ist). |

## Verhalten

### Datenvorverarbeitung & Schutzmaske

Ein Sudoku wird im System als flacher Vektor von 324 Bits abgebildet, bei dem jede der 81 Zellen exakt 4 Bits belegt (Zahlenwert 0 für leer, 1 bis 9 für besetzte Felder). Das ungelöste Starträtsel wird fest an den Eingang `const` angelegt. Intern erzeugt das Modul daraus eine unantastbare Schutzschablone (Maske). Jede Zelle des Starträtsels, die ungleich 0 ist, wird blockiert. Dies stellt sicher, dass die genetischen Operatoren (Crossover und Mutation) ausschließlich freie Felder verändern und die logischen Vorgaben des Rätsels zu jedem Zeitpunkt gewahrt bleiben.

### Vorbereitung & Start

Zu Beginn wird ein System-Reset durchgeführt (`rst = '1'`) und `start = '0'` gesetzt. Das zu lösende Rätsel muss stabil am Port `const` anliegen.

Der Algorithmus wird durch einen Taktimpuls auf `start = '1'` initiiert. Da das Rätsel direkt über den Port `const` eingelesen wird, ist kein vorheriges sequentielles Beschreiben eines RAMs von außen notwendig. Sobald der Algorithmus läuft, beginnt die FSM mit der Initialisierung der Population und startet anschließend die evolutionäre Schleife über maximal `max_gen` Epochen.

> [!WARNING] HARDWARE-HINWEIS
> Uns ist bewusst, dass das Anlegen des Rätsels über den Port `const` auf echter Hardware so nicht möglich ist, da die verfügbaren Pins wahrscheinlich stark überschritten werden.
> Im Zuge der Simulation ist dies allerdings kein Problem und auch ein sequentielles Laden des Rätsels in den RAM, was eine Lösung darstellen würde, hätte keinen signifikanten Einfluss auf die Laufzeit. Eine spätere Optimierung blieb an dieser Stelle aus.

### Evolutionärer Zyklus

In jeder Generation koordiniert das Top-Level-Modul `ga_sudoku` folgende Schritte:

- **Evaluierung:** Das voll-pipelinete Modul `fitness_sudoku` berechnet parallel die Zeilen-, Spalten- und Blockkonflikte für die Individuen einer Generation.

- **Selektion:** Über das Modul `tournament_sel_sudoku` werden sequentiell anhand zweier Gruppen die besten Eltern in einem Turnier ermittelt.

- **Rekombination & Mutation:** Um die Evolution voranzutreiben, erfolgt ein blockweises Crossover der erzeugten Kinder, gefolgt von einer gezielten Swap-Mutation freigegebener Zellen.

Der Algorithmus stoppt und setzt `done <= '1'`, sobald entweder eine perfekte Lösung gefunden wurde (`best_fit = 0`) oder die durch `max_gen` definierte Epochenanzahl erreicht ist.

### Beispiel

Die konkrete Verwendung der

### Performance



::: danger PROBLEM: LOKALE OPTIMA

Problem der lokale Optima.
:::