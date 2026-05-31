# Generated
import time
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

df = pd.read_csv("../data/banana_quality.csv")

X = df.iloc[:, :-1]
y = df.iloc[:, -1]

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.745,
    random_state=42
)

start = time.perf_counter()
knn = KNeighborsClassifier(
    n_neighbors=3,
    metric="euclidean",
    p=2,
    algorithm="brute",
    n_jobs=1
)
knn.fit(X_train, y_train)
y_pred = knn.predict(X_test)
end = time.perf_counter()
print(f"Zeit: {(end - start) * 1000:.2f} ms")

accuracy = accuracy_score(y_test, y_pred)
print(f"\nAccuracy: {accuracy:.4f}")

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, y_pred))

print("\nClassification Report:")
print(classification_report(y_test, y_pred))
