# Genetischer Algorithmus für lineare Regression

## Umsetzbarkeit

- ja, aber mit Einschärnkungen
- Probleme:
  - Zufallszahlen: LFSR
  - evtl. hoher Speicherbedarf
  - Auswahl bester Individuen aufwändig (vereinfachte Auswahl, verschiedene Möglichkeiten)
- sehr gute Parallelisierung
  - parallele Anpassung der Population (Mutation, Crossover)
  - parallele Berechnung der Fitness-Funktion
  - Einschränkung: RAM
    - parallele Berechnung mehrerer Kinder/Fitness nicht umgesetzt (aber agentenbasiert möglich)
- agentenbasiert sehr gut möglich (nicht umgesetzt)
  - z.B. Teil-Populationen, Planetensystem

## Struktur

- **ga_linreg**: Top-Level-Modul für den genetischen Algorithmus, Ermittlung des global besten Chromosoms
  - **ram**: Datensatz-RAM (je Feature + Funktionswert), Chromosomen-RAM (je Koeffizient), Fitness-RAM
  - **fitness_linreg**: Controller stellt untergeordneten Fitness-Funktion Datenpunkte aus dem RAM bereit
    - **rse_linreg**: Fitness-Pipeline: Funktionsberechnung, Differenzberechnung zum erwarteten Funktionswert, quadrierten/absoluten Fehler akkumulieren für alle Datenpunkte
      - **adder_tree**: Adder-Tree zum Pipelining vieler akkumulierter Additionen (zur Berechnung des Funktionswertes)
        - **adder_tree_stage**: Pipeline-Stage des Adder-Trees
  - **pop_init**: zufällige Populationsinitialisierung inkl. initialer Fitness-Berechnung
    - **lfsr**: Linear-rückgekoppeltes Schieberegister zur Generierung von Pseudozufallszahlen (zuällige Generierung der Gene der Chromosome)
  - **trainer**: Steuerung und Kaspelung des Trainings, FSM zur Steuerung der Tranings-Komponenten inkl. ausgelagerter Fitness-Funktion
    - **tournament_sel**: Tournament Selection wählt in 2 unabhängigen, aufeinanderfolgenden Tournaments 2 Eltern-Chromosome
      - **lfsr**: Linear-rückgekoppeltes Schieberegister zur Generierung von Pseudozufallszahlen (zufällige Wahl der RAM-Adresse der Chromosome im Tournament)
    - **crossover**: Crossover erzeugt aus 2 Eltern ein Kind mit Genen, die zufällig von den beiden Eltern gewählt werden
      - **lfsr**: Linear-rückgekoppeltes Schieberegister zur Generierung von Pseudozufallszahlen (zufällige Wahl des Elternteils für ein Gen)
    - **mutation**: Mutation mutiert ein Chromosom zufällig mit einer Mutationsmaske (logisch oder arithmetisch)
      - **lfsr**: Linear-rückgekoppeltes Schieberegister zur Generierung von Pseudozufallszahlen (zufällige Mutationsmaske)
    - **tournament_rep**: Tournament Replacement wählt im Tournament ein schlechtestes Inviduum aus und ersetzt dieses
      - **lfsr**: Linear-rückgekoppeltes Schieberegister zur Generierung von Pseudozufallszahlen (zufällige Wahl der RAM-Adresse der Chromosome im Tournament)

## Steady State Genetic Algorithm

Zur besseren Umsetzung unter den ermittelten Voraussetzungen (insb. Pipelining und Streaming) wird auf die klassische Funktionsweise eines genetischen Algorithmus verzichtet.
Stattdessen wird ein Steady State Genetic Algorithm verwendet, welcher über keine konkreten Generationen verfügt, sondern kontinuierlich vorhandene Chromosome durch neue ersetzt.

### Populationsbeschreibung

- Population = Array von Individuen
- Individuum = Chromosom
  - Aufteilung in Blöcke/Gene (Koeffizienten)
  - Bitvektor (Flat)

### Ablauf

- Intialisierung
  - zufällige Population generieren
  - Fitness für Population berechnen (im RAM speichern)
- iteratives Training
  - 2 unabhängige, aufeinanderfolgende Tournament Selections für die Wahl von 2 Eltern
  - Crossover erzeugt Kind
  - Mutation vom Kind
  - Fitness vom Kind berechnen
  - Tournament Replacement bestimmt im Tournament schlechtestes Individuum und tauscht aus

### Generationen

Statt der Erzeugung von vollständigen Generationen/Populationen wird iterativ in jeder Iteration genau ein Chromosom erzeugt,
welches genau ein anderes Chromosom im RAM ersetzt und kontinuierlich/laufend die Population anpasst.
Dadurch wird ein kontinuerlicher Datenfluss (Streaming/Pipeline) ermöglicht und mögliche Konflikte sowie Synchronisierung (z.B. Warten bis die gesamte Population erzeugt worden ist) verhindert.
Auch wird ein zweiter RAM (Ping-Pong-RAM) vermieden und Änderungen beeinflussen die Population schneller (möglicherweise geringere Latenz bis zu einer akzeptablen Lösung).
Bei der linearen Regression hat dieser Ansatz ohne Generationen auch sehr gut und schnell funktioniert.

## Funktionsweise

Die Funktionsweise wird im folgenden anhand der Funktionsweise der einzelnen Komponenten erklärt,
die in strikter Reihenfolge entsprechend des zuvor beschriebenen Ablaufs nacheinander ausgeführt werden.
Fast alle Komponenten verfügen über ein Start- und Done-Signal, um die Komponenten zu starten bzw. eine Fertigstellung feststellen zu können.
Die Komponenten `ram`, `adder_tree` und `adder_tree_stage` werden hier nicht weiter beschrieben.
Deren Funktionsweise ist der Dokumentation zu k-Nearest-Neighbors zu entnehmen.

Da hier nun jedoch mehrere Komponenten auf die Block-RAMs zugreifen,
werden zunächst die verschiedenen Zugriffe der Komponenten auf den RAM dargestellt.
Zu beachten ist darüber hinaus noch, dass die Fitness-Funktion sowohl von der Populationsinitialisierung als auch von dem Trainer verwendet wird.

### RAM-Zugriff

| Komponente                 | Datensatz | Chromosome & Fitness |
| -------------------------- | --------- | -------------------- |
| Top-Level (von außen)      | write     | -                    |
| Fitness                    | read      | -                    |
| Populationsinitialisierung | (read\*)  | write                |
| (Trainer\*)                | (read\*)  | (read/write\*)       |
| Tournament Selection       | -         | read                 |
| Crossover                  | -         | -                    |
| Mutation                   | -         | -                    |
| Tournament Replacement     | -         | read/write           |

Hinweis\*:
Der Zugriff auf das Chromosomen-RAM wird zusätzlich innerhalb des Trainers für die enthaltenen Komponenten gesteuert und liefert nach außen ein einheitliches Signal (der Training-Eintrag ist deshalb eine redundante Zusammenfassung).
Der Trainer und die Populationsinitialisierung lesen zudem den Datensatz-RAM nur indirekt über die Steuerung der Fitness-Funktion.

### Top-Level (ga_linreg)

Das Top-Level-Modul `ga_linreg` setzt alle Haupt-Komponenten zusammen.
Dies sind die verschiedenen Block-RAMs (Datensatz, Chromosome, Fitness), die Populationsinitialisierung und der Trainer.
Dabei wird zu Beginn das Schreiben des Datensatzes von außen ermöglicht.
Anschließend beginnt die Populationsinitialisierung, sobald `start = 1` gesetzt ist.
Schließlich wird der Trainer gestartet, sobald die Initialisierung beendet ist.
Es werden deshalb immer genau in der Reihenfolge die Zustände Ready, Init und Train durchlaufen, wobei das Verlassen des Zustands Train nur über einen Reset möglich ist.

### Fitness-Funktion (fitness_linreg)

Die Fitness-Funktion wird von der Populationsinitialisierung sowie vom Trainer verwendet und berechnet die Fitness für ein gegebenes Chromosom.
Dabei liest dieser Controller den Datensatz-RAM aus und übermittelt die Datenpunkte als Stream jeweils an die untergeordnete Komponente zur tatsächlichen Berechnung der Fitness.

## Rescaled Sum of Errors (rse_linreg)

Die tatsächlich Fitness-Berechnung findet in einer 6+ stufigen Pipeline in dieser Komponente statt.
Die berechnete Fitness entspricht dem Mean Squared/Absolute Error ohne die Berechnung des Durchschnitts (daher Sum statt Mean) und mit einer Verschiebung des Kommas (daher Rescaled).
Zusätzlich werden zur Reduzierung der Anzahl der Bits LSBs abgeschnitten und damit auch die Genauigkeit reduziert, weshalb die berechnete Fitness nicht mathematisch exakt ist.
Die folgenden Pipeline-Stufen werden durchlaufen:

1. RAM-Daten in Register zwischenspeichern
2. Multiplikation der Koeffizienten mit Datenpunkt
3. Addition der Multiplikationsergebnisse im Adder-Tree (je nach Anzahl Koeffizienten Multi-Stage)
4. Differenz zwischen berechnetem und erwartetem Funktionswert berechnen
5. Differenz quadrieren (bzw. absoluten Wert bestimmen)
6. quadrierte/absolute Differenz Akkumulieren

Die Genauigkeit ist bei absoluter (statt quadratischer) Abweichung höher,
da weniger LSBs abgeschnitten werden müssen (eine Multiplikation weniger).
Deshalb hat die Verwendung der absoluten Abweichung häufig zu besseren Ergebnissen geführt.

### Populationsinitialisierung (pop_init)

Die Populationsinitialisierung generiert parallel aus mehreren LFSRs mit verschiedenen Seeds jeweils alle Gene eines Chromosoms und stellt dieses der Fitness-Funktion zur Verfügung.
Diese berechnet die Fitness, welche dann mit dem Chromosom in die Block-RAMs geschrieben wird.
Dieser Prozess wird für alle Adressen des Chromosomen-/Fitness-RAMs wiederholt.
Das Modul durchläuft also die Zustände Ready, Generate, Fitness, Write und Done, wobei der Übergang von Write bei noch nicht abgeschlossener Initialisierung zunächst wieder zu Generate stattfindet.
Done wird anschließend nach dem Beschreiben der letzten Adresse erreicht und kann nur noch durch einen Reset verlassen werden.

### Trainer (trainer)

Nach der Populationsinitialisierung wird der Trainer gestartet, welcher nur aus dem Warte-Zustand Ready gewechselt.
Hier werden strikt in einer Endlosschleife die Zustände Select, Crossover, Mutate, Fit und Replace in dieser Reihenfolge durchlaufen.
Jeder Zustandswechsel startet die jeweilige Komponente schaltet die Datenpfade zum RAM bzw. zur Fitness-Funktion, wenn diese von mehreren Komponenten verwendet werden.
Der Trainer ist ein simpler Automat ohne weitere komplexe Funktionalität.

### Tournament Selection (tournament_sel)

Die Tournament Selection führt nacheinander 2 unabhängige Tournaments durch und besteht jeweils das beste Chromosom.
Das Lesen des RAMs wird hierbei jedoch gecached, um die Taktfrequenz zu erhöhen.
Deshalb ist ein Cache-Zustand notwendig.
Ansonsten durchläuft dieser Automat die Zustände Ready, Cache, Read1, Clear und Read2 in dieser Reihenfolge.
Wobei Cache nur die zuvor genannte Verzögerung zum Lesen abbildet (implizit auch Clear für das zweite Lesen).
Anschließend werden k zufällig vom LFSR gewählte Adressen aus dem Chromosomen-/Fitness-RAM gelesen.
Die beste Fitness (kleinster Fehler) wird samt Chromosom gespeichert.
Mit Clear wird dieser Zwischenspeicher geleert und das beste Chromosom in ein Ausgabe-Register geschrieben.
Das Tournament wird wiederholt und das hierbei beste Chromosom als zweiter Elternteil ausgegeben.

### Crossover (crossover)

Der Crossover bildet aus den beiden von der Tournament Selection gewählten Eltern-Chromosomen ein Kind.
Dabei wird jeweils ein ganzes Gen zufällig (LFSR) von einem Elternteil übernommen.

| Chromosom     | Gen 1 | Gen 2 | Gen 3 | Gen 4 | Gen 5 |
| ------------- | ----- | ----- | ----- | ----- | ----- |
| Elternteil 1  | A     | B     | C     | D     | E     |
| Elternteil 2  | F     | G     | H     | I     | J     |
| Beispiel-Kind | A (1) | G (2) | C (1) | D (1) | J (2) |

### Mutation (mutation)

Die Mutation mutiert das vom Crossover gebildete Kind-Chromosom zufällig.
Dabei wird kontinuierlich eine Mutationsmaske aus mehreren LFSRs gebildet.
Mithilfe eines Masken-Faktors kann die Mutationswahrscheinlichkeit konfiguriert werden.
Der Masken-Faktor entspricht der Anzahl der verundeten zufällige Bit-Vektoren, aus denen die Mutationsmaske erzeugt wird.
Jedes Chromosom/Mutations-Maske wird zusätzlich in 4 Blöcke unterteilt.
Alle weiteren Blöcke aufsteigend vom LSB werden jeweils mit einem zusätzlichen zufälligen Bit-Vektor verundet.
Die Mutationswahrscheinlich ist also bei den geringeren Blöcken (LSBs) geringer als bei den höheren Blöcken (MSBs).
Darüber hinaus werden die beiden Mutations-Modi Logisch (XOR) und Arithmetisch (ADD/SUB) unterstützt, wobei Arithmetisch zufällig zwischen ADD/SUB wählt.
Bei der linearen Regression hat sich der arithmetische Modus als wesentlich besser erwiesen.

### Tournament Replacement (tournament_rep)

Analog zur Tournament Selection führt auch das Tournament Replacement ein Tournament durch,
bestimmt hier jedoch das schlechteste Chromosom.
Dieses Chromosom wird durch das neue, mutierte Kind-Chromosom ersetzt.
Es werden ähnlich zur Selection die Zustände Ready, Cache, Read und Compare durchlaufen,
wobei Compare auch das Schreiben des neuen Chromosoms in den RAM durchführt (konfigurierbar bedingt nur, wenn das Kind besser ist).

### LFSR

In allen Komponenten des Trainers werden Zufallswerte zum Zugriff auf RAM-Adressen oder zum Anpassen der Chromosome benötigt.
Diese werden von einem linear-rückgekoppelten Schieberegister bereitgestellt.
Hierbei werden stets primitive Polynome für eine maximale Periodenlänge verwendet.
Der Seed ist für jedes instanziierte LFSR statisch festgelegt und wird einer vorgefertigen Liste von Beispiel-Seeds entnommen.
Optional könnte dieser Seed z.B. als Generic nach außen zur Konfiguration freigegeben werden.
Eine Anpassung des Seeds war jedoch bisher noch nie notwendig,
da auch bei Tests mit verschiedenen Seeds stets eine Lösung in ähnlicher Zeit gefunden wurde,
weshalb auf die Konfigurierbarkeit hier verzichtet wurde (insbesondere aufgrund der großen Anzahl von notwendigen Seeds).

### Testbenches

Alle Teil-Komponenten wurden mithilfe von Testbenches erfolgreich validiert (siehe Ordner `test/ga_linreg` bzw. allgemeine Komponenten in anderen Unterordnern).
