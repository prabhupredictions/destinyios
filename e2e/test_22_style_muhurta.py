# ios_app/e2e/test_22_style_muhurta.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_single_date_mandate(text: str):
    phrases = [
        "only correct date",
        "the only date",
        "must happen on",
        "ceremony must be on",
        "no other date works",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Single-date mandate found: '{phrase}'"


def assert_no_ceremony_guarantee(text: str):
    phrases = [
        "ceremony will succeed",
        "marriage will be happy",
        "guaranteed success",
        "business will succeed because",
        "surgery will go well",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Ceremony success guarantee found: '{phrase}'"


def assert_no_medical_delay_advice(text: str):
    phrases = [
        "postpone your surgery",
        "delay the surgery",
        "wait for a better time for surgery",
        "avoid surgery until",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Medical delay advice found: '{phrase}'"


class TestStyleMuhurta:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_muhurta_life_events_marriage(self, screens):
        """muhurta_life_events: marriage timing — no single-date mandate, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "When is the best time for my marriage? What is a good muhurta for my wedding?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_single_date_mandate(response)
        assert_no_ceremony_guarantee(response)
        screens.chat.tap_back()

    def test_muhurta_transitions_business(self, screens):
        """muhurta_transitions: business launch timing — no guarantees, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "When should I start my business? What is the best muhurta for launching a new venture?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_ceremony_guarantee(response)
        screens.chat.tap_back()

    def test_muhurta_protection_surgery(self, screens):
        """muhurta_protection: surgery timing — no medical delay advice, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Is this a good time for my surgery? What does my chart say about medical procedures?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_medical_delay_advice(response)
        assert_no_ceremony_guarantee(response)
        screens.chat.tap_back()
