# Generated
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score

df = pd.read_csv("../data/wine_quality.csv")

X = df[["fixed acidity","volatile acidity","citric acid","residual sugar","chlorides","free sulfur dioxide","total sulfur dioxide","density","pH","sulphates","alcohol"]]
y = df[["quality"]]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.01, random_state=42
)

model = LinearRegression()
model.fit(X_train, y_train)

y_pred = model.predict(X_test)

print("Koeffizienten:")
print(f"fixed acidity        = {model.coef_[0][0]:.4f}")
print(f"volatile acidity     = {model.coef_[0][1]:.4f}")
print(f"citric acid          = {model.coef_[0][2]:.4f}")
print(f"residual sugar       = {model.coef_[0][3]:.4f}")
print(f"chlorides            = {model.coef_[0][4]:.4f}")
print(f"free sulfur dioxide  = {model.coef_[0][5]:.4f}")
print(f"total sulfur dioxide = {model.coef_[0][6]:.4f}")
print(f"density              = {model.coef_[0][7]:.4f}")
print(f"pH                   = {model.coef_[0][8]:.4f}")
print(f"sulphates            = {model.coef_[0][9]:.4f}")
print(f"alcohol              = {model.coef_[0][10]:.4f}")

print(f"\nIntercept = {model.intercept_[0]:.4f}")

mse = mean_squared_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print(f"\nMSE = {mse:.2f}")
print(f"R²  = {r2:.4f}")