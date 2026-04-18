"""
ML Model Training - TF-IDF + Naive Bayes classifier for complaint categorization.
Trains on complaints_1500.csv (columns: complaint_text, category).
Categories: Electricity, Garbage, Roads, Sanitation, Water
"""

import os
import pickle
import sys
import pandas as pd  # type: ignore
from sklearn.feature_extraction.text import TfidfVectorizer  # type: ignore
from sklearn.naive_bayes import MultinomialNB  # type: ignore
from sklearn.model_selection import train_test_split  # type: ignore
from sklearn.metrics import classification_report, accuracy_score  # type: ignore

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.abspath(os.path.join(BASE_DIR, '..'))
MODEL_PATH = os.path.join(BASE_DIR, 'model.pkl')
VECTORIZER_PATH = os.path.join(BASE_DIR, 'vectorizer.pkl')

# Dataset is in database/ folder
DATASET_PATH = os.path.join(PROJECT_DIR, 'database', 'complaints_1500.csv')


def train():
    """Train the ML model using complaints_1500.csv."""
    # Load dataset
    if not os.path.exists(DATASET_PATH):
        print(f"❌ Dataset not found at: {DATASET_PATH}")
        print("   Please place complaints_1500.csv in the database/ folder.")
        sys.exit(1)

    df = pd.read_csv(DATASET_PATH)
    print(f"📊 Loaded dataset: {len(df)} rows")
    print(f"   Columns: {list(df.columns)}")
    print(f"   Categories: {df['category'].unique().tolist()}")

    # Dataset uses 'complaint_text' column
    if 'complaint_text' in df.columns:
        text_col = 'complaint_text'
    elif 'description' in df.columns:
        text_col = 'description'
    else:
        print(f"❌ Dataset must have 'complaint_text' or 'description' column.")
        print(f"   Found columns: {list(df.columns)}")
        sys.exit(1)

    X = df[text_col].fillna('')
    y = df['category'].fillna('Other')

    # Normalize categories to lowercase for consistency
    y = y.str.lower().str.strip()

    print(f"\n📊 Category Distribution:")
    for cat, count in y.value_counts().items():
        print(f"   {cat}: {count}")

    # Split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # TF-IDF Vectorization
    vectorizer = TfidfVectorizer(max_features=5000, stop_words='english')
    X_train_tfidf = vectorizer.fit_transform(X_train)
    X_test_tfidf = vectorizer.transform(X_test)

    # Train classifier
    model = MultinomialNB()
    model.fit(X_train_tfidf, y_train)

    # Evaluate
    y_pred = model.predict(X_test_tfidf)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\n✅ Model Accuracy: {accuracy:.2%}")
    print("\n📋 Classification Report:")
    print(classification_report(y_test, y_pred))

    # Save model and vectorizer
    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(model, f)
    with open(VECTORIZER_PATH, 'wb') as f:
        pickle.dump(vectorizer, f)

    print(f"💾 Model saved to {MODEL_PATH}")
    print(f"💾 Vectorizer saved to {VECTORIZER_PATH}")
    print("\n✅ Training complete! Model is ready for predictions.")


if __name__ == '__main__':
    train()
