# Generated
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score

df = pd.read_csv("../data/salary.csv")

X = df[["yoe", "grade"]]
y = df[["salary"]]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.01, random_state=42
)

model = LinearRegression()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)

print("Koeffizienten:")
print(f"yoe   = {model.coef_[0][0]:.4f}")
print(f"grade = {model.coef_[0][1]:.4f}")

print(f"\nIntercept = {model.intercept_[0]:.4f}")

mse = mean_squared_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print(f"\nMSE = {mse:.2f}")
print(f"R²  = {r2:.4f}")