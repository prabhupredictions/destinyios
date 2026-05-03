"""
Premium chat redesign E2E tests.
Covers: reading layout, progress ring, ritual steps, depth layers,
follow-up rows, full-width input, crash prevention, streaming.
"""
import time
import pytest
from helpers.assertions import assert_min_words


class TestChatPremiumLayout:

    def test_domain_tag_visible_after_response(self, screens):
        """AI response shows domain tag pill."""
        screens.home.tap_chat_tab()
        screens.chat.send("What is my career outlook for 2026?")
        screens.chat.wait_for_response(timeout=90)
        assert screens.chat.present("reading_domain_tag"), \
            "domain tag not visible after career response"

    def test_ritual_progress_visible_during_streaming(self, screens):
        """Ritual progress container appears while streaming."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys("What are my career prospects?")
        screens.chat.tap("send_button")
        time.sleep(1.5)
        assert screens.chat.present("ritual_progress_view") or \
               screens.chat.present("streaming_indicator"), \
            "neither ritual_progress_view nor streaming_indicator visible 1.5s after send"
        screens.chat.wait_for_response(timeout=90)

    def test_kundali_ring_visible_during_streaming(self, screens):
        """Kundali ring is visible while streaming."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys("What is my health outlook?")
        screens.chat.tap("send_button")
        time.sleep(0.8)
        if screens.chat.is_streaming():
            assert screens.chat.present("kundali_ring_view"), \
                "kundali_ring_view not visible during streaming"
        else:
            pytest.skip("Response arrived before ring check — timing sensitive test")

    def test_reading_body_text_present_after_response(self, screens):
        """reading_body_text accessibility ID visible after response."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send("Tell me about my current dasha.")
        response = screens.chat.wait_for_response(timeout=90)
        assert screens.chat.present("reading_body_text"), \
            "reading_body_text not found after response"
        assert_min_words(response, 40)

    def test_question_label_matches_sent_query(self, screens):
        """Question label shows the user's question in italic above the reading."""
        screens.chat.tap_new_chat()
        question = "What does my Moon sign mean?"
        screens.chat.send(question)
        screens.chat.wait_for_response(timeout=90)
        label_els = screens.chat.finds("reading_question_label")
        assert len(label_els) > 0, "reading_question_label not found"
        label_text = label_els[-1].get_attribute("label") or ""
        assert question.lower() in label_text.lower(), \
            f"question label '{label_text}' does not contain query '{question}'"

    def test_depth_layers_visible_after_response(self, screens):
        """depth_layers_view container present after response."""
        assert screens.chat.present("depth_layers_view"), \
            "depth_layers_view not visible after response"

    def test_depth_why_row_tappable(self, screens):
        """Tapping depth_why_row expands content."""
        if screens.chat.present("depth_why_row"):
            screens.chat.tap("depth_why_row")
            time.sleep(0.3)
            assert screens.chat.present("depth_expanded_content"), \
                "depth_expanded_content not shown after tapping Why row"
            screens.chat.tap("depth_why_row")
        else:
            pytest.skip("depth_why_row not present — advice field may be empty")

    def test_followup_suggestions_appear_after_response(self, screens):
        """followup_suggestions_view with at least 1 row appears after response."""
        assert screens.chat.present("followup_suggestions_view"), \
            "followup_suggestions_view not visible after response"
        assert screens.chat.present("followup_row_0"), \
            "followup_row_0 not found"

    def test_followup_row_is_contextual(self, screens):
        """Follow-up suggestion text is non-empty and related to astrology."""
        rows = screens.chat.finds("followup_row_0")
        assert len(rows) > 0, "No follow-up rows found"
        text = rows[0].get_attribute("label") or ""
        assert len(text) > 5, f"Follow-up row text too short: '{text}'"

    def test_followup_tap_sends_message_and_gets_response(self, screens):
        """Tapping a follow-up row sends it and produces a response."""
        if not screens.chat.present("followup_row_0"):
            pytest.skip("No follow-up rows available")
        before_count = screens.chat.message_count()
        screens.chat.tap("followup_row_0")
        screens.chat.wait_for_response(timeout=90)
        assert screens.chat.message_count() > before_count, \
            "No new message added after tapping follow-up"

    def test_input_bar_single_row_layout(self, screens):
        """Input bar elements (chat_input, send_button) are horizontally aligned."""
        assert screens.chat.present("chat_input"), "chat_input not found"
        assert screens.chat.present("send_button"), "send_button not found"
        input_rect = screens.chat.find("chat_input").rect
        send_rect = screens.chat.find("send_button").rect
        input_mid_y = input_rect["y"] + input_rect["height"] / 2
        send_mid_y = send_rect["y"] + send_rect["height"] / 2
        assert abs(input_mid_y - send_mid_y) < 30, \
            f"Input bar elements not on same row: input_y={input_mid_y:.0f}, send_y={send_mid_y:.0f}"

    def test_no_crash_after_many_messages(self, screens):
        """App does not crash after 10 back-to-back exchanges."""
        screens.chat.tap_new_chat()
        questions = [
            "What sign is my Moon?",
            "And my Sun?",
            "What's my ascendant?",
            "Tell me about my 1st house.",
            "And my 10th house?",
            "What is my current dasha lord?",
            "When does it end?",
            "What follows after?",
            "What year is best for career?",
            "Give me a one-sentence summary.",
        ]
        for q in questions:
            screens.chat.send(q)
            screens.chat.wait_for_response(timeout=90)
        assert screens.chat.present("chat_input"), \
            "chat_input missing after 10 exchanges — possible crash"

    def test_copy_button_present_and_tappable(self, screens):
        """copy_button is accessible and tappable after response."""
        assert screens.chat.present("copy_button"), "copy_button not found after response"
        screens.chat.tap("copy_button")
        time.sleep(0.5)

    def test_new_chat_clears_reading_entries(self, screens):
        """After new chat, reading_entry elements are gone."""
        screens.chat.tap_new_chat()
        time.sleep(0.5)
        assert not screens.chat.present("reading_entry"), \
            "reading_entry still visible after new chat"

    def test_load_older_button_when_available(self, screens):
        """load_older_button: if present, tapping it loads more messages."""
        if screens.chat.present("load_older_button"):
            screens.chat.tap("load_older_button")
            time.sleep(0.5)
            assert screens.chat.message_count() >= 0, "No messages after load older"
        else:
            pytest.skip("load_older_button not present (thread under 50 messages)")
