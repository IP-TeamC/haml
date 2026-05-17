# von chatty generiert, als test

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score

# CSV laden
df = pd.read_csv("salary.csv")

# Features und Zielvariable
X = df[["yoe", "grade"]]
y = df[["salary"]]   # 2D für Scaler

# Normalisierung auf [-1, +1]
x_scaler = MinMaxScaler(feature_range=(-1, 1))
y_scaler = MinMaxScaler(feature_range=(-1, 1))

X_scaled = x_scaler.fit_transform(X)
y_scaled = y_scaler.fit_transform(y)

# Train/Test-Split
X_train, X_test, y_train, y_test = train_test_split(
    X_scaled, y_scaled, test_size=0.2, random_state=42
)

# Modell trainieren
model = LinearRegression()
model.fit(X_train, y_train)

# Vorhersagen
y_pred_scaled = model.predict(X_test)

# Zurückskalieren
y_pred = y_scaler.inverse_transform(y_pred_scaled)
y_test_real = y_scaler.inverse_transform(y_test)

# Koeffizienten
print("Koeffizienten:")
print(f"yoe   = {model.coef_[0][0]:.4f}")
print(f"grade = {model.coef_[0][1]:.4f}")

print(f"\nIntercept = {model.intercept_[0]:.4f}")

# Bewertung auf Originalskala
mse = mean_squared_error(y_test_real, y_pred)
r2 = r2_score(y_test_real, y_pred)

print(f"\nMSE = {mse:.2f}")
print(f"R²  = {r2:.4f}")

# Beispielvorhersage
sample = pd.DataFrame({
    "yoe": [2.0],
    "grade": [2.5]
})

# Eingaben skalieren
sample_scaled = x_scaler.transform(sample)

# Vorhersage
pred_scaled = model.predict(sample_scaled)

# Salary zurückskalieren
pred_salary = y_scaler.inverse_transform(pred_scaled)

print(f"\nVorhergesagtes Gehalt: {pred_salary[0][0]:.2f}")