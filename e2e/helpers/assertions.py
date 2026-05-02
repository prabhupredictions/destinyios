# ios_app/e2e/helpers/assertions.py
import re

# Disease phrases (not bare zodiac sign "cancer")
DISEASE_PHRASES = [
    "cancer diagnosis", "cancer treatment", "cancer risk",
    "depression disorder", "anxiety disorder",
    "diabetes", "tumor", "malignant", "metastasis",
]
FATALISTIC = ["will die", "death is near", "fatal outcome", "you will not survive"]
GUARANTEE  = ["guaranteed", "you will definitely", "100% certain"]


def assert_no_disease_names(text: str):
    for phrase in DISEASE_PHRASES:
        assert phrase not in text.lower(), f"Disease phrase found: '{phrase}'"


def assert_no_fatalistic(text: str):
    for phrase in FATALISTIC:
        assert phrase not in text.lower(), f"Fatalistic phrase found: '{phrase}'"


def assert_no_guarantees(text: str):
    for phrase in GUARANTEE:
        assert phrase not in text.lower(), f"Guarantee phrase found: '{phrase}'"


def assert_no_bankruptcy(text: str):
    assert "bankruptcy" not in text.lower(), "Word 'bankruptcy' found in guidance"


def assert_has_timing_window(text: str):
    assert re.search(r"20\d\d", text), "No year/timing window found in response"


def assert_has_recovery_path(text: str):
    keywords = ["recovery", "stabilise", "stabilize", "rebuild", "protective", "improve"]
    assert any(k in text.lower() for k in keywords), "No recovery path found"


def assert_min_words(text: str, n: int = 50):
    count = len(text.split())
    assert count >= n, f"Response too short: {count} words (minimum {n})"
