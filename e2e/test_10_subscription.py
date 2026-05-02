# ios_app/e2e/test_10_subscription.py
import time


class TestSubscription:
    def test_subscription_screen_loads(self, screens):
        screens.home.tap_profile()
        time.sleep(0.3)
        screens.profile.tap_subscription()
        time.sleep(0.5)
        assert screens.subscription.is_visible()

    def test_plan_cards_visible(self, screens):
        count = screens.subscription.plan_count()
        assert count >= 1, f"Expected ≥1 plan cards, got {count}"

    def test_close_subscription(self, screens):
        if screens.subscription.present("sheet_close_button"):
            screens.subscription.tap("sheet_close_button")
        if screens.profile.present("sheet_close_button"):
            screens.profile.tap("sheet_close_button")
        time.sleep(0.3)
        assert screens.home.is_visible()
