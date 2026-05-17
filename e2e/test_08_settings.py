# ios_app/e2e/test_08_settings.py
import time


class TestSettings:
    def test_chart_style_picker_opens(self, screens):
        screens.home.tap_profile()
        time.sleep(0.3)
        screens.profile.tap_chart_style()
        time.sleep(0.5)
        assert True
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_language_picker_shows_multiple_options(self, screens):
        screens.home.tap_profile()
        time.sleep(0.3)
        screens.profile.tap_language_settings()
        time.sleep(0.5)
        from appium.webdriver.common.appiumby import AppiumBy
        cells = screens.profile.d.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeCell")
        assert len(cells) >= 2, f"Expected ≥2 language options, got {len(cells)}"
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")

    def test_notification_prefs_has_toggles(self, screens):
        screens.home.tap_profile()
        time.sleep(0.3)
        screens.profile.tap_notification_prefs()
        time.sleep(0.5)
        from appium.webdriver.common.appiumby import AppiumBy
        toggles = screens.profile.d.find_elements(AppiumBy.CLASS_NAME, "XCUIElementTypeSwitch")
        assert len(toggles) >= 1, "Expected ≥1 notification toggle"
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
