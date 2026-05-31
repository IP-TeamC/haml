import datetime

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import pygad

## Datengenerierung ##
np.random.seed(42)
N = 50
X = np.linspace(0, 10, N)

TRUE_M = 2.5      # wahre Steigung
TRUE_B = -1.2     # wahrer Achsenabschnitt
noise = np.random.normal(0, 1.5, N)
Y = TRUE_M * X + TRUE_B + noise

## Fitnessfunktion ##
fitness_history: list[float] = []

def fitness_func(ga_instance, solution, solution_idx):
    m, b = solution
    y_pred = m * X + b
    mse = np.mean((Y - y_pred) ** 2)
    return -mse          # negativ, da PyGAD maximiert

def on_generation(ga_instance):
    best_fitness = ga_instance.best_solution()[1]
    fitness_history.append(-best_fitness)   # MSE speichern

## GA-Konfiguration ##
ga = pygad.GA(
    num_generations = 300,
    num_parents_mating = 10,
    fitness_func = fitness_func,
    sol_per_pop = 50,
    num_genes = 2, # [m, b]
    gene_space = [
        {"low": -10, "high": 10},               # Suchraum für m
        {"low": -10, "high": 10},               # Suchraum für b
    ],
    parent_selection_type = "tournament",
    keep_elitism = 3,
    crossover_type = "single_point",
    mutation_type = "random",
    mutation_percent_genes = 20,
    random_mutation_min_val = -0.5,
    random_mutation_max_val =  0.5,
    on_generation = on_generation,
    suppress_warnings = True,
)

## Evolution starten ##
print("GA start")
ga.run()

solution, fitness, _ = ga.best_solution()
m_pred, b_pred = solution
mse_final = -fitness

print(f"  Wahre Parameter :  m = {TRUE_M:.4f},  b = {TRUE_B:.4f}")
print(f"  GA-Ergebnis     :  m = {m_pred:.4f},  b = {b_pred:.4f}")
print(f"  Finaler MSE     :  {mse_final:.6f}")

## Visualisierung ##
fig = plt.figure(figsize=(13, 5))
fig.suptitle("Lineare Regression via Genetischen Algorithmus (PyGAD)",
             fontsize=14, fontweight="bold")

gs = gridspec.GridSpec(1, 2, figure=fig, wspace=0.35)

## Linkes Diagramm: Regressionsgerade ##
ax1 = fig.add_subplot(gs[0])
ax1.scatter(X, Y, color="#4C72B0", alpha=0.7, s=40, label="Messdaten")
ax1.plot(X, TRUE_M * X + TRUE_B, "g--", lw=2,
         label=f"Wahre Gerade  (m={TRUE_M}, b={TRUE_B})")
ax1.plot(X, m_pred * X + b_pred, "r-",  lw=2.5,
         label=f"GA-Ergebnis   (m={m_pred:.3f}, b={b_pred:.3f})")
ax1.set_xlabel("x")
ax1.set_ylabel("y")
ax1.set_title("Regression")
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3)

## Rechtes Diagramm: MSE-Verlauf ##
ax2 = fig.add_subplot(gs[1])
ax2.plot(fitness_history, color="#DD4444", lw=1.8)
ax2.set_xlabel("Generation")
ax2.set_ylabel("MSE")
ax2.set_title("Fitnessverlauf (MSE)")
ax2.set_yscale("log")
ax2.grid(True, alpha=0.3)

plt.savefig("graphs/" + datetime.datetime.now().strftime('%m-%d-%Y_%H-%M-%S') + "linreg_ga.png", dpi=150, bbox_inches="tight")
plt.close()