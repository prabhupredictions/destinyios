# ios_app/e2e/test_17_style_self.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_identity_fatalism(text: str):
    phrases = ["you are destined to fail", "you will never succeed", "you cannot change"]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Fatalistic identity phrase found: '{phrase}'"


class TestStyleSelf:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_self_core_identity(self, screens):
        """self_core: core identity — plain language, no planets, timing window, ≥50w."""
        response = self._ask_and_get(screens, "Who am I? What is my core personality and character?")
        assert_min_words(response, 50)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_self_potential_strengths(self, screens):
        """self_potential: strengths and life path — no planets, no fatalism, timing."""
        response = self._ask_and_get(
            screens, "What are my natural strengths? What is my life path?"
        )
        assert_min_words(response, 50)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_identity_fatalism(response)
        screens.chat.tap_back()

    def test_self_aspiration_confidence(self, screens):
        """self_aspiration: confidence and leadership — no guarantees, plain language, timing."""
        response = self._ask_and_get(
            screens, "Am I a confident person? What is my leadership style?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_self_fortune_luck(self, screens):
        """self_fortune: luck and appearance — no guarantees, no planets, timing window."""
        response = self._ask_and_get(
            screens, "Am I a lucky person? What does my appearance say about me?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()
