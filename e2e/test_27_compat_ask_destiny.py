# ios_app/e2e/test_27_compat_ask_destiny.py
"""
E2E tests for AskDestinySheet in compatibility result.

Covers both backend paths:
  Agentic  — direct compatibility question → POST /follow-up (non-streaming)
             → CosmicProgressView cycles → typewriter-reveal answer
  Sub_agent — question about individual person triggers redirect
             → StreamingPredictionService SSE → streamed answer in redirect bubble

Test data: Prabhu (1980-07-01, 06:32, Bhilai) & Smita (1980-11-13, 09:30, Belgaum)
Partner is injected via E2E_PARTNER_* env vars (see conftest.py + CompatibilityView.swift).
"""
import time
import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _navigate_to_result(screens):
    """Navigate to the Compatibility tab and wait for a result score to appear.
    Assumes partner data is pre-injected via E2E env vars and Analyze is enabled.
    """
    screens.home.tap_match_tab()
    assert screens.compat.is_visible(), "Compatibility screen not found"

    if not screens.compat.present("compat_result_score"):
        assert screens.compat.is_analyze_enabled(), \
            "Analyze button disabled — E2E partner env vars may not have been injected"
        screens.compat.tap_analyze()
        screens.compat.wait_for_result(timeout=180)

    assert screens.compat.present("compat_result_score"), \
        "Compatibility result score not visible after analysis"


def _open_ask_destiny(screens):
    """Tap the floating 'Ask me' bubble and wait for the sheet."""
    screens.compat.tap("ask_destiny_button")
    screens.ask_destiny.wait_for("ask_destiny_sheet", timeout=10)
    assert screens.ask_destiny.is_visible(), "AskDestinySheet did not open"


# ---------------------------------------------------------------------------
# Agentic path — direct compatibility question
# ---------------------------------------------------------------------------

class TestCompatAskDestinyAgentic:
    """Ask a direct compatibility question (no individual-person redirect)."""

    def test_sheet_opens(self, screens):
        _navigate_to_result(screens)
        _open_ask_destiny(screens)

    def test_cosmic_progress_appears_during_loading(self, screens):
        """After sending a compatibility question, cosmic progress should cycle
        before the answer arrives."""
        screens.ask_destiny.send("What is the overall compatibility score between us?")
        appeared = screens.ask_destiny.wait_for_cosmic_progress(timeout=20)
        assert appeared, "cosmic_progress_view never appeared for agentic loading"

    def test_agentic_response_arrives(self, screens):
        """Wait for the AI answer to appear (cosmic progress gone, message visible)."""
        answer = screens.ask_destiny.wait_for_ai_response(timeout=120)
        assert len(answer) > 20, f"AI response too short or empty: {answer!r}"

    def test_followup_suggestions_appear(self, screens):
        """FollowUpSuggestionsView rows appear after the typewriter finishes."""
        # Give typewriter time to finish (answer is being revealed word-by-word)
        time.sleep(5)
        assert screens.ask_destiny.has_followup_suggestions(), \
            "No follow-up suggestion rows found after agentic answer"


# ---------------------------------------------------------------------------
# Follow-up path — tap a suggestion row
# ---------------------------------------------------------------------------

class TestCompatAskDestinyFollowUp:
    """Tap the first follow-up suggestion and verify a second AI response."""

    def test_tap_followup_sends_second_question(self, screens):
        # Ensure the sheet is still open with suggestions from prior class
        if not screens.ask_destiny.is_visible():
            _navigate_to_result(screens)
            _open_ask_destiny(screens)
            # Trigger agentic answer to get suggestions
            screens.ask_destiny.send("What is the overall compatibility score between us?")
            screens.ask_destiny.wait_for_ai_response(timeout=120)
            time.sleep(5)

        count_before = screens.ask_destiny.ai_message_count()
        screens.ask_destiny.tap_followup(0)

        # Wait for second answer
        answer = screens.ask_destiny.wait_for_ai_response(timeout=120)
        count_after = screens.ask_destiny.ai_message_count()

        assert count_after > count_before, \
            "No new AI message after tapping follow-up suggestion"
        assert len(answer) > 20, f"Second AI response too short: {answer!r}"

    def test_dismiss_sheet(self, screens):
        screens.ask_destiny.dismiss()
        time.sleep(1)
        assert not screens.ask_destiny.is_visible(), \
            "AskDestinySheet still visible after dismiss"


# ---------------------------------------------------------------------------
# Sub_agent path — question about individual person triggers redirect
# ---------------------------------------------------------------------------

class TestCompatAskDestinySubAgent:
    """Ask about a specific person's chart to trigger the redirect → SSE streaming path."""

    def test_setup_result(self, screens):
        _navigate_to_result(screens)

    def test_open_sheet_for_subagent(self, screens):
        _open_ask_destiny(screens)

    def test_redirect_cosmic_progress_in_bubble(self, screens):
        """Ask about Smita's career outlook — backend redirects to individual chart.
        The redirect bubble should show CosmicProgressView during SSE streaming."""
        screens.ask_destiny.send("What is Smita's career outlook based on her chart?")
        appeared = screens.ask_destiny.wait_for_cosmic_progress(timeout=20)
        assert appeared, \
            "cosmic_progress_view never appeared in redirect bubble (sub_agent path)"

    def test_subagent_streamed_answer_arrives(self, screens):
        """Full SSE stream completes — redirect bubble replaced by typewriter-revealed answer."""
        answer = screens.ask_destiny.wait_for_ai_response(timeout=180)
        assert len(answer) > 20, f"Sub_agent streamed answer too short: {answer!r}"
        # The answer should mention Smita or individual analysis
        low = answer.lower()
        assert "smita" in low or "individual" in low or "career" in low, \
            f"Answer doesn't seem related to Smita's individual chart: {answer[:200]!r}"

    def test_subagent_followup_suggestions(self, screens):
        """Follow-up suggestions should appear after sub_agent streamed answer."""
        time.sleep(5)
        assert screens.ask_destiny.has_followup_suggestions(), \
            "No follow-up suggestions after sub_agent answer"

    def test_dismiss_sheet_after_subagent(self, screens):
        screens.ask_destiny.dismiss()
        time.sleep(1)
        assert not screens.ask_destiny.is_visible(), \
            "AskDestinySheet still visible after sub_agent dismiss"
