# ios_app/e2e/test_18_style_spiritual.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_moksha_guarantee(text: str):
    phrases = ["you will achieve moksha", "you will attain liberation", "you are enlightened"]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Moksha guarantee found: '{phrase}'"


def assert_no_occult_certainty(text: str):
    phrases = ["you have psychic powers", "you are psychic", "you have occult powers"]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Occult certainty found: '{phrase}'"


class TestStyleSpiritual:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_spiritual_core_meditation(self, screens):
        """spiritual_core: meditation type — plain language, no planets, timing window, ≥50w."""
        response = self._ask_and_get(screens, "What type of meditation suits me? What is my spiritual nature?")
        assert_min_words(response, 50)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_spiritual_devotion_pilgrimage(self, screens):
        """spiritual_devotion: pilgrimage and guru — no planets, no specific religions, timing."""
        response = self._ask_and_get(
            screens, "Should I go on pilgrimage? Will I find a spiritual teacher?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_spiritual_deep_moksha(self, screens):
        """spiritual_deep: moksha/liberation — no guarantees, conditional language, no occult certainty."""
        response = self._ask_and_get(
            screens, "What is my moksha potential? What past-life karma shapes my life?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_moksha_guarantee(response)
        assert_no_occult_certainty(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        screens.chat.tap_back()
