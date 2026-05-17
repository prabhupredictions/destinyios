# ios_app/e2e/conftest.py
import os
import pytest
from appium import webdriver
from appium.options.ios import XCUITestOptions

TEST_ENV = os.environ.get("TEST_ENV", "local")  # local (default, 99%) or staging (non-reproducible bugs only)
BASE_URLS = {
    "local":   "http://127.0.0.1:8000",
    "staging": "https://astroapi-test-dsqvza5jza-ul.a.run.app",
}
E2E_EMAIL = "prabhukushwaha@gmail.com"
BIRTH = {
    "dob":       "1980-07-01",
    "time":      "06:32",
    "latitude":  "21.2138",
    "longitude": "81.3943",
    "city":      "Bhilai",
}
# Compatibility partner (Smita) — used by test_27_compat_ask_destiny.py
PARTNER = {
    "name":      "Smita",
    "dob":       "1980-11-13",
    "time":      "09:30",
    "city":      "Belgaum, Karnataka",
    "latitude":  "15.8497",
    "longitude": "74.4977",
}


@pytest.fixture(scope="session")
def driver():
    opts = XCUITestOptions()
    opts.platform_name    = "iOS"
    opts.platform_version = "18"
    opts.device_name      = "iPhone 17 Pro"
    opts.udid             = "2CD3AEF0-03BC-41DF-82F1-4A2DFFF6A095"
    opts.bundle_id        = "com.destinyai.astrology"
    opts.automation_name  = "XCUITest"
    opts.no_reset         = False
    opts.process_arguments = {
        "args": ["UI_TEST_MODE"],
        "env": {
            "E2E_USER_EMAIL":    E2E_EMAIL,
            "API_BASE_URL":      BASE_URLS[TEST_ENV],
            "E2E_DOB":           BIRTH["dob"],
            "E2E_TIME":          BIRTH["time"],
            "E2E_LATITUDE":      BIRTH["latitude"],
            "E2E_LONGITUDE":     BIRTH["longitude"],
            "E2E_CITY":          BIRTH["city"],
            "E2E_PARTNER_NAME":  PARTNER["name"],
            "E2E_PARTNER_DOB":   PARTNER["dob"],
            "E2E_PARTNER_TIME":  PARTNER["time"],
            "E2E_PARTNER_CITY":  PARTNER["city"],
            "E2E_PARTNER_LAT":   PARTNER["latitude"],
            "E2E_PARTNER_LON":   PARTNER["longitude"],
        },
    }
    drv = webdriver.Remote("http://127.0.0.1:4723", options=opts)
    drv.implicitly_wait(15)
    yield drv
    drv.quit()


@pytest.fixture(scope="session")
def screens(driver):
    from helpers.screens import (
        HomeScreen, ChatScreen, CompatibilityScreen, ChartsScreen,
        HistoryScreen, ProfileScreen, PartnersScreen, SubscriptionScreen,
        NotificationsScreen, OnboardingScreen, AskDestinyScreen,
    )

    class _Screens:
        home         = HomeScreen(driver)
        chat         = ChatScreen(driver)
        compat       = CompatibilityScreen(driver)
        ask_destiny  = AskDestinyScreen(driver)
        charts       = ChartsScreen(driver)
        history      = HistoryScreen(driver)
        profile      = ProfileScreen(driver)
        partners     = PartnersScreen(driver)
        subscription = SubscriptionScreen(driver)
        notifs       = NotificationsScreen(driver)
        onboarding   = OnboardingScreen(driver)

    return _Screens()
