"""
GA-Mechanismen (alle via PyGAD-Subklasse):
  Selektion    : tournament_selection  – besten aus K=3 (nativ in PyGAD, überschrieben)
  Crossover    : uniform_crossover     – Gen zufällig von Elter 1 oder 2 (nativ)
  Mutation     : arithmetic_mutation   – Gen += U(-delta, +delta) (überschrieben)
  Replacement  : tournament_replace    – schlechtesten aus 3 ersetzen, nur wenn Kind besser
                                       (run_update_population überschrieben)
"""
import datetime
import time

import numpy as np
import numpy
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import pandas as pd
import pygad

## 1. Datengenerierung ##
dataFrameLinReg = pd.read_csv('../data/lineare_regression2.csv')

X = dataFrameLinReg['x'].to_numpy()
Y = dataFrameLinReg['y'].to_numpy()


print(f"Geladene Datenpunkte: {len(X)}")
print(f"X-Bereich: [{X.min():.3f}, {X.max():.3f}]")
print(f"Y-Bereich: [{Y.min():.3f}, {Y.max():.3f}]")

## 2. Fitnessfunktion ##
fitness_history: list[float] = []

def fitness_func(ga_instance, solution, solution_idx):
    m, b = solution
    mse  = np.mean((Y - (m * X + b)) ** 2)
    return -mse   # PyGAD maximiert -> negativer MSE

def on_generation(ga_instance):
    fitness_history.append(-ga_instance.best_solution()[1])

## 3. PyGAD-Subklasse mit überschriebenen Methoden ##
MUT_DELTA = 0.5   # maximale arithmetische Schrittweite
MUT_PROB = 0.3   # Mutationswahrscheinlichkeit pro Gen

class CustomGA(pygad.GA):

    def random_mutation(self, offspring):
        """
        Arithmetic Mutation: überschreibt PyGADs random_mutation.
        Jedes Gen wird mit Wahrscheinlichkeit MUT_PROB um einen
        gleichverteilten Zufallswert aus [-MUT_DELTA, +MUT_DELTA] verändert.
        """
        for index in range(offspring.shape[0]):
            for gene_index in range(offspring.shape[1]):
                if np.random.rand() < MUT_PROB:
                    offspring[index, gene_index] += np.random.uniform(-MUT_DELTA, MUT_DELTA)
        return offspring

    def run_update_population(self):
        """
        Tournament Replacement: überschreibt PyGADs run_update_population.
        Für jedes Kind aus last_generation_offspring_mutation:
          - ziehe 3 zufällige Individuen aus der aktuellen Population
          - ersetze den Schlechtesten (höchster MSE = niedrigster Fitness),
            aber nur wenn das Kind besser ist als er.
        """
        offspring = self.last_generation_offspring_mutation
        fitness = self.last_generation_fitness  # fitness der aktuellen Population

        for child in offspring:
            child_fitness = fitness_func(self, child, None)

            indices = numpy.random.choice(len(self.population), 3, replace=False)
            worst_idx = min(indices, key=lambda i: fitness[i])  # kleinste Fitness = schlechtester

            if child_fitness > fitness[worst_idx]:
                self.population[worst_idx] = child
                fitness[worst_idx]         = child_fitness

        # PyGAD erwartet, dass last_generation_fitness aktuell bleibt
        self.last_generation_fitness = fitness

## GA-Instanz und Start ##
ga = CustomGA(
    num_generations = 300,
    num_parents_mating = 2, # je 1x Tournament → 2 Eltern
    fitness_func = fitness_func,
    sol_per_pop = 50,
    num_genes = 2, # [m, b]
    gene_space = [
        {"low": -10, "high": 10},
        {"low": -10, "high": 10},
    ],
    parent_selection_type = "tournament",
    K_tournament = 3, # besten aus 3 wählen
    crossover_type = "uniform", # Gen zufällig von Elter 1 oder 2
    mutation_type = "random", # wird durch arithmetic_mutation überschrieben
    mutation_percent_genes = 100, # alle Gene der Mutation anbieten (interne Steuerung via MUT_PROB)
    keep_elitism = 0, # Elitismus, Replacement übernimmt das
    keep_parents = 0,
    on_generation = on_generation,
    suppress_warnings = True,
)

print("Starte genetischen Algorithmus …")
start_time = time.time_ns()
ga.run()
end_time = time.time_ns()

solution, fitness, _ = ga.best_solution()
m_pred, b_pred = solution
mse_final = -fitness

print(f"Berechnungszeit: {(end_time - start_time) / (10 ** 9)}")
print(f"  GA-Ergebnis     :  m = {m_pred:.4f},  b = {b_pred:.4f}")
print(f"  Finaler MSE     :  {mse_final:.6f}")

## 5. Visualisierung ##
fig = plt.figure(figsize=(13, 5))
fig.suptitle("Lineare Regression via Genetischen Algorithmus (PyGAD)",
             fontsize=14, fontweight="bold")

gs = gridspec.GridSpec(1, 2, figure=fig, wspace=0.35)

ax1 = fig.add_subplot(gs[0])
ax1.scatter(X, Y, color="#4C72B0", alpha=0.7, s=40, label="Messdaten")
ax1.plot(X, m_pred * X + b_pred, "r-", lw=2.5,
         label=f"GA-Ergebnis   (m={m_pred:.3f}, b={b_pred:.3f})")
ax1.set_xlabel("x")
ax1.set_ylabel("y")
ax1.set_title("Regression")
ax1.legend(fontsize=9)
ax1.grid(True, alpha=0.3)

ax2 = fig.add_subplot(gs[1])
ax2.plot(fitness_history, color="#DD4444", lw=1.8)
ax2.set_xlabel("Generation")
ax2.set_ylabel("MSE")
ax2.set_title("Fitnessverlauf (MSE)")
ax2.set_yscale("log")
ax2.grid(True, alpha=0.3)

#plt.savefig("graphs/" + datetime.datetime.now().strftime('%m-%d-%Y_%H-%M-%S') + "Cusotm_linreg_ga.png", dpi=150, bbox_inches="tight")
plt.close()