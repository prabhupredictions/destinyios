# ios_app/e2e/test_23_style_general.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_fatalism(text: str):
    phrases = [
        "your chart is doomed",
        "no hope",
        "permanent failure",
        "certain disaster",
        "you will never succeed",
        "chart is permanently blocked",
        "your life is cursed",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Fatalistic prediction found: '{phrase}'"


def assert_no_death_prediction(text: str):
    phrases = [
        "you will die",
        "death is indicated",
        "fatal outcome",
        "will not survive",
        "catastrophic end",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Death prediction found: '{phrase}'"


class TestStyleGeneral:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_general_overview_life_theme(self, screens):
        """general_overview: life theme reading — no fatalism, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Give me a full chart reading. What is my life theme and what am I suited for?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_fatalism(response)
        assert_no_death_prediction(response)
        screens.chat.tap_back()

    def test_general_overview_annual_forecast(self, screens):
        """general_overview: annual forecast — no guarantees, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "What does my year look like? What should I focus on in 2026?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_fatalism(response)
        screens.chat.tap_back()

    def test_general_overview_cross_domain(self, screens):
        """general_overview: cross-domain question — no fatalism, no death, timing, ≥40w."""
        response = self._ask_and_get(
            screens, "How is my overall chart? What are my biggest strengths and challenges in life?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_fatalism(response)
        assert_no_death_prediction(response)
        screens.chat.tap_back()
