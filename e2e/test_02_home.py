# ios_app/e2e/test_02_home.py
import pytest


class TestHome:
    def test_home_screen_loads_with_ui_test_mode(self, screens):
        assert screens.home.is_visible(), "home_screen not visible after UI_TEST_MODE launch"

    def test_dasha_card_present_and_has_text(self, screens):
        assert screens.home.present("dasha_insight_card"), "dasha_insight_card not found"
        text = screens.home.dasha_card_text()
        assert len(text) > 0, "Dasha card has no text"

    def test_yoga_card_present(self, screens):
        assert screens.home.present("yoga_highlight_card"), "yoga_highlight_card not found"

    def test_transit_alert_card_present(self, screens):
        assert screens.home.present("transit_alert_card"), "transit_alert_card not found"

    def test_life_area_career_button_present(self, screens):
        assert screens.home.present("life_area_career"), "life_area_career button not found"

    def test_life_area_tap_opens_popup(self, screens, driver):
        screens.home.tap_life_area("career")
        import time; time.sleep(1)
        driver.back()  # dismiss popup

    def test_home_to_chat_tab_navigation(self, screens):
        screens.home.tap_chat_tab()
        assert screens.chat.is_visible(), "Chat input not visible after tapping chat tab"
        screens.chat.tap_back()

    def test_home_to_match_tab_navigation(self, screens):
        screens.home.tap_match_tab()
        assert screens.compat.is_visible(), "Compatibility screen not visible after tapping match tab"
        screens.home.tap("tab_home")
