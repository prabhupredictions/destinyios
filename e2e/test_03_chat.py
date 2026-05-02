# ios_app/e2e/test_03_chat.py
import time
import pytest
from helpers.assertions import assert_min_words


class TestChat:
    def test_chat_screen_loads(self, screens):
        screens.home.tap_chat_tab()
        assert screens.chat.is_visible(), "chat_input not found on chat screen"

    def test_input_bar_accepts_text(self, screens, driver):
        field = screens.chat.find("chat_input")
        field.send_keys("Test input")
        assert field.get_attribute("value") is not None
        field.clear()

    def test_send_triggers_streaming_indicator(self, screens):
        screens.chat.send("What is my current dasha period?")
        time.sleep(2)
        assert screens.chat.is_streaming(), "streaming_indicator not visible after sending"

    def test_streaming_resolves_with_response(self, screens):
        response = screens.chat.wait_for_response(timeout=90)
        assert len(response) > 0, "No response text found after streaming"

    def test_response_has_minimum_words(self, screens):
        screens.chat.tap_new_chat()
        screens.chat.send("What does my birth chart say about my personality?")
        response = screens.chat.wait_for_response(timeout=90)
        assert_min_words(response, 50)

    def test_copy_button_visible_after_response(self, screens):
        assert screens.chat.present("copy_button"), "copy_button not visible after response"

    def test_copy_button_tappable(self, screens):
        screens.chat.tap_copy()
        time.sleep(1.5)

    def test_new_chat_clears_messages(self, screens):
        screens.chat.tap_new_chat()
        time.sleep(0.5)
        assert screens.chat.message_count() == 0, "Messages not cleared after new chat"

    def test_chart_button_opens_chart_sheet(self, screens):
        screens.chat.tap_chart()
        time.sleep(1)
        assert screens.charts.is_visible() or screens.chat.present("chart_screen"), \
            "Chart sheet did not open"
        if screens.chat.present("sheet_close_button"):
            screens.chat.find("sheet_close_button").click()

    def test_history_button_opens_history(self, screens):
        screens.chat.tap_history()
        time.sleep(1)
        assert screens.history.is_visible(), "History sheet did not open"
        if screens.history.present("sheet_close_button"):
            screens.history.find("sheet_close_button").click()

    def test_back_button_returns_to_home(self, screens):
        screens.chat.tap_back()
        time.sleep(0.5)
        assert screens.home.is_visible(), "Home screen not visible after chat back button"

    def test_second_message_in_thread(self, screens):
        screens.home.tap_chat_tab()
        screens.chat.send("What is my moon sign?")
        screens.chat.wait_for_response(timeout=90)
        count_after_first = screens.chat.message_count()
        screens.chat.send("And what does that mean for relationships?")
        screens.chat.wait_for_response(timeout=90)
        assert screens.chat.message_count() > count_after_first, "Second message not appended"
        screens.chat.tap_new_chat()
        screens.chat.tap_back()
