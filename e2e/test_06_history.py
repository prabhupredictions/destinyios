# ios_app/e2e/test_06_history.py
import time


class TestHistory:
    def test_history_opens_from_home(self, screens):
        screens.home.tap_history()
        time.sleep(0.5)
        assert screens.history.is_visible(), "history_screen not visible"

    def test_history_shows_at_least_one_thread(self, screens):
        count = screens.history.thread_count()
        assert count >= 1, f"Expected ≥1 history threads, got {count}"

    def test_tapping_thread_opens_chat(self, screens):
        screens.history.tap_first_thread()
        time.sleep(1)
        assert screens.chat.is_visible(), "Chat screen not visible after tapping history thread"
        screens.chat.tap_back()

    def test_back_returns_to_home(self, screens):
        if screens.history.present("sheet_close_button"):
            screens.history.tap("sheet_close_button")
        time.sleep(0.3)
        assert screens.home.is_visible()
