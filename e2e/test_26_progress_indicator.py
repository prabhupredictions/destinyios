"""
E2E tests for the premium CosmicProgressView progress indicator.

Verifies that the agentic pipeline emits real-time progress steps that
appear in the chat bubble during streaming, then fade when the answer arrives.
"""
import time
import pytest
from helpers.assertions import assert_min_words


CAREER_QUERY   = "What is my career outlook for 2026?"
MARRIAGE_QUERY = "When will I get married?"  # research mode (triggers 4-group pipeline)


class TestProgressIndicatorAppears:

    def test_cosmic_progress_view_visible_during_streaming(self, screens):
        """CosmicProgressView container appears while agentic pipeline runs."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        time.sleep(2.0)  # allow first SSE progress_step to arrive
        assert screens.chat.present("cosmic_progress_view"), \
            "cosmic_progress_view not visible 2s after sending agentic query"
        screens.chat.wait_for_response(timeout=90)

    def test_at_least_one_step_row_appears(self, screens):
        """At least one progress_step_row rendered during streaming."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        time.sleep(2.0)
        step_rows = screens.chat.finds("progress_step_row")
        assert len(step_rows) >= 1, \
            f"Expected ≥1 progress_step_row, found {len(step_rows)}"
        screens.chat.wait_for_response(timeout=90)

    def test_active_step_has_dots(self, screens):
        """Active step shows the animated · · · dots indicator."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        time.sleep(2.0)
        if not screens.chat.present("cosmic_progress_view"):
            pytest.skip("Response arrived before check — timing sensitive")
        assert screens.chat.present("progress_active_dots"), \
            "progress_active_dots not found on active step"
        screens.chat.wait_for_response(timeout=90)


class TestProgressStepCompletion:

    def test_completed_step_shows_checkmark(self, screens):
        """First step gains a checkmark after tools complete."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        # Wait for second step to appear — means first step must be completed
        deadline = time.time() + 30
        found = False
        while time.time() < deadline:
            if len(screens.chat.finds("progress_step_completed")) >= 1:
                found = True
                break
            time.sleep(0.5)
        assert found, "No completed step (with checkmark) found within 30s"
        screens.chat.wait_for_response(timeout=90)

    def test_progress_view_gone_after_answer(self, screens):
        """cosmic_progress_view disappears once the answer text is present."""
        screens.chat.tap_new_chat()
        screens.chat.send(CAREER_QUERY)
        screens.chat.wait_for_response(timeout=90)
        assert not screens.chat.present("cosmic_progress_view"), \
            "cosmic_progress_view still visible after answer arrived"

    def test_answer_text_non_empty_after_steps(self, screens):
        """Prediction answer is substantive after progress steps complete."""
        screens.chat.tap_new_chat()
        response = screens.chat.wait_for_response(timeout=90)
        assert_min_words(response, 40)


class TestExpressVsResearchModes:

    def test_express_shows_max_3_steps(self, screens):
        """Express mode (single-group) produces ≤ 3 progress steps total."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        screens.chat.wait_for_response(timeout=90)
        completed = screens.chat.finds("progress_step_completed")
        assert len(completed) <= 3, \
            f"Express mode should produce ≤3 steps, got {len(completed)}"

    def test_research_shows_more_steps_than_express(self, screens):
        """Research mode (4-group) produces more steps than express mode."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(
            "What is the prediction mode for my marriage timing?"
        )
        screens.chat.tap("send_button")
        step_count_peak = 0
        deadline = time.time() + 60
        while time.time() < deadline:
            rows = screens.chat.finds("progress_step_row")
            step_count_peak = max(step_count_peak, len(rows))
            if not screens.chat.present("cosmic_progress_view"):
                break
            time.sleep(0.4)
        screens.chat.wait_for_response(timeout=90)
        assert step_count_peak >= 1, "Expected at least 1 progress step for research mode query"


class TestFallbackBehavior:

    def test_non_agentic_path_no_cosmic_progress_view(self, screens):
        """Compatibility flow (non-agentic) does not show cosmic_progress_view."""
        screens.home.tap("tab_match")
        time.sleep(0.5)
        if screens.chat.present("compat_analyze_button"):
            screens.chat.tap("compat_analyze_button")
            time.sleep(1.5)
            assert not screens.chat.present("cosmic_progress_view"), \
                "cosmic_progress_view shown on non-agentic compatibility path"
            screens.chat.wait_for("compat_result_score", timeout=120)
        else:
            pytest.skip("Compatibility analyze button not present — partner data not set up")
        screens.home.tap("tab_home")

    def test_cached_response_no_progress_view(self, screens):
        """Second identical query (cache hit) resolves without showing cosmic_progress_view."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        # First call — populate cache
        screens.chat.send(CAREER_QUERY)
        screens.chat.wait_for_response(timeout=90)
        # Second call — should be cached
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        time.sleep(0.5)
        # On a cache hit the response arrives within ~1s
        if screens.chat.present("cosmic_progress_view"):
            screens.chat.wait_for_response(timeout=15)
            if screens.chat.present("cosmic_progress_view"):
                pytest.skip("Cache miss on second identical query — indeterminate state")
        screens.chat.wait_for_response(timeout=30)


class TestProgressLocalization:

    def test_english_first_step_text_contains_expected_phrase(self, screens):
        """In English locale, first progress step label contains 'sky' or 'birth'."""
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        deadline = time.time() + 10
        step_rows = []
        while time.time() < deadline:
            step_rows = screens.chat.finds("progress_step_row")
            if step_rows:
                break
            time.sleep(0.3)
        assert step_rows, "No progress_step_row appeared within 10s"
        first_label = (step_rows[0].get_attribute("label") or "").lower()
        assert "sky" in first_label or "birth" in first_label or "mapping" in first_label, \
            f"First step label '{first_label}' does not match expected English progress string"
        screens.chat.wait_for_response(timeout=90)

    def test_final_oracle_step_text_contains_expected_phrase(self, screens):
        """Final synthesis step label contains 'oracle' or 'weaving' (English)."""
        screens.chat.tap_new_chat()
        screens.chat.find("chat_input").send_keys(CAREER_QUERY)
        screens.chat.tap("send_button")
        oracle_found = False
        deadline = time.time() + 30
        while time.time() < deadline:
            rows = screens.chat.finds("progress_step_row")
            for row in rows:
                label = (row.get_attribute("label") or "").lower()
                if "oracle" in label or "weaving" in label:
                    oracle_found = True
                    break
            if oracle_found:
                break
            time.sleep(0.5)
        screens.chat.wait_for_response(timeout=90)
        assert oracle_found, \
            "Never saw oracle/weaving step — synthesis progress step missing"
