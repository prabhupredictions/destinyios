# ios_app/e2e/helpers/screens.py
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


class _Base:
    def __init__(self, driver):
        self.d = driver
        self._wait = WebDriverWait(driver, 20)

    def find(self, aid):
        return self.d.find_element(AppiumBy.ACCESSIBILITY_ID, aid)

    def finds(self, aid):
        return self.d.find_elements(AppiumBy.ACCESSIBILITY_ID, aid)

    def tap(self, aid):
        self.find(aid).click()

    def present(self, aid) -> bool:
        return len(self.finds(aid)) > 0

    def save_screenshot(self, name: str):
        import os
        os.makedirs("ios_app/e2e/screenshots", exist_ok=True)
        self.d.save_screenshot(f"ios_app/e2e/screenshots/{name}.png")

    def wait_for(self, aid, timeout=20):
        self._wait.until(EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, aid)))

    def wait_gone(self, aid, timeout=90):
        WebDriverWait(self.d, timeout).until_not(
            EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, aid))
        )


class HomeScreen(_Base):
    def is_visible(self): return self.present("home_screen")
    def tap_chat_tab(self):         self.tap("tab_chat")
    def tap_match_tab(self):        self.tap("tab_match")
    def tap_profile(self):          self.tap("home_profile_button")
    def tap_history(self):          self.tap("home_history_button")
    def tap_notifications(self):    self.tap("home_notifications_button")
    def tap_life_area(self, area):  self.tap(f"life_area_{area}")
    def tap_yoga_card(self):        self.tap("yoga_highlight_card")
    def tap_dasha_card(self):       self.tap("dasha_insight_card")
    def tap_transit_alert(self):    self.tap("transit_alert_card")
    def dasha_card_text(self):      return self.find("dasha_insight_card").get_attribute("label")


class ChatScreen(_Base):
    def is_visible(self): return self.present("chat_input")

    def send(self, text: str):
        field = self.find("chat_input")
        field.clear()
        field.send_keys(text)
        self.tap("send_button")

    def wait_for_response(self, timeout=90) -> str:
        self.wait_gone("streaming_indicator", timeout=timeout)
        msgs = self.finds("ai_message")
        return msgs[-1].get_attribute("label") if msgs else ""

    def is_streaming(self):     return self.present("streaming_indicator")
    def message_count(self):    return len(self.finds("ai_message"))
    def tap_copy(self):         self.tap("copy_button")
    def tap_new_chat(self):     self.tap("new_chat_button")
    def tap_history(self):      self.tap("chat_history_button")
    def tap_chart(self):        self.tap("chat_chart_button")
    def tap_back(self):         self.tap("chat_back_button")


class CompatibilityScreen(_Base):
    def is_visible(self):           return self.present("compat_screen")
    def tap_analyze(self):          self.tap("compat_analyze_button")
    def tap_history(self):          self.tap("compat_history_button")
    def is_analyze_enabled(self):   return self.find("compat_analyze_button").is_enabled()
    def tap_dob_person2(self):      self.tap("compat_person2_dob")
    def result_score(self):         return self.find("compat_result_score").get_attribute("label")
    def tap_mangal_dosha(self):     self.tap("mangal_dosha_row")
    def tap_kalsarpa_dosha(self):   self.tap("kalsarpa_dosha_row")

    def wait_for_result(self, timeout=120):
        self.wait_for("compat_result_score", timeout=timeout)


class ChartsScreen(_Base):
    def is_visible(self):           return self.present("chart_screen")
    def tap_dasha_tab(self):        self.tap("chart_tab_dasha")
    def tap_transits_tab(self):     self.tap("chart_tab_transits")
    def tap_planets_tab(self):      self.tap("chart_tab_planets")
    def planet_count(self):         return len(self.finds("planet_position_row"))


class HistoryScreen(_Base):
    def is_visible(self):           return self.present("history_screen")
    def thread_count(self):         return len(self.finds("history_thread_row"))
    def tap_first_thread(self):
        rows = self.finds("history_thread_row")
        if rows:
            rows[0].click()


class ProfileScreen(_Base):
    def is_visible(self):                   return self.present("profile_screen")
    def tap_birth_details(self):            self.tap("profile_birth_details")
    def tap_language_settings(self):        self.tap("profile_language_settings")
    def tap_astrology_settings(self):       self.tap("profile_astrology_settings")
    def tap_chart_style(self):              self.tap("profile_chart_style")
    def tap_response_style(self):           self.tap("profile_response_style")
    def tap_notification_prefs(self):       self.tap("profile_notification_prefs")
    def tap_partner_manager(self):          self.tap("profile_partner_manager")
    def tap_subscription(self):             self.tap("profile_subscription")


class PartnersScreen(_Base):
    def is_visible(self):           return self.present("partners_screen")
    def partner_count(self):        return len(self.finds("partner_row"))
    def tap_add(self):              self.tap("partner_add_button")
    def tap_partner(self, index=0):
        rows = self.finds("partner_row")
        if rows:
            rows[index].click()


class SubscriptionScreen(_Base):
    def is_visible(self):           return self.present("subscription_screen")
    def plan_count(self):           return len(self.finds("subscription_plan_card"))


class NotificationsScreen(_Base):
    def is_visible(self):               return self.present("notifications_screen")
    def notification_count(self):       return len(self.finds("notification_row"))


class OnboardingScreen(_Base):
    def is_visible(self):       return self.present("onboarding_screen")
    def tap_continue(self):     self.tap("onboarding_continue")
    def tap_submit(self):       self.tap("birth_submit_button")

    def enter_birth_data(self, dob: str, time: str, city: str):
        self.find("birth_dob_field").send_keys(dob)
        self.find("birth_time_field").send_keys(time)
        self.find("birth_city_field").send_keys(city)


class AskDestinyScreen(_Base):
    """Page object for AskDestinySheet (floating chat in compatibility result)."""

    def is_visible(self) -> bool:
        return self.present("ask_destiny_sheet")

    def send(self, text: str):
        """Type a message and tap send."""
        field = self.find("compat_chat_input")
        field.clear()
        field.send_keys(text)
        self.tap("compat_send_button")

    def wait_for_ai_response(self, timeout=120) -> str:
        """Wait until at least one compat_ai_message is present; return its label."""
        WebDriverWait(self.d, timeout).until(
            EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "compat_ai_message"))
        )
        msgs = self.finds("compat_ai_message")
        return msgs[-1].get_attribute("label") if msgs else ""

    def ai_message_count(self) -> int:
        return len(self.finds("compat_ai_message"))

    def is_cosmic_progress_visible(self) -> bool:
        return self.present("cosmic_progress_view")

    def wait_for_cosmic_progress(self, timeout=15) -> bool:
        """Return True if cosmic progress appears within timeout."""
        try:
            WebDriverWait(self.d, timeout).until(
                EC.presence_of_element_located((AppiumBy.ACCESSIBILITY_ID, "cosmic_progress_view"))
            )
            return True
        except Exception:
            return False

    def tap_followup(self, index: int = 0):
        """Tap the Nth follow-up suggestion pill."""
        self.tap(f"followup_row_{index}")

    def has_followup_suggestions(self) -> bool:
        return self.present("followup_row_0")

    def dismiss(self):
        """Tap the Done button to close the sheet."""
        # Find button labelled "Done" (localized via done_action key)
        try:
            btn = self.d.find_element(AppiumBy.ACCESSIBILITY_ID, "done_action")
            btn.click()
        except Exception:
            # Fallback: swipe down
            self.d.execute_script("mobile: swipe", {"direction": "down"})

