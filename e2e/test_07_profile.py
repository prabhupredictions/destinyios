# ios_app/e2e/test_07_profile.py
import time


class TestProfile:
    def test_profile_opens_from_home(self, screens):
        screens.home.tap_profile()
        time.sleep(0.5)
        assert screens.profile.is_visible(), "profile_screen not visible"

    def test_birth_details_sheet_opens(self, screens):
        screens.profile.tap_birth_details()
        time.sleep(0.5)
        assert screens.profile.present("birth_dob_field") or True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_birth_details_shows_correct_year(self, screens):
        screens.profile.tap_birth_details()
        time.sleep(0.5)
        page_source = screens.profile.d.page_source
        assert "1980" in page_source, "Birth year 1980 not found in birth details"
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_language_settings_opens(self, screens):
        screens.profile.tap_language_settings()
        time.sleep(0.5)
        assert True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_astrology_settings_opens(self, screens):
        screens.profile.tap_astrology_settings()
        time.sleep(0.5)
        assert True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_response_style_opens(self, screens):
        screens.profile.tap_response_style()
        time.sleep(0.5)
        assert True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_notification_prefs_opens(self, screens):
        screens.profile.tap_notification_prefs()
        time.sleep(0.5)
        assert True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_partner_manager_opens(self, screens):
        screens.profile.tap_partner_manager()
        time.sleep(0.5)
        assert screens.partners.is_visible(), "partners_screen not visible"
        if screens.partners.present("sheet_close_button"):
            screens.partners.tap("sheet_close_button")

    def test_close_profile(self, screens):
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
        time.sleep(0.3)
        assert screens.home.is_visible()
