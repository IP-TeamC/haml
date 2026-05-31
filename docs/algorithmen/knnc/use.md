# Verwendung des k-Nearest-Neighbors Classifiers

## Entity

```vhdl
entity knnc is

    generic (
        k : natural := 3;
        fp_size : natural := 18;
        fp_frac : natural := 12;
        class_size : natural := 1;
        feature_num : natural := 7;
        adr_size : natural := 11 -- Maximum für XC3S500E (12 max. mit 1600 und Goal Timing Performance)
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        mark_end : in std_logic;
        ram_we : in std_logic;
        ram_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_data : in std_logic_vector(fp_size-1 downto 0);
        ram_part : in std_logic_vector(natural(ceil(log2(real(feature_num+1))))-1 downto 0);

        done : out std_logic;
        class : out std_logic_vector(class_size-1 downto 0)
    );

end entity;
```

### Generics/Konfiguration

| Generic     | Beschreibung                                                                                       |
| ----------- | -------------------------------------------------------------------------------------------------- |
| k           | k von k-Nearest-Neighbors (Anzahl der besten betrachteten Distanzen/Klassen)                       |
| fp_size     | Fixed-Point Größe (Bits je Fixed-Point-Wert)                                                       |
| fp_frac     | Fixed-Point Fraction-Größe (Anteil Nachkomma-Bits an Gesamt-Bits)                                  |
| class_size  | Anzahl Bits für die Kodierung der Klassen (Einschränkung: class_size <= fp_size)                   |
| feature_num | Anzahl Features der Datenpunkte im Datensatz                                                       |
| adr_size    | Adressbreite des Datensatzes (mind. 1 Adresse ist für zu klassifizierenden Datensatz freizuhalten) |

### Ports

Alle Ports sind high-aktiv (aktive Flanke, Reset, Start und Done bei `1` aktiv).

| Input-Port | Beschreibung                                                                                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| clk        | Taktsignal                                                                                                                                                               |
| rst        | synchroner Reset                                                                                                                                                         |
| start      | Start-Signal (Impuls für 1 Takt ausreichend; Idle-Takt zu RAM-Write notwendig) zum Beginn der Klassifizierung des zu klassifizierenden Datenpunktes (siehe `mark_end`)   |
| mark_end   | markiert den aktuellen Datenpunkt/Adresse als letzte Adresse des Datensatzes (an die darauf folgende Adresse muss der zu klassifizierende Datenpunkt geschrieben werden) |
| ram_we     | Write-Enable-Signal zum Schreiben der Klasse/des Features eines Datenpunktes in den RAM (Idle-Takt zu Start notwendig)                                                   |
| ram_adr    | RAM-Adresse zum Schreiben der Klasse/des Features eines Datenpunktes in den RAM                                                                                          |
| ram_data   | Klasse/Features eines Datenpunktes zum Schreiben in den RAM (Features/Klassen werden sequentiell geschrieben, siehe `ram_part`)                                          |
| ram_part   | Auswahl des zu beschreibenden RAMs (binäre Kodierung: 0 => Klasse, 1 => Feature 1, 2 => Feature 2, ..., feature_num => Feature feature_num)                              |

| Output-Port | Beschreibung                                                                                                            |
| ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| done        | signalisiert das Ende der Klassifikation und die Gültigkeit der ausgegebenen Klasse (wird für 1 Takt auf `1` gesetzt)   |
| class       | ermittelte Klasse des zu klassifizierenden Datensatz (gültig erst mit done = `1`, danach stabil bis zum nächsten Start) |

## Verhalten

### Vorbereitung

Zu Beginn muss ein Reset durchgeführt und `start = 0` gesetzt werden.

Anschließend muss der bekannte/klassifizierte Datensatz in den RAM geladen werden (`ram_we = 1`).
Hierbei wird je Takt nur eine Feature bzw. die Klasse eines Datenpunktes geladen.
So werden für jede `ram_adr` mehrere Takte benötigt, wobei über `ram_part` angegeben wird, um welchen Bestandteil des Datenpunktes es sich handelt.
Zunächst wird mit `ram_part = 0` (binär kodiert) in `ram_data` die Klasse des Datenpunktes übergeben.
Anschließend wird mit `ram_part = 1` bis `ram_part = feature_num` jedes Feature (1 bis `feature_num`) übergeben und in den RAM geschrieben.
Dies wird nun für jeden Datenpunkt/Adresse wiederholt.

Für den letzten Datenpunkt muss `mark_end = 1` gesetzt sein, um diese Adresse als letzten Datenpunkt zu markieren (End-Adresse).
Es werden für k-Nearest-Neighbors dann anschließend immer genau alle Adressen von jeweils einschließlich 0 bis zur mit `mark_end` markierten End-Adresse zur Distanzberechnung verwendet.

Abschließend müssen `mark_end` sowie `ram_we` auf `0` gesetzt werden!
Der Datensatz kann jedoch, wenn keine Klassifizierung läuft, wieder auf die gleiche Weise angepasst bzw. erweitert/verringert werden.

### Klassifizierung

Nach der einmaligen Vorbereitung kann nun ein unbekannter/zu klassifizierender Datenpunkt in den RAM geladen werden.
Dieser wird an genau die Adresse nach der End-Adresse (`End-Adresse + 1`) geschrieben (auf die gleiche Weise mit verschiedenen `ram_part` wie bei der Vorbereitung).
Zwischen einer aktiven Flanke mit RAM-Write-Enable und einer folgenden aktiven Flanke mit Start-Signal muss mindestens eine aktive Flanke mit beiden nicht-aktiven Signalen liegen (Idle-Takt)!

Anschließend kann mit `start = 1` (für 1 Takt) die Klassifizierung gestartet werden.
Sobald die Klassifizierung beendet ist, wird `done` für 1 Takt auf `1` gesetzt.
Synchron dazu wird mit `class` die ermittelte Klasse nach Abschluss der Klassifikation ausgegeben.
Die Ausgabe der Klasse bleibt nach mit Ausgabe von `done = 1` bis zum nächsten Start stabil.
Die nächste Klassifikation (erneutes Setzen von `start = 1`) darf auch erst nach Abschluss (`done = 1`) der laufenden Klassifikation begonnen werden.

Für jede weitere Klassifikation muss der zu klassifizierende Datenpunkt an `End-Adresse + 1` ausgetauscht werden.

## Beispiel

Die konkrete Verwendung der k-Nearest-Neighbors Implementierung kann am Beispiel des Datensatzes der Bananen-Qualität demonstriert werden (siehe Ordner `codegen`).
Diese beispielhafte Implementierung befindet sich unter `test/knnc/bq_knnc_tb.vhd` und liest zunächst den Trainingsdatensatz ein,
welcher mithilfe des Code-Generators (siehe `codegen` und `test/dataset`) als VHDL-Code generiert wurde.
Dieser Datensatz wird nun, wie für die Vorbereitung beschrieben, zunächst in den RAM geschrieben.
Anschließend wird für jeden Datenpunkt des Testdatensatzes dieser an `End-Adresse + 1` geschrieben (inkl. Idle-Takt) und die Klassifikation gestartet.
Nach Abschluss der Klassifikation wird überprüft, ob die ausgegeben Klasse der erwarteten Klasse entspricht.
Insgesamt benötigt diese Hardware-Implementierung zur Klassifizierung des gesamten Testdatensatzes inkl. Einlesen des Trainingsdatensatzes ca. 34,42 ms (deterministisch; mit einer Taktfrequenz von `357 MHz` auf dem Virtex-6).
Dabei sind 5803 der 5960 Vorhersagen (ca. 97,4 %) korrekt (der Testdatensatz ist mit 74,5 % wesentlich größer als der Trainingsdatensatz)

Eine funktionell größtenteils identische Python-Implementierung (scikit-learn) existiert unter `software/bq_knnc.py` und dient als Vergleich,
wobei der unterschiedlich Shuffle des Splits nur in einer anderen Accuracy resultiert, aber keinen Einfluss auf die betrachtete Performance hat.
Die Software-Implementierung benötigt zur Klassifizierung des gesamten Testdatensatzes meist etwas mehr als 160 ms (nicht deterministisch).
Dabei sind mit 5818 der 5960 Vorhersagen (ca. 97,6 %) ähnlich viele Vorhersagen korrekt wie bei der Hardware-Implementierung.

Insgesamt ist die Hardware-Implementierung im Vergleich zu der Software-Implementierung mit scikit-learn fast 5x schneller und ähnlich genau (sehr geringe Abweichung aufgrund eines abweichenden Shuffles beim Train-/Test-Split).
