# ios_app/e2e/test_14_style_travel.py
from helpers.assertions import assert_min_words, assert_no_guarantees, assert_has_timing_window


class TestStyleTravel:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_travel_foreign_response(self, screens):
        """travel_foreign group: abroad travel/settlement — timing window, ≥50 words."""
        response = self._ask_and_get(screens, "What does my chart say about travelling or settling abroad?")
        assert_min_words(response, 50)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_travel_career_response(self, screens):
        """travel_career group: work abroad — career framing present."""
        response = self._ask_and_get(
            screens, "Is there a job transfer or opportunity to work abroad in my chart?"
        )
        assert_min_words(response, 30)
        career_words = ["career", "job", "work", "professional", "transfer", "posting"]
        assert any(w in response.lower() for w in career_words), \
            "Response lacks career framing"
        screens.chat.tap_back()

    def test_travel_legal_response(self, screens):
        """travel_legal group: visa/immigration — no guarantees, candid risk."""
        response = self._ask_and_get(
            screens, "What are my chances of getting a visa or immigrating?"
        )
        assert_no_guarantees(response)
        assert_min_words(response, 30)
        screens.chat.tap_back()

    def test_travel_education_response(self, screens):
        """travel_education group: study abroad — no guarantees."""
        response = self._ask_and_get(screens, "Can I study abroad based on my birth chart?")
        assert_no_guarantees(response)
        assert_min_words(response, 30)
        screens.chat.tap_back()

    def test_travel_relocation_response(self, screens):
        """travel_relocation group: relocate — open verdict."""
        response = self._ask_and_get(screens, "Should I relocate to another city or country?")
        assert_min_words(response, 30)
        assert_no_guarantees(response)
        screens.chat.tap_back()
