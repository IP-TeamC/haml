# Getting Started

Diese Dokumentation ist ebenfalls auf [GitHub](https://ip-teamc.github.io/haml/) aufrufbar.

## Projektbeschreibung

Wir haben uns beim Projekt **haml** mit **Hardware-Accelerated Machine-Learning**, insbesondere mit FPGAs, beschäftigt.
Zunächst haben wir betrachtet, wie sich eine effiziente Implementierung auf Hardware von Software unterscheiden müsste und welche Konzepte bei der Implementierung umgesetzt werden müssten.
Mit dieser Basis haben wir verschiedene Machine-Learning-Algorithmen betrachtet und die Eignung/Umsetzbarkeit einer Hardware-Implementierung dieser Algorithmen überprüft.

Anschließend haben wir konkret **k-Nearest-Neighbors** und **genetische Algorithmen für lineare Regression** sowie zum **Lösen von Sudokus** in VHDL implementiert.
Die Implementierungen haben wir abschließend kurz mit Software-Implementierungen verglichen und die Beschleunigung bestimmt (bis zu 500x schneller als Software).

## Setup

Für die Verhaltenssimulation haben wir hauptsächlich auf [GHDL](https://github.com/ghdl/ghdl) in Kombination mit [GTKWave](https://github.com/gtkwave/gtkwave) gesetzt (ausführbar unter Linux oder mithilfe von WSL).
Sind diese beiden Voraussetzungen Anwendungen installiert (in den meisten Linux-Distributionen mit dem üblichen Paketmanager ohne spezielle Repositories installierbar),
kann mithilfe der beiden Skripte `run.sh` und `run-wave.sh` die Simulation gestartet werden.
Die `wave`-Variante erzeugt eine Wave-Datei und öffnet diese zur Darstellung in GTKWave,
ist deshalb jedoch wesentlich langsamer und benötigt einen großen Speicherbedarf bei langen Laufzeiten.
Stattdessen sollte für Testfälle oder lange Laufzeiten (bzw. immer wenn keine grafische Darstellung benötigt wird) immer die einfache `run.sh` bevorzugt werden.

Diese `run.sh` wird mit der zu simulierenden Testbench-Entity und optional einer Zeitangabe gestartet (Standard 1 ms).
Folgende Testbenches existieren (ausgenommen reine Testbenches zur Validierung der korrekten Funktionsweise):

| Testbench              | Ausführung (mit angemessener Zeitangabe) |
| ---------------------- | ---------------------------------------- |
| bq_knnc_tb             | `./run.sh bq_knnc_tb 35ms`               |
| salary_tb              | `./run.sh salary_tb 2ms`                 |
| f3x12_tb               | `./run.sh f3x12_tb 1ms`                  |
| lineare_regression1_tb | `./run.sh lineare_regression1_tb 1ms`    |
| lineare_regression2_tb | `./run.sh lineare_regression2_tb 1ms`    |

Wichtig! Dabei ist zu beachten, dass die `run.sh` sowie `run-wave.sh` immer im Haupt-Projektverzeichnis (in dem sich auch die beiden Skripte befinden; nicht in einem anderen Ordner/Unterordner) ausgeführt werden müssen!

Die Implementierung auf dem Virtex-6 fand in Xilinx ISE statt.
Die Projektdatei `haml.xise` sowie die Timing Constraints `haml.ucf` und Design Strategy `ds_v6.xds` sind ebenfalls enthalten.

Besonderheiten zur Ausführung und grafischen Darstellung der Ergebnisse des genetischen Algorithmus zum Lösen von Sudokus sind unter [algorithmen/ga_sudoku/live-sudoku-ui](./algorithmen/ga_sudoku/live-sudoku-ui.md) beschrieben.

## Projektstruktur

Das Projekt besteht aus:

| Komponente | Beschreibung                                                                                  |
| ---------- | --------------------------------------------------------------------------------------------- |
| codegen    | Code-Generator zum Erzeugen von Datensätzen als VHDL-Code                                     |
| data       | CSV-Datensätze                                                                                |
| docs       | Dokumentation der Implementierung/des Projekts                                                |
| software   | Software-Implementierung in Python zum Vergleich                                              |
| src        | VHDL-Implementierung, in weitere Komponenten unterteilt je nach Algorithmus                   |
| test       | VHDL-Testbenches (Validierung der Funktionsweise, Ausführung der Algorithmen mit Datensätzen) |

## codegen

Zur Datenvorverarbeitung zur Nutzung der CSV-Datensätze in der VHDL-Implementierung haben wir einen Code-Generator geschrieben,
der für jeden Datensatz einen ROM als VHDL-Code generiert und dabei wichtige Parameter wie z.B. Fixed-Point Größe, Fixed-Point Fraction-Anteil und End-Adresse berücksichtigt.
Diese VHDL-Datensätze werden für die Testbenches von k-Nearest-Neighbor und vom genetischen Algorithmus für lineare Regression verwendet.

Alle erzeugten VHDL-Datensätze werden unter `test/dataset` gespeichert.
Die Klasse `BananaQuality` erzeugt den Datensatz `banana_quality.csv` als VHDL-Code.
Die Klasse `GenericLinReg` erzeugt die anderen vier Datensätze für die lineare Regression (`salary.csv`, `f3x12.csv`, `lineare_regression1.csv`, `lineare_regression2.csv`).
Zusätzlich bietet diese Klasse mit den Methoden `denormalizeFunction` sowie `convertDenormalizeAndPrintFunction` eine Möglichkeit,
die normalisierte Fixed-Point-Darstellung der Koeffizienten wieder zurück in die denormalisierte Double-Darstellung in Java umzuwandeln und auszugeben (siehe `main`-Methode).

Wir haben uns explizit gegen eine Normalisierung/Denormalisierung innerhalb der VHDL-/Hardware-Implementierung entschieden,
da dies lediglich ein einmaliger und nicht rechenaufwändiger Schritt ist (im Gegensatz zur folgenden linearen Regression).
Auch kann so die komplexe Verarbeitung von Floating-Point als Eingabe vermieden werden.
