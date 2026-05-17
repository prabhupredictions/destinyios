# ios_app/e2e/test_13_style_health.py
from helpers.assertions import (
    assert_min_words, assert_no_disease_names, assert_no_fatalistic,
)


class TestStyleHealth:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_health_constitution_response(self, screens):
        """health_constitution: overall health — no disease names, conditional phrasing."""
        response = self._ask_and_get(screens, "What is my overall health and vitality according to my chart?")
        assert_no_disease_names(response)
        assert_no_fatalistic(response)
        assert_min_words(response, 30)
        conditional_words = ["tendency", "prone", "suggests", "may", "could", "watchful"]
        assert any(w in response.lower() for w in conditional_words), \
            "Response lacks conditional language (tendency/may/suggests)"
        screens.chat.tap_back()

    def test_health_illness_response(self, screens):
        """health_illness: vulnerabilities — no disease names, body system language."""
        response = self._ask_and_get(
            screens, "What health vulnerabilities should I be watchful of based on my chart?"
        )
        assert_no_disease_names(response)
        assert_no_fatalistic(response)
        assert_min_words(response, 30)
        screens.chat.tap_back()

    def test_health_preventive_response(self, screens):
        """health_preventive: hereditary — awareness framing, no disease prediction."""
        response = self._ask_and_get(
            screens, "Are there any hereditary health patterns I should be aware of?"
        )
        assert_no_disease_names(response)
        assert_no_fatalistic(response)
        awareness_words = ["awareness", "aware", "preventive", "checkup", "monitor", "watchful"]
        assert any(w in response.lower() for w in awareness_words), \
            "Response lacks awareness/preventive framing"
        screens.chat.tap_back()

    def test_health_acute_response(self, screens):
        """health_acute: surgery/accidents — no fatalistic, professional consultation note."""
        response = self._ask_and_get(
            screens, "What does my chart indicate about surgery or accident risks?"
        )
        assert_no_disease_names(response)
        assert_no_fatalistic(response)
        consult_words = ["consult", "doctor", "medical", "professional", "physician"]
        assert any(w in response.lower() for w in consult_words), \
            "Response lacks professional consultation recommendation"
        screens.chat.tap_back()
