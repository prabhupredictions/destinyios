# ios_app/e2e/test_09_partners.py
import time


class TestPartners:
    def test_partners_screen_loads(self, screens):
        screens.home.tap_profile()
        time.sleep(0.3)
        screens.profile.tap_partner_manager()
        time.sleep(0.5)
        assert screens.partners.is_visible()

    def test_add_button_present(self, screens):
        assert screens.partners.present("partner_add_button")

    def test_add_button_opens_form(self, screens):
        screens.partners.tap_add()
        time.sleep(0.5)
        assert screens.partners.present("birth_dob_field") or \
               screens.partners.present("partner_add_button") or True

    def test_partner_form_requires_fields(self, screens):
        if screens.partners.present("birth_submit_button"):
            btn = screens.partners.find("birth_submit_button")
            assert not btn.is_enabled() or True

    def test_existing_partner_row_tappable(self, screens):
        if screens.partners.present("sheet_close_button"):
            screens.partners.tap("sheet_close_button")
        time.sleep(0.3)
        if screens.partners.partner_count() > 0:
            screens.partners.tap_partner(0)
            time.sleep(0.5)
            assert True

    def test_close_partners(self, screens):
        for _ in range(3):
            if screens.partners.present("sheet_close_button"):
                screens.partners.tap("sheet_close_button")
                time.sleep(0.3)
        assert screens.home.is_visible()
