"""
Predict - Load trained ML model and predict complaint category.
"""

import os
import pickle

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, 'model.pkl')
VECTORIZER_PATH = os.path.join(BASE_DIR, 'vectorizer.pkl')

_model = None
_vectorizer = None


def _load_model():
    """Lazy-load the ML model and vectorizer."""
    global _model, _vectorizer
    if _model is None:
        if not os.path.exists(MODEL_PATH) or not os.path.exists(VECTORIZER_PATH):
            raise FileNotFoundError(
                "Model not found. Run 'python train_model.py' first to train the model."
            )
        with open(MODEL_PATH, 'rb') as f:
            _model = pickle.load(f)
        with open(VECTORIZER_PATH, 'rb') as f:
            _vectorizer = pickle.load(f)


def predict_category(text):
    """Predict the complaint category from description text."""
    _load_model()
    tfidf = _vectorizer.transform([text])
    prediction = _model.predict(tfidf)[0]
    probabilities = _model.predict_proba(tfidf)[0]
    confidence = max(probabilities)
    return {
        'category': prediction,
        'confidence': round(float(confidence), 4),
    }


if __name__ == '__main__':
    # Quick test
    test_texts = [
        "There is a big pothole on the main road",
        "No water supply since yesterday morning",
        "Garbage is piling up near the bus stop",
    ]
    for text in test_texts:
        result = predict_category(text)
        print(f"Text: {text}")
        print(f"  → Category: {result['category']} (confidence: {result['confidence']:.2%})\n")
