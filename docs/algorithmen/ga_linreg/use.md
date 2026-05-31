# Verwendung des genetischen Algorithmus für lineare Regression

## Entity

```vhdl
entity ga_linreg is

    generic (
        mask_factor : natural := 3;
        k_sel : natural := 3;
        k_rep : natural := 3;
        var_num : natural := 1;
        fp_size : natural := 18;
        fp_frac : natural := 17;
        fit_size: natural := 36;
        dp_adr_size : natural := 8;
        chr_adr_size : natural := 6;
        replace_with_worse : boolean := false;
        mut_arith : boolean := true;
        square : boolean := false
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        mark_end : in std_logic;
        dp_we : in std_logic_vector(var_num downto 0);
        dp_adr : in std_logic_vector(dp_adr_size-1 downto 0);
        dp_data : in std_logic_vector(fp_size-1 downto 0);

        best_chr : out std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        best_chr_fit : out std_logic_vector(fit_size-1 downto 0)
    );

end entity;
```

### Generics/Konfiguration

| Generic            | Beschreibung                                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------------------------------- |
| mask_factor        | höherer Masken-Faktor reduziert die Mutationswahrscheinlichkeit (empfohlen 2-4)                                 |
| k_sel              | Tournament-Größe für Tournament Selection                                                                       |
| k_rep              | Tournament-Größe für Tournament Replacement                                                                     |
| var_num            | Anzahl Features der Datenpunkte im Datensatz                                                                    |
| fp_size            | Fixed-Point Größe (Bits je Fixed-Point-Wert)                                                                    |
| fp_frac            | Fixed-Point Fraction-Größe (Anteil Nachkomma-Bits an Gesamt-Bits)                                               |
| fit_size           | Größe/Genauigkeit der Fitness-Funktion in Bits (max. adr_size+2\*fp_size-4, empfohlen 2\*fp_size)               |
| dp_adr_size        | Adressbreite der Datenpunkt-RAMs                                                                                |
| chr_adr_size       | Adressbreite der Chromosom-/Fitness-RAMs (bestimmt Populations-Größe, empfohlen 5-8)                            |
| replace_with_worse | false verhindert das Ersetzen durch schlechtere Kandidaten (empfohlene Einstellung fuer Tournament Replacement) |
| mut_arith          | Mutations-Modus: Logisch (XOR) oder Arithmetisch (ADD/SUB, empfohlen)                                           |
| square             | Fitness-/Fehler-Funktion: Sum of Squared (square = true) / Absolute (square = false) Errors                     |

### Ports

Alle Ports sind high-aktiv (aktive Flanke, Reset und Start bei `1` aktiv).

| Input-Port | Beschreibung                                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| clk        | Taktsignal                                                                                                                                  |
| rst        | synchroner Reset                                                                                                                            |
| start      | Start-Signal (Impuls für 1 Takt ausreichend; vorheriges Beschreiben des Datensatz-RAMs notwendig; läuft nach Start dauerhaft bis zum Reset) |
| mark_end   | markiert den aktuellen Datenpunkt/Adresse als letzte Adresse des Datensatzes                                                                |
| dp_we      | Bitvektor für Write-Enable-Signale für Datensatz-RAMs (One-Hot; 0 => Funktionswert, 1 => Feature 1, ..., var_num => Feature var_num)        |
| dp_adr     | RAM-Adresse zum Schreiben eines Features/des Funktionswertes eines Datenpunktes in den RAM                                                  |
| dp_data    | Feature/Funktionswert eines Datenpunktes zum Schreiben in den RAM (Features/Funktionswert werden sequentiell geschrieben, siehe `dp_we`)    |

| Output-Port  | Beschreibung                                                     |
| ------------ | ---------------------------------------------------------------- |
| best_chr     | bisher bestes Chromosom (kontinuierliche Anpassung)              |
| best_chr_fit | Fitness des bisher besten Chromosoms (kontinuierliche Anpassung) |

## Verhalten

### Datenvorverarbeitung

Da die Verwendung von Fixed-Point-Werten eine begrenzte Genauigkeit bietet,
sollte das Fenster bzw. die zur Verfügung stehenden Bits für jedes Feature/Variable maximal ausgenutzt werden.
Dies ist bei Rohdaten meist nicht gegeben, da eine einheitliche Fixed-Point-Darstellung für jedes Feature eine unterschiedliche Genauigkeit aufgrund eines abweichenden Wertebereichs bietet.
Um dieses Problem zu lösen, empfiehlt es sich, alle Werte in einem zu Fixed-Point passenden Wertebereich zu normalisieren (z.B. zwischen -1 und (1 - 2^(-fp_frac)) eignet sich gut).
In jedem Fall ist diese Datenvorverarbeitung vor Übergabe an den genetischen Algorithmus zu erledigen und die Generics (`fp_size`, `fp_frac`) dementsprechend anzupassen.
Nur auf diese Weise kann eine für diese Fixed-Point-Darstellung maximal mögliche Genauigkeit erreicht werden.

Eine Möglichkeit zur Normalisierung des Datensatzes vor der Ausführung des genetischen Algorithmus und Denormalisierung der ermittelten Koeffizienten zum Abschluss bieten die Methoden der Klasse `GenericLinReg` im `codegen`.

Darüberhinaus ist zu beachten, dass die ermittelten Koeffizienten ebenfalls an den Wertebereich der Fixed-Point-Darstellung gebunden sind.
Somit sind in absoluten Werten zu große Steigungen ein potentielles Problem (abhängig vom Datensatz).
In diesen (wahrscheinlich seltenen Fällen) muss die Steigung in der Vorverarbeitung ebenfalls nach unten korrigiert werden.
Hierfür bietet es sich an, lediglich die Funktionswerte nach der Normalisierung zu halbieren (bzw. mehrfach zu halbieren).
Anschließend muss nach Berechnung einer Funktion jeder Koeffizient (außer der Achsenabschnitt) um diesen Faktor wieder zurückkorrigiert werden.
In den getesteten Datensätzen ist die Notwendigkeit dieser Anpassung bisher nicht notwendig gewesen und stellt ein eher theoretisches Problem von Fixed-Point-Berechnungen dar,
auch wenn problematische Datensätze künstlich definitiv konstruiert werden können.

### Vorbereitung

Zu Beginn muss ein Reset durchgeführt und `start = 0` gesetzt werden.

Anschließend muss der Datensatz in den RAM geladen werden.
Hierbei wird je Takt nur eine Feature bzw. der bekannte Funktionswert eines Datenpunktes geladen.
So werden für jede `dp_adr` mehrere Takte benötigt, wobei über `dp_we` (One-Hot) angegeben wird,
um welchen Bestandteil des Datenpunktes es sich handelt (zugleich auch Write-Enable-Signal).
Dabei entspricht bei `dp_we` (One-Hot) Index 0 (LSB) dem bekannten Funktionswert und die anderen Bits jeweils dem Feature (1 => Feature 1, 2 => Feature 2, ..., var_num => Feature var_num).
Zunächst wird mit `dp_we = 0` (One-Hot, d.h. nur LSB gesetzt) und `dp_data` der Funktionswert eines Datenpunktes übergeben.
Anschließend wird mit Linksschieben jedes weitere Feature (1 bis `var_num`) übergeben und in den RAM geschrieben.
Dies wird nun für jeden Datenpunkt/Adresse wiederholt.

Für den letzten Datenpunkt muss `mark_end = 1` gesetzt sein, um diese Adresse als letzten Datenpunkt zu markieren (End-Adresse).
Dies wird dann die letzte Adresse sein, die von der Fitness-Funktion betrachtet wird.

Abschließend müssen `mark_end` sowie alle Bits von `dp_we` auf `0` gesetzt werden!
Sobald der genetische Algorithmus gestartet wird, dürfen weder `mark_end` noch Bits von `dp_we` auf `1` gesetzt werden.

### Start

Nach der einmaligen und nicht veränderbaren Vorbereitung durch das Laden des Datensatzes (nur nach einem Reset erneut beschreibbar) kann der genetische Algorithmus gestartet werden.
Hierfür wird nun lediglich `start = 1` gesetzt, wobei die anderen Kontrollsignale (`rst`, `mark_end` und `dp_we`) natürlich vollständig auf `0` gesetzt sein müssen.
Der Zustand der Signale `dp_adr` sowie `dp_data` ist nicht relevant und kann beim Start auf beliebigen Werten gesetzt bleiben.

Der genetische Algorithmus beginnt nun mit der Initialisierung der Population.
Daraufhin startet das Training, welches als Steady State Genetic Algorithm nicht auf Generationen basiert.
Deshalb ist kein sinnvolles Abbruchkriterium definierbar.
Stattdessen wird kontinuierlich das beste Chromosom ermittelt und dieses mit dessen Fitness ausgegeben.

Von außen kann nun das Reset-Signal gesetzt werden, um den genetischen Algorithmus zu beenden.
Dabei bleibt das ausgegebene Chromosom und dessen Fitness weiterhin stabil.
Erst der nächste Start würde diese Ausgabe-Signale überschreiben.

## Beispiel

Die konkrete Verwendung der Implementierung des genetischen Algorithmus für lineare Regression kann am Beispiel der Datensätze für
eine Gehaltstabelle (Salary mit YOE/Grade), der Funktionen y=3x+12 oder den beiden Datensätzen `lineare_regression{1,2}.csv` demonstriert werden (siehe Ordner `codegen`).

Diese beispielhaften Implementierungen befinden sich unter `test/ga_linreg_examples/{salary,f3x12,lineare_regression1,lineare_regression2}_tb.vhd`
und lesen zunächst den Datensatz ein, welcher mithilfe des Code-Generators (siehe `codegen` und `test/dataset`) als VHDL-Code generiert wurde.
Dieser Datensatz wird nun, wie für die Vorbereitung beschrieben, zunächst in den RAM geschrieben und anschließend der genetische Algorithmus gestartet.

Die regelmäßige Konsolenausgabe zur Überwachung der Chromosome und Fitness-Werte im Simulator findet in der generischen `test/ga_linreg/ga_linreg_tb.vhd` statt.
Diese gibt jede Mikrosekunde die aktuell besten Koeffizienten mit der dazugehörigen Fitness aus.

Die Konfiguration setzt dabei in allen Fällen auf folgende Konfiguration:

| Generic            | Einstellung |
| ------------------ | ----------- |
| mask_factor        | 3           |
| k_sel              | 3           |
| k_rep              | 3           |
| fp_size            | 18          |
| fp_frac            | 17          |
| fit_size           | 36          |
| chr_adr_size       | 5           |
| replace_with_worse | false       |
| mut_arith          | false       |
| square             | false       |

Diese Konfiguration mit einer Populationsgröße von 32 (`2^5`) und sonst dem Datensatz entsprechenden Parametern (`var_num` und `dp_adr_size`) hat in allen Testfällen zu einem schnellen sowie guten Ergebnis in weniger als 1 ms geführt.

| Datensatz               | Akzeptable/Gute Lösung | Optimale Lösung | Software (optimal) |
| ----------------------- | ---------------------- | --------------- | ------------------ |
| salary.csv              | ca. 0,4 ms             | 1,19 ms         | nicht getestet     |
| f3x12.csv               | ca. 0,1 ms             | 0,26 ms         | nicht getestet     |
| lineare_regression1.csv | ca. 0,2 ms             | 0,55 ms         | ca. 270 ms         |
| lineare_regression2.csv | ca. 0,2 ms             | 0,53 ms         | ca. 270 ms         |

Die Hardware-Implementierung verwendet den Virtex-6 mit einer Taktfrequenz von `364 MHz` und die Software-Implementierung verwendet Python mit PyGAD.
Damit ist die Hardware-Implementierung bei diesen Beispieln etwa um den Faktor 500 schneller als die Software-Implementierung.
Die Software-Implementierung wurde jedoch auf moderner Hardware durchgeführt, während die Hardware-Implementierung auf dem Virtex-6 von 2009 implementiert wurde.
Ein moderner FPGA würde diesen Faktor wahrscheinlich noch vergrößern können (z.B. wäre insgesamt ein doppelt so hoher Faktor von etwa 1000 realistisch).

Beim genetischen Algorithmus für lineare Regression lässt sich also eine sehr deutliche Beschleunigung bei der Hardware-Implementierung gegenüber einer Software-Implementierung feststellen.
