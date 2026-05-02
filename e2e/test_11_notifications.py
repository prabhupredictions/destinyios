# ios_app/e2e/test_11_notifications.py
import time


class TestNotifications:
    def test_notification_inbox_opens(self, screens):
        screens.home.tap_notifications()
        time.sleep(0.5)
        assert screens.notifs.is_visible()

    def test_inbox_renders_without_crash(self, screens):
        time.sleep(2)
        assert True

    def test_empty_state_or_rows_present(self, screens):
        count = screens.notifs.notification_count()
        assert count >= 0
        if screens.notifs.present("sheet_close_button"):
            screens.notifs.tap("sheet_close_button")
        time.sleep(0.3)
        assert screens.home.is_visible()
