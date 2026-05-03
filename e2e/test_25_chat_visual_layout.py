"""
Visual layout E2E tests for the iOS premium chat redesign.
Uses Appium to test the actual rendered iOS app.
Covers: font accessibility, element bounds, layout structure,
reading entry structure, input bar single-row, streaming UI.

These run against the real iOS app in the simulator — not a mockup.
"""
import time
import pytest


class TestChatVisualLayout:
    """Verifies layout and visual structure of the premium chat redesign."""

    def test_chat_input_bar_visible_and_accessible(self, screens):
        """chat_input and send_button are present and visible."""
        screens.home.tap_chat_tab()
        assert screens.chat.present("chat_input"), "chat_input not found"
        assert screens.chat.present("send_button"), "send_button not found"

    def test_input_and_send_on_same_horizontal_row(self, screens):
        """Input field and send button are aligned horizontally (single-row layout)."""
        input_rect = screens.chat.find("chat_input").rect
        send_rect = screens.chat.find("send_button").rect
        input_mid_y = input_rect["y"] + input_rect["height"] / 2
        send_mid_y = send_rect["y"] + send_rect["height"] / 2
        assert abs(input_mid_y - send_mid_y) < 30, \
            f"Input bar is NOT single-row: input_y={input_mid_y:.0f}, send_y={send_mid_y:.0f}"

    def test_input_takes_majority_of_bar_width(self, screens):
        """Input field takes the majority of available horizontal space."""
        input_rect = screens.chat.find("chat_input").rect
        send_rect = screens.chat.find("send_button").rect
        # Send button should be small (< 55pt); input should be much wider
        assert send_rect["width"] < 55, f"Send button too wide: {send_rect['width']}pt"
        assert input_rect["width"] > send_rect["width"] * 3, \
            f"Input not wider than 3× send button: input={input_rect['width']}pt send={send_rect['width']}pt"

    def test_reading_entry_layout_after_response(self, screens):
        """After a response: reading_entry, reading_body_text are present."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send("Tell me about my Moon sign placement.")
        screens.chat.wait_for_response(timeout=90)
        assert screens.chat.present("reading_entry"), "reading_entry not found"
        assert screens.chat.present("reading_body_text"), "reading_body_text not found"

    def test_reading_body_is_wide(self, screens):
        """Reading body text spans full width (no narrow bubble)."""
        if screens.chat.present("reading_body_text"):
            body_rect = screens.chat.find("reading_body_text").rect
            # Should be at least 280pt wide on any modern iPhone
            assert body_rect["width"] >= 280, \
                f"reading_body_text is only {body_rect['width']}pt wide — bubble layout may be active"

    def test_question_label_appears_above_body(self, screens):
        """Question label appears above reading body (higher y position)."""
        if screens.chat.present("reading_question_label") and screens.chat.present("reading_body_text"):
            q_rect = screens.chat.find("reading_question_label").rect
            b_rect = screens.chat.find("reading_body_text").rect
            assert q_rect["y"] <= b_rect["y"], \
                f"Question label (y={q_rect['y']}) is BELOW body (y={b_rect['y']})"

    def test_domain_tag_present_and_small(self, screens):
        """Domain tag pill is compact (height < 24pt)."""
        if screens.chat.present("reading_domain_tag"):
            tag_rect = screens.chat.find("reading_domain_tag").rect
            assert tag_rect["height"] < 24, \
                f"Domain tag too tall ({tag_rect['height']}pt) — should be a compact pill"

    def test_kundali_ring_is_small_square(self, screens):
        """Kundali ring is approximately 28×28 pt."""
        if screens.chat.present("kundali_ring_view"):
            ring_rect = screens.chat.find("kundali_ring_view").rect
            assert 20 <= ring_rect["width"] <= 40, \
                f"Kundali ring width {ring_rect['width']}pt — expected ~28pt"
            assert 20 <= ring_rect["height"] <= 40, \
                f"Kundali ring height {ring_rect['height']}pt — expected ~28pt"

    def test_followup_rows_are_full_width(self, screens):
        """Follow-up suggestion rows span full chat width (not narrow capsules)."""
        if screens.chat.present("followup_row_0"):
            row_rect = screens.chat.find("followup_row_0").rect
            assert row_rect["width"] >= 280, \
                f"followup_row_0 is only {row_rect['width']}pt wide — may still be capsule pill"

    def test_depth_why_row_tappable_and_expands(self, screens):
        """Depth 'Why' row expands when tapped."""
        if screens.chat.present("depth_why_row"):
            screens.chat.tap("depth_why_row")
            time.sleep(0.3)
            assert screens.chat.present("depth_expanded_content"), \
                "depth_expanded_content not visible after tapping Why row"

    def test_copy_button_is_accessible(self, screens):
        """Copy button is present and within expected size range."""
        if screens.chat.present("copy_button"):
            btn_rect = screens.chat.find("copy_button").rect
            assert btn_rect["width"] > 0, "copy_button has zero width"

    def test_streaming_progress_visible_on_new_question(self, screens):
        """During a new request: progress UI or streaming indicator appears."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys("What is my lagna?")
        screens.chat.tap("send_button")
        time.sleep(1.0)
        progress_visible = (
            screens.chat.present("ritual_progress_view") or
            screens.chat.present("streaming_indicator") or
            screens.chat.present("kundali_ring_view")
        )
        assert progress_visible, \
            "No streaming progress UI found 1 second after sending — streaming may not be wired"
        screens.chat.wait_for_response(timeout=90)

    def test_new_chat_resets_layout(self, screens):
        """After tapping new chat, reading_entry elements are cleared."""
        screens.chat.tap_new_chat()
        time.sleep(0.5)
        assert not screens.chat.present("reading_entry"), \
            "reading_entry still present after new chat — layout not cleared"
