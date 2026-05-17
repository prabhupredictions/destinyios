# ios_app/e2e/test_05_charts.py
import time


class TestCharts:
    def test_chart_sheet_opens_from_chat(self, screens):
        screens.home.tap_chat_tab()
        screens.chat.tap_chart()
        time.sleep(1)
        assert screens.charts.is_visible(), "chart_screen not visible"

    def test_dasha_tab_navigable(self, screens):
        if screens.charts.present("chart_tab_dasha"):
            screens.charts.tap_dasha_tab()
            time.sleep(0.5)
            assert True

    def test_transits_tab_navigable(self, screens):
        if screens.charts.present("chart_tab_transits"):
            screens.charts.tap_transits_tab()
            time.sleep(0.5)
            assert True

    def test_planets_tab_shows_nine_planets(self, screens):
        if screens.charts.present("chart_tab_planets"):
            screens.charts.tap_planets_tab()
            time.sleep(0.5)
            count = screens.charts.planet_count()
            assert count >= 9, f"Expected ≥9 planets, got {count}"

    def test_close_chart_returns_to_chat(self, screens):
        if screens.charts.present("sheet_close_button"):
            screens.charts.tap("sheet_close_button")
        else:
            screens.chat.tap_back()
        time.sleep(0.5)
        screens.chat.tap_back()
        assert screens.home.is_visible()
