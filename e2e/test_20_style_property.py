# ios_app/e2e/test_20_style_property.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_price_prediction(text: str):
    phrases = [
        "will cost exactly",
        "price will be",
        "sell for exactly",
        "guaranteed rental",
        "100% occupancy",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Price prediction found: '{phrase}'"


def assert_no_property_fatalism(text: str):
    phrases = [
        "you will never own property",
        "you cannot buy a house",
        "property is denied",
        "you will never have a home",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Property fatalism found: '{phrase}'"


class TestStyleProperty:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_property_buying_readiness(self, screens):
        """property_buying: buying readiness — no fatalism, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Should I buy property? Am I suited for buying a house or land?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_property_fatalism(response)
        screens.chat.tap_back()

    def test_property_building_construction(self, screens):
        """property_building: construction readiness — no guarantees, timing, ≥40w."""
        response = self._ask_and_get(
            screens, "Should I build my own house? What is my griha pravesh timing?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_property_income_rental(self, screens):
        """property_income: rental income and vehicles — no price predictions, timing, ≥40w."""
        response = self._ask_and_get(
            screens, "Can I earn from property? Should I buy a vehicle? What is my property income potential?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_price_prediction(response)
        screens.chat.tap_back()
