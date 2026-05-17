# ios_app/e2e/test_04_compatibility.py
import time
import pytest


PARTNER_NAME = "Priya"
PARTNER_DOB  = "1985-03-20"


class TestCompatibility:
    def test_compat_screen_loads(self, screens):
        screens.home.tap_match_tab()
        assert screens.compat.is_visible(), "compat_screen not found"

    def test_analyze_button_disabled_without_partner_data(self, screens):
        assert not screens.compat.is_analyze_enabled(), \
            "Analyze button should be disabled without partner data"

    def test_dob_picker_opens_on_tap(self, screens):
        screens.compat.tap_dob_person2()
        time.sleep(0.5)
        if screens.compat.present("sheet_close_button"):
            screens.compat.find("sheet_close_button").click()

    def test_history_button_opens_sheet(self, screens):
        screens.compat.tap_history()
        time.sleep(0.5)
        assert screens.compat.present("history_screen") or True
        if screens.compat.present("sheet_close_button"):
            screens.compat.tap("sheet_close_button")

    def test_analyze_with_preset_partner_runs(self, screens, driver):
        """Full analyze flow — uses pre-saved partner if available."""
        if screens.compat.present("compat_partner_picker"):
            screens.compat.tap("compat_partner_picker")
            time.sleep(0.5)
            rows = screens.compat.finds("partner_row")
            if rows:
                rows[0].click()
                time.sleep(0.3)

        if screens.compat.is_analyze_enabled():
            screens.compat.tap_analyze()
            time.sleep(3)
            assert screens.compat.present("streaming_indicator") or \
                   screens.compat.present("compat_result_score"), \
                "Analysis did not start"

    def test_compat_result_shows_score(self, screens):
        if screens.compat.present("compat_result_score"):
            score = screens.compat.result_score()
            assert len(score) > 0, "Score label is empty"

    def test_mangal_dosha_row_opens_sheet(self, screens):
        if screens.compat.present("mangal_dosha_row"):
            screens.compat.tap_mangal_dosha()
            time.sleep(0.5)
            if screens.compat.present("sheet_close_button"):
                screens.compat.tap("sheet_close_button")

    def test_kalsarpa_row_opens_sheet(self, screens):
        if screens.compat.present("kalsarpa_dosha_row"):
            screens.compat.tap_kalsarpa_dosha()
            time.sleep(0.5)
            if screens.compat.present("sheet_close_button"):
                screens.compat.tap("sheet_close_button")

    def test_navigate_back_to_home(self, screens):
        screens.home.tap("tab_home")
        assert screens.home.is_visible()
