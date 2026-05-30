# Verwendung des k-Nearest-Neighbors Classifiers

## Entity

```vhdl
entity knnc is

    generic (
        k : natural := 3;
        fp_size : natural := 18;
        fp_frac : natural := 12;
        class_size : natural := 1; -- Constraint: class_size <= fp_size
        feature_num : natural := 7;
        adr_size : natural := 11 -- Maximum für XC3S500E (12 max. mit 1600 und Goal Timing Performance)
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        mark_end : in std_logic; -- markiert, ob der aktuelle Datenpunkt/Adresse die letzte Adresse des Datensatzes ist (zu klassifizierender Datenpunkt wird die folgende Adresse)
        ram_we : in std_logic; -- Datenpunkt in den RAM schreiben
        ram_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_data : in std_logic_vector(fp_size-1 downto 0);
        ram_part : in std_logic_vector(natural(ceil(log2(real(feature_num+1))))-1 downto 0); -- 0 => Class, 1 => Feature 1, ...

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

| Port     | Beschreibung                                                                                                                                                             |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| clk      | Taktsignal                                                                                                                                                               |
| rst      | synchroner Reset                                                                                                                                                         |
| start    | Start-Signal (Impuls für 1 Takt ausreichend) zum Beginn der Klassifizierung des zu klassifizierenden Datenpunktes (siehe `mark_end`)                                     |
| mark_end | markiert den aktuellen Datenpunkt/Adresse als letzte Adresse des Datensatzes (an die darauf folgende Adresse muss der zu klassifizierende Datenpunkt geschrieben werden) |
| ram_we   | Write-Enable-Signal zum Schreiben der Klasse/des Features eines Datenpunktes in den RAM                                                                                  |
| ram_adr  | RAM-Adresse zum Schreiben der Klasse/des Features eines Datenpunktes in den RAM                                                                                          |
| ram_data | Klasse/Features eines Datenpunktes zum Schreiben in den RAM (Features/Klassen werden sequentiell geschrieben, siehe ``ram_part`)                                         |
| ram_part | Auswahl des zu beschreibenden RAMs (binäre Kodierung: 0 => Klasse, 1 => Feature 1, 2 => Feature 2, ..., feature_num => Feature feature_num)                              |
| done     | signalisiert das Ende der Klassifikation und die Gültigkeit der ausgegebenen Klasse (wird für 1 Takt auf `1` gesetzt)                                                    |
| class    | ermittelte Klasse des zu klassifizierenden Datensatz (gültig erst mit done = `1`, danach stabil bis zum nächsten Start)                                                  |

## Verhalten

## Beispiel Bananen-Qualität
