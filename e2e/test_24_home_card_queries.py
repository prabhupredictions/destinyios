# ios_app/e2e/test_24_home_card_queries.py
"""
End-to-end tests for home card query → chat flow.

Covers every interactive card on the Home screen:
  - Life area orbs (career, finance, health, family, relationship, education)
  - Dasha insight card
  - Transit cards (Sun, Jupiter)
  - Yoga / Dosha card (popup → Ask More)
  - "What's in My Mind" questions

For each card the test verifies:
  1. Navigation to chat tab happens automatically
  2. A non-empty AI response is produced
  3. The response is not the guardrail block message
  4. The user bubble shows the SHORT label, not the raw technical query
"""

import time
import pytest
from helpers.assertions import assert_min_words


# ── helpers ──────────────────────────────────────────────────────────────────

def _tap_and_wait_response(screens, tap_fn, timeout=90):
    """Tap something on home, wait for chat to appear, return the AI response."""
    tap_fn()
    time.sleep(1)
    # Chat tab should become active automatically
    screens.chat.wait_for("chat_input", timeout=10)
    response = screens.chat.wait_for_response(timeout=timeout)
    screens.chat.tap_new_chat()
    screens.home.tap("tab_home")
    time.sleep(0.5)
    return response


def _user_bubble_label(screens):
    """Return the text label of the first user message bubble."""
    bubbles = screens.chat.finds("user_message")
    if not bubbles:
        return ""
    return bubbles[0].get_attribute("label") or ""


def _assert_response_ok(response: str, label: str):
    assert len(response) > 0, f"[{label}] Empty response from LLM"
    assert "i'm sorry, but i can't provide" not in response.lower(), \
        f"[{label}] Response was blocked by guardrail: {response[:200]}"
    assert_min_words(response, 30)


# ── life area orbs ────────────────────────────────────────────────────────────

class TestLifeAreaOrbs:
    """Tap each life-area orb → verify it opens chat and gets a relevant response."""

    @pytest.mark.parametrize("area", [
        "career", "finance", "health", "family", "relationship", "education",
    ])
    def test_life_area_orb_opens_chat_and_gets_response(self, screens, area):
        assert screens.home.present(f"life_area_{area}"), \
            f"life_area_{area} orb not found on home screen"

        # Tap orb → brief popup appears
        screens.home.tap(f"life_area_{area}")
        time.sleep(0.8)

        # Tap "Ask More" in the brief popup
        assert screens.home.present("life_area_ask_more_button"), \
            f"life_area_ask_more_button not visible for {area}"
        screens.home.tap("life_area_ask_more_button")
        time.sleep(1)

        screens.chat.wait_for("chat_input", timeout=10)

        # User bubble should show the short label ("What's ahead for my Career?")
        # not the raw forecast text
        label = _user_bubble_label(screens)
        assert len(label) > 0, f"[{area}] No user bubble found in chat"
        assert len(label) < 200, \
            f"[{area}] User bubble is too long — raw query leaked: {label[:200]}"

        response = screens.chat.wait_for_response(timeout=90)
        _assert_response_ok(response, f"life_area_{area}")

        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)


# ── dasha card ────────────────────────────────────────────────────────────────

class TestDashaCard:
    def test_dasha_card_present(self, screens):
        assert screens.home.present("dasha_insight_card"), "dasha_insight_card not found"

    def test_dasha_card_tap_opens_chat(self, screens):
        screens.home.tap_dasha_card()
        screens.chat.wait_for("chat_input", timeout=10)
        assert screens.chat.is_visible(), "Chat not visible after tapping dasha card"

    def test_dasha_card_user_bubble_shows_short_label(self, screens):
        label = _user_bubble_label(screens)
        assert len(label) > 0, "No user bubble found after dasha card tap"
        # Label should be the short "What does my current Dasha mean for me?" string
        # not the full technical query with Dasha period name
        assert "dob" not in label.lower(), "Raw technical query leaked into user bubble"
        assert len(label) < 200, f"User bubble too long — raw query leaked: {label[:200]}"

    def test_dasha_card_gets_substantive_response(self, screens):
        response = screens.chat.wait_for_response(timeout=90)
        _assert_response_ok(response, "dasha_card")
        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)


# ── transit cards ─────────────────────────────────────────────────────────────

class TestTransitCards:
    """Tap individual transit planet orbs and verify chat response."""

    @pytest.mark.parametrize("planet", ["sun", "jupiter", "saturn", "mars"])
    def test_transit_card_opens_chat(self, screens, planet):
        aid = f"transit_card_{planet}"
        if not screens.home.present(aid):
            pytest.skip(f"transit_card_{planet} not shown today")

        screens.home.tap(aid)
        time.sleep(1)
        screens.chat.wait_for("chat_input", timeout=10)

        label = _user_bubble_label(screens)
        assert len(label) > 0, f"[transit {planet}] No user bubble found"
        assert len(label) < 200, \
            f"[transit {planet}] User bubble too long — raw query leaked: {label[:200]}"

        response = screens.chat.wait_for_response(timeout=90)
        _assert_response_ok(response, f"transit_{planet}")

        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)


# ── yoga card popup ───────────────────────────────────────────────────────────

class TestYogaCard:
    def test_yoga_card_present(self, screens):
        assert screens.home.present("yoga_highlight_card"), "yoga_highlight_card not found"

    def test_yoga_card_opens_popup(self, screens):
        # Tap the first yoga card
        assert screens.home.present("yoga_card_0"), "yoga_card_0 not found"
        screens.home.tap("yoga_card_0")
        time.sleep(0.8)
        assert screens.home.present("yoga_ask_more_button"), \
            "yoga_ask_more_button not visible after tapping yoga card"

    def test_yoga_ask_more_opens_chat(self, screens):
        screens.home.tap("yoga_ask_more_button")
        time.sleep(1)
        screens.chat.wait_for("chat_input", timeout=10)
        assert screens.chat.is_visible(), "Chat not visible after Yoga Ask More tap"

    def test_yoga_user_bubble_shows_short_label(self, screens):
        label = _user_bubble_label(screens)
        assert len(label) > 0, "No user bubble found after yoga ask more"
        # Short label: "What does [YogaName] mean for me?"
        # NOT the multi-line technical context block
        assert len(label) < 200, \
            f"User bubble too long — raw yoga context leaked: {label[:200]}"

    def test_yoga_response_is_substantive(self, screens):
        response = screens.chat.wait_for_response(timeout=90)
        _assert_response_ok(response, "yoga_ask_more")
        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)


# ── what's in my mind ─────────────────────────────────────────────────────────

class TestMindQuestions:
    """Test all 4 suggested mind questions from the home screen."""

    @pytest.mark.parametrize("idx", [0, 1, 2, 3])
    def test_mind_question_tappable_and_gets_response(self, screens, idx):
        aid = f"mind_question_{idx}"
        if not screens.home.present(aid):
            pytest.skip(f"mind_question_{idx} not present")

        screens.home.tap(aid)
        time.sleep(1)
        screens.chat.wait_for("chat_input", timeout=10)

        # For mind questions, user bubble IS the question text (no separate label)
        label = _user_bubble_label(screens)
        assert len(label) > 0, f"[mind_question_{idx}] No user bubble found"

        response = screens.chat.wait_for_response(timeout=90)
        _assert_response_ok(response, f"mind_question_{idx}")

        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)


# ── known backend bugs ────────────────────────────────────────────────────────
# These tests document known backend issues. They are marked xfail so CI stays
# green but they will flip to PASS once the backend is fixed.

class TestKnownBackendBugs:
    @pytest.mark.xfail(reason="Backend Bug #1: LLM ignores yoga context, returns generic natal analysis")
    def test_yoga_response_mentions_yoga_name(self, screens):
        """After asking about a yoga, the response should reference that yoga by name."""
        screens.home.tap("yoga_card_0")
        time.sleep(0.8)
        screens.home.tap("yoga_ask_more_button")
        time.sleep(1)
        screens.chat.wait_for("chat_input", timeout=10)
        response = screens.chat.wait_for_response(timeout=90)
        # This currently fails — LLM ignores the yoga name entirely
        yoga_keywords = ["yoga", "dosha", "combination", "chart pattern"]
        assert any(k in response.lower() for k in yoga_keywords), \
            f"Response does not mention yoga at all: {response[:300]}"
        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)

    @pytest.mark.xfail(reason="Backend Bug #2: mind_question[0] blocked by guardrail")
    def test_first_mind_question_not_blocked(self, screens):
        """First mind question 'Should I take on a new project at work?' should not be blocked."""
        if not screens.home.present("mind_question_0"):
            pytest.skip("mind_question_0 not present")
        screens.home.tap("mind_question_0")
        time.sleep(1)
        screens.chat.wait_for("chat_input", timeout=10)
        response = screens.chat.wait_for_response(timeout=90)
        assert "i'm sorry, but i can't provide" not in response.lower(), \
            "First mind question is blocked by guardrail"
        screens.chat.tap_new_chat()
        screens.home.tap("tab_home")
        time.sleep(0.5)

    @pytest.mark.xfail(reason="Backend Bug #3: language parameter not respected — backend always returns English")
    def test_home_data_respects_language_setting(self, screens, driver):
        """When app language is Hindi, home data (daily insight, mind questions) should be in Hindi."""
        # This requires changing app language to hi and reloading home data
        # Currently fails because backend ignores language=hi and returns English
        import re
        # Hindi text contains Devanagari characters (Unicode range U+0900–U+097F)
        devanagari = re.compile(r'[ऀ-ॿ]')
        # Scrape the daily insight text on home screen
        insight_elements = screens.home.finds("daily_insight_text")
        if not insight_elements:
            pytest.skip("daily_insight_text not present")
        insight_text = insight_elements[0].get_attribute("label") or ""
        assert devanagari.search(insight_text), \
            f"Daily insight is in English even with language=hi: {insight_text[:100]}"
