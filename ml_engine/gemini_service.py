"""
AI Complaint Service.
Supports GLM and Gemini providers for complaint classification and urgency analysis.
Falls back to local ML when remote APIs are unavailable.
"""

import os
import sys
import json
import threading
from typing import Any

import requests

# Add backend to path for config
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from config import Config  # type: ignore

try:
    import google.generativeai as genai  # type: ignore
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

AI_PROVIDER = (os.environ.get('AI_PROVIDER') or Config.AI_PROVIDER or 'glm').lower().strip()

GLM_API_KEY = os.environ.get('GLM_API_KEY') or Config.GLM_API_KEY
GLM_MODEL = os.environ.get('GLM_MODEL') or Config.GLM_MODEL
GLM_API_URL = os.environ.get('GLM_API_URL') or Config.GLM_API_URL

GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY') or Config.GEMINI_API_KEY

_model = None


def _clean_json_text(text: str) -> str:
    """Normalize model output and strip markdown wrappers."""
    cleaned = (text or '').strip()
    if cleaned.startswith('```'):
        cleaned = cleaned.split('\n', 1)[1] if '\n' in cleaned else cleaned[3:]
    if cleaned.endswith('```'):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()
    if cleaned.startswith('json'):
        cleaned = cleaned[4:].strip()
    return cleaned


def _parse_json_text(text: str) -> dict:
    """Parse JSON text returned by the provider."""
    return json.loads(_clean_json_text(text))


def _normalize_result(result: dict, source: str) -> dict:
    """Normalize shared fields from provider output."""
    result['category'] = str(result.get('category', 'other')).lower().strip()
    result['priority'] = str(result.get('priority', 'medium')).lower().strip()
    result['source'] = source
    return result


def _get_model():
    """Initialize Gemini model lazily."""
    global _model
    if _model is None and GEMINI_AVAILABLE and GEMINI_API_KEY:
        genai.configure(api_key=GEMINI_API_KEY)
        _model = genai.GenerativeModel('gemini-2.0-flash')
    return _model


def _extract_content_text(message_content: Any) -> str:
    """Normalize provider content into plain text."""
    if isinstance(message_content, str):
        return message_content
    if isinstance(message_content, list):
        parts = []
        for item in message_content:
            if isinstance(item, dict):
                parts.append(item.get('text') or item.get('content') or '')
            else:
                parts.append(str(item))
        return ''.join(parts)
    return str(message_content)


def _call_glm_json(prompt: str) -> dict:
    """Call GLM chat completions endpoint and parse JSON output."""
    if not GLM_API_KEY:
        raise RuntimeError('GLM_API_KEY is not configured')

    response = requests.post(
        GLM_API_URL,
        headers={
            'Authorization': f'Bearer {GLM_API_KEY}',
            'Content-Type': 'application/json',
        },
        json={
            'model': GLM_MODEL,
            'messages': [
                {'role': 'system', 'content': 'You are an assistant that returns strict JSON only.'},
                {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
        },
        timeout=6,
    )
    response.raise_for_status()

    payload = response.json()
    choices = payload.get('choices') or []
    if not choices:
        raise RuntimeError('GLM response missing choices')

    message = choices[0].get('message', {})
    content = _extract_content_text(message.get('content', ''))
    return _parse_json_text(content)


def _classify_with_glm(complaint_text: str) -> dict:
    """Classify complaint using GLM."""
    prompt = f"""You are an AI assistant for a Civic Grievance System in India.
Analyze the following citizen complaint and return ONLY a valid JSON object.

Complaint: \"{complaint_text}\"

Return JSON with these exact keys:
{{
  \"category\": \"<one of: roads, water, electricity, sanitation, garbage>\",
  \"department\": \"<the government department responsible>\",
  \"priority\": \"<one of: low, medium, high>\",
  \"urgency_score\": <number 1-10>,
  \"summary\": \"<one sentence summary of the issue>\",
  \"suggested_action\": \"<what the department should do>\"
}}

Rules:
- Category MUST be one of: roads, water, electricity, sanitation, garbage
- Priority should be 'high' for safety/health hazards, 'low' for cosmetic issues
- Be concise in summary and suggested_action
- Return ONLY the JSON, no extra text"""

    result = _call_glm_json(prompt)
    return _normalize_result(result, 'glm-ai')


def _classify_with_gemini(complaint_text: str) -> dict | None:
    """Classify complaint using Gemini."""
    model = _get_model()
    if model is None:
        return None

    prompt = f"""You are an AI assistant for a Civic Grievance System in India.
Analyze the following citizen complaint and return ONLY a valid JSON object.

Complaint: \"{complaint_text}\"

Return JSON with these exact keys:
{{
  \"category\": \"<one of: roads, water, electricity, sanitation, garbage>\",
  \"department\": \"<the government department responsible>\",
  \"priority\": \"<one of: low, medium, high>\",
  \"urgency_score\": <number 1-10>,
  \"summary\": \"<one sentence summary of the issue>\",
  \"suggested_action\": \"<what the department should do>\"
}}

Rules:
- Category MUST be one of: roads, water, electricity, sanitation, garbage
- Priority should be 'high' for safety/health hazards, 'low' for cosmetic issues
- Be concise in summary and suggested_action
- Return ONLY the JSON, no extra text"""

    result_container: list[Any] = [None]
    error_container: list[Any] = [None]

    def call_gemini() -> None:
        try:
            result_container[0] = model.generate_content(prompt)
        except Exception as ex:
            error_container[0] = ex

    thread = threading.Thread(target=call_gemini, daemon=True)
    thread.start()
    thread.join(timeout=5)

    if thread.is_alive() or result_container[0] is None:
        print('WARNING: Gemini API timed out, skipping Gemini provider')
        return None

    if error_container[0]:
        print(f"WARNING: Gemini API error: {error_container[0]}")
        return None

    response = result_container[0]
    result = _parse_json_text(response.text)
    return _normalize_result(result, 'gemini-ai')


def _analyze_urgency_with_glm(complaint_text: str) -> dict:
    """Analyze urgency using GLM."""
    prompt = f"""Rate the urgency of this civic complaint on a scale of 1-10.
Return ONLY a JSON object.

Complaint: \"{complaint_text}\"

{{
  \"urgency_score\": <1-10>,
  \"priority\": \"<low/medium/high>\",
  \"reason\": \"<why this urgency level>\",
  \"affected_people\": \"<estimated: few/many/large_area>\",
  \"safety_risk\": <true/false>
}}"""

    result = _call_glm_json(prompt)
    if 'urgency_score' not in result:
        result['urgency_score'] = 5
    if 'priority' not in result:
        result['priority'] = 'medium'
    return result


def _analyze_urgency_with_gemini(complaint_text: str) -> dict | None:
    """Analyze urgency using Gemini."""
    model = _get_model()
    if model is None:
        return None

    prompt = f"""Rate the urgency of this civic complaint on a scale of 1-10.
Return ONLY a JSON object.

Complaint: \"{complaint_text}\"

{{
  \"urgency_score\": <1-10>,
  \"priority\": \"<low/medium/high>\",
  \"reason\": \"<why this urgency level>\",
  \"affected_people\": \"<estimated: few/many/large_area>\",
  \"safety_risk\": <true/false>
}}"""

    try:
        response = model.generate_content(prompt)
        return _parse_json_text(response.text)
    except Exception as e:
        print(f"WARNING: Gemini urgency analysis error: {e}")
        return None


def classify_complaint(complaint_text: str) -> dict:
    """Classify complaint with configured provider and fallback chain."""
    provider = AI_PROVIDER or 'glm'

    if provider in ('glm', 'auto'):
        try:
            return _classify_with_glm(complaint_text)
        except Exception as e:
            print(f"WARNING: GLM classify error: {e}")

    if provider in ('gemini', 'auto'):
        gemini_result = _classify_with_gemini(complaint_text)
        if gemini_result:
            return gemini_result

    return _fallback_classify(complaint_text)


def analyze_urgency(complaint_text: str) -> dict:
    """Analyze urgency with configured provider and fallback chain."""
    provider = AI_PROVIDER or 'glm'

    if provider in ('glm', 'auto'):
        try:
            return _analyze_urgency_with_glm(complaint_text)
        except Exception as e:
            print(f"WARNING: GLM urgency analysis error: {e}")

    if provider in ('gemini', 'auto'):
        gemini_result = _analyze_urgency_with_gemini(complaint_text)
        if gemini_result:
            return gemini_result

    return {'urgency_score': 5, 'priority': 'medium', 'reason': 'Fallback - AI unavailable'}


def _fallback_classify(complaint_text: str) -> dict:
    """Fallback to local ML model when remote AI APIs are unavailable."""
    try:
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'ml_engine'))
        from predict import predict_category  # type: ignore
        result = predict_category(complaint_text)
        from routing_engine import route_complaint  # type: ignore
        return {
            'category': result['category'],
            'department': route_complaint(result['category']),
            'priority': 'medium',
            'urgency_score': 5,
            'summary': complaint_text[:100],
            'suggested_action': 'Review and assign to relevant team',
            'source': 'local-ml-fallback',
            'confidence': result.get('confidence', 0),
        }
    except Exception as e:
        return {
            'category': 'other',
            'department': 'General Administration',
            'priority': 'medium',
            'urgency_score': 5,
            'summary': complaint_text[:100],
            'suggested_action': 'Manual review required',
            'source': 'error-fallback',
            'error': str(e),
        }


if __name__ == '__main__':
    test_complaints = [
        'There is a huge pothole on MG Road causing accidents',
        'No water supply for 3 days in our colony',
        'Garbage piling up near the school, causing health issues',
    ]
    print('AI Complaint Classifier\n' + '=' * 50)
    for text in test_complaints:
        print(f"\nComplaint: {text}")
        result = classify_complaint(text)
        print(f"   Category:   {result.get('category')}")
        print(f"   Department: {result.get('department')}")
        print(f"   Priority:   {result.get('priority')}")
        print(f"   Source:     {result.get('source')}")
