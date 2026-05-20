# von chatty generiert

# Datensatz für y = 3x + 12 erzeugen
# 64 Zeilen mit negativen und positiven x-Werten
# Ausgabe als CSV-Datei

import csv

# Bereich definieren
x_values = range(-32, 32)  # ergibt 64 Werte

# CSV-Datei schreiben
with open("f3x12.csv", mode="w", newline="") as file:
    writer = csv.writer(file)

    # Kopfzeile
    writer.writerow(["x", "y"])

    # Daten schreiben
    for x in x_values:
        y = 3 * x + 12
        writer.writerow([x, y])

print("CSV-Datei 'f3x12.csv' wurde erstellt.")