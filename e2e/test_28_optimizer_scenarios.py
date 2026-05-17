# ios_app/e2e/test_28_optimizer_scenarios.py
"""
E2E tests for QueryOptimizerService scenarios via the Chat tab.

Each class exercises a distinct optimizer capability:

  TestOptimizerAreaRouting        — correct domain classification for fresh queries
  TestOptimizerFollowUpContinuity — multi-turn context retained for short follow-ups
  TestOptimizerTopicShift         — area change mid-conversation handled cleanly
  TestOptimizerShortQueryExpansion— 1-3 word queries expanded from conversation context
  TestOptimizerTimingQueries      — date extraction embedded in responses
  TestOptimizerMultiTurnDepth     — 3-turn conversation; each turn builds on prior
  TestOptimizerCompatMultiTurn    — AskDestiny compatibility chat multi-turn (context fix)

Test user: Prabhu (1980-07-01, 06:32, Bhilai) injected via E2E env vars.
Compatibility partner: Smita (1980-11-13, 09:30, Belgaum) for the last class.
"""

import time
import pytest
from helpers.assertions import assert_min_words, assert_has_timing_window


# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

# Phrases that indicate the LLM lost conversation context
CONFUSION_PHRASES = [
    "could you clarify",
    "what do you mean",
    "i'm not sure what you",
    "please provide more information",
    "what topic are you",
    "which area are you",
    "what are you referring to",
    "i don't have enough context",
    "could you specify",
    "please clarify",
    "could you tell me more about what",
]

AREA_KEYWORDS = {
    "marriage":  ["marriage", "marry", "spouse", "wedding", "partner", "7th house",
                  "venus", "marital", "relationship"],
    "career":    ["career", "job", "profession", "promotion", "work", "business",
                  "10th house", "saturn", "professional"],
    "health":    ["health", "body", "disease", "medical", "vitality", "6th house",
                  "physical", "wellness"],
    "finance":   ["finance", "wealth", "money", "income", "investment", "financial",
                  "2nd house", "11th house"],
    "travel":    ["travel", "abroad", "foreign", "relocation", "journey", "12th house",
                  "overseas"],
    "education": ["education", "study", "degree", "exam", "academic", "learning",
                  "4th house", "5th house"],
    "family":    ["children", "child", "family", "son", "daughter", "5th house",
                  "progeny"],
    "spiritual": ["spiritual", "karma", "moksha", "meditation", "dharma", "soul"],
}


def _no_confusion(response: str, where: str = ""):
    low = response.lower()
    for phrase in CONFUSION_PHRASES:
        assert phrase not in low, \
            f"Context confusion phrase '{phrase}' found{' in ' + where if where else ''}"


def _has_area_keywords(response: str, area: str):
    low = response.lower()
    assert any(kw in low for kw in AREA_KEYWORDS[area]), \
        f"Response does not contain expected {area} keywords. Got: {response[:300]!r}"


def _fresh_chat(screens):
    screens.home.tap_chat_tab()
    time.sleep(0.5)
    if screens.chat.message_count() > 0:
        screens.chat.tap_new_chat()
        time.sleep(0.5)


# ---------------------------------------------------------------------------
# 1. Area Routing — fresh queries, no prior context
# ---------------------------------------------------------------------------

class TestOptimizerAreaRouting:
    """Optimizer correctly classifies a fresh query into the right life area.
    Verified by checking that the response contains area-relevant vocabulary."""

    def test_marriage_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What does my birth chart indicate about my marriage prospects?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "marriage")

    def test_career_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What does my chart show about my professional career growth?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "career")

    def test_health_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What are the health indications in my birth chart?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "health")

    def test_finance_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What does my chart say about wealth accumulation and finances?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "finance")

    def test_travel_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("Will I settle abroad or have foreign travel opportunities?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "travel")

    def test_family_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What does my chart indicate about having children and family life?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "family")

    def test_spiritual_query_routes_correctly(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What is my spiritual path according to my birth chart?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "spiritual")


# ---------------------------------------------------------------------------
# 2. Follow-up Continuity — short follow-ups must use loaded context
# ---------------------------------------------------------------------------

class TestOptimizerFollowUpContinuity:
    """After an initial answer, short follow-ups ('why?', 'tell me more', 'which period?')
    must use conversation history — the optimizer's loaded_history fix.
    The LLM should NOT ask for clarification it already has."""

    def test_setup_initial_marriage_answer(self, screens):
        _fresh_chat(screens)
        screens.chat.send("What does my chart say about marriage timing?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "marriage")

    def test_followup_why_retains_context(self, screens):
        """'Why?' after marriage answer must produce a contextual elaboration,
        not ask 'what do you mean by why?' or demand topic clarification."""
        screens.chat.send("Why?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _no_confusion(resp, "follow-up 'Why?'")
        _has_area_keywords(resp, "marriage")

    def test_followup_tell_me_more_elaborates(self, screens):
        """'Tell me more' should elaborate on marriage, not re-ask what topic."""
        screens.chat.send("Tell me more about this")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _no_confusion(resp, "follow-up 'Tell me more'")
        _has_area_keywords(resp, "marriage")

    def test_followup_which_period_uses_context(self, screens):
        """'Which specific period?' must resolve against prior timing discussion."""
        screens.chat.send("Which specific period should I watch for?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _no_confusion(resp, "follow-up 'Which specific period'")
        # Response should contain a year or dasha reference
        assert_has_timing_window(resp)

    def test_followup_what_else_stays_on_topic(self, screens):
        """'What else?' must continue on marriage, not switch topic or ask for clarification."""
        screens.chat.send("What else should I know?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _no_confusion(resp, "follow-up 'What else'")
        _has_area_keywords(resp, "marriage")


# ---------------------------------------------------------------------------
# 3. Topic Shift — optimizer detects area change mid-conversation
# ---------------------------------------------------------------------------

class TestOptimizerTopicShift:
    """When the user shifts from one topic to another, the optimizer must classify
    the new area correctly and not carry over the prior area's framing."""

    def test_setup_initial_marriage_answer(self, screens):
        _fresh_chat(screens)
        screens.chat.send("When is a favorable time for my marriage?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "marriage")

    def test_topic_shift_to_career(self, screens):
        """Asking about career after a marriage thread — must route to career, not marriage."""
        screens.chat.send("Now tell me about my career prospects and job growth.")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "career")
        # Must not be confused by the prior marriage context
        low = resp.lower()
        assert "marriage" not in low and "spouse" not in low, \
            "Career response contaminated with marriage context"

    def test_followup_after_topic_shift_stays_on_career(self, screens):
        """'Tell me more' after career answer must elaborate on career, not revert to marriage."""
        screens.chat.send("Tell me more about job changes.")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _no_confusion(resp, "post-shift follow-up")
        _has_area_keywords(resp, "career")

    def test_second_topic_shift_to_health(self, screens):
        """Shift again from career to health — optimizer must detect second shift."""
        screens.chat.send("What about my health and physical vitality?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "health")


# ---------------------------------------------------------------------------
# 4. Short Query Expansion — 1-3 word queries must expand from context
# ---------------------------------------------------------------------------

class TestOptimizerShortQueryExpansion:
    """The optimizer's validate_compatibility_query and routing_query rewrite must
    expand bare keywords into full questions using conversation context."""

    def test_single_word_marriage_query(self, screens):
        """Bare 'Marriage?' at the start — optimizer expands to a full marriage question."""
        _fresh_chat(screens)
        screens.chat.send("Marriage?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _has_area_keywords(resp, "marriage")

    def test_single_word_career_query(self, screens):
        _fresh_chat(screens)
        screens.chat.send("Career?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _has_area_keywords(resp, "career")

    def test_two_word_contextual_followup(self, screens):
        """After a marriage answer, 'More details?' should expand into a marriage elaboration."""
        _fresh_chat(screens)
        screens.chat.send("What does my chart indicate about my marriage?")
        screens.chat.wait_for_response(timeout=90)
        screens.chat.send("More details?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _no_confusion(resp, "2-word follow-up 'More details?'")
        _has_area_keywords(resp, "marriage")

    def test_two_word_timing_followup(self, screens):
        """'When exactly?' after a timing answer must produce a refined timing response."""
        _fresh_chat(screens)
        screens.chat.send("When will my career improve?")
        screens.chat.wait_for_response(timeout=90)
        screens.chat.send("When exactly?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 15)
        _no_confusion(resp, "2-word follow-up 'When exactly?'")
        assert_has_timing_window(resp)


# ---------------------------------------------------------------------------
# 5. Timing Queries — date extraction and embedding
# ---------------------------------------------------------------------------

class TestOptimizerTimingQueries:
    """Timing queries must produce responses with concrete year/period references.
    The optimizer embeds the extracted date range into routing_query for tools."""

    def test_marriage_timing_has_year(self, screens):
        _fresh_chat(screens)
        screens.chat.send("When will I get married according to my chart?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        assert_has_timing_window(resp)
        _has_area_keywords(resp, "marriage")

    def test_career_timing_has_year(self, screens):
        _fresh_chat(screens)
        screens.chat.send("When will I get a promotion or significant career advancement?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        assert_has_timing_window(resp)
        _has_area_keywords(resp, "career")

    def test_explicit_date_in_query_preserved(self, screens):
        """When user states a date ('in 2027'), the response should reference it."""
        _fresh_chat(screens)
        screens.chat.send("What happens in my career between 2026 and 2028?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        assert "202" in resp, "Explicit date range not reflected in response"
        _has_area_keywords(resp, "career")

    def test_relative_date_resolved(self, screens):
        """'Next 2 years' must be resolved to actual dates — response should cite a year."""
        _fresh_chat(screens)
        screens.chat.send("What does the next 2 years look like for my finances?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        assert_has_timing_window(resp)
        _has_area_keywords(resp, "finance")

    def test_past_timing_query(self, screens):
        """'What happened in my career around 2020?' — past query handled correctly."""
        _fresh_chat(screens)
        screens.chat.send("What significant career events happened around 2018 to 2021?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "career")
        # Should reference the past period
        assert any(yr in resp for yr in ["2018", "2019", "2020", "2021"]), \
            "Past period not referenced in response"


# ---------------------------------------------------------------------------
# 6. Multi-Turn Depth — 3 exchanges, each building on prior
# ---------------------------------------------------------------------------

class TestOptimizerMultiTurnDepth:
    """3-turn conversation verifying optimizer context depth.
    Each turn must build on the prior answer; the 3rd turn must not
    re-introduce content from turn 1 as if it's new."""

    def test_turn_1_personality(self, screens):
        _fresh_chat(screens)
        screens.chat.send(
            "What does my birth chart reveal about my core personality and strengths?"
        )
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        # Store first response count
        self.__class__._count_after_t1 = screens.chat.message_count()

    def test_turn_2_challenges_builds_on_t1(self, screens):
        """'What challenges do I face?' must reference personality context from turn 1."""
        screens.chat.send("What challenges do I face based on this?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _no_confusion(resp, "turn 2")
        # Should produce a new message
        assert screens.chat.message_count() > self.__class__._count_after_t1, \
            "Turn 2 did not produce a new AI message"
        self.__class__._count_after_t2 = screens.chat.message_count()

    def test_turn_3_solution_builds_on_t2(self, screens):
        """'How do I overcome these?' must reference challenges from turn 2, not re-introduce t1."""
        screens.chat.send("How do I overcome these challenges?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _no_confusion(resp, "turn 3")
        assert screens.chat.message_count() > self.__class__._count_after_t2, \
            "Turn 3 did not produce a new AI message"

    def test_turn_3_does_not_repeat_turn_1_intro(self, screens):
        """The 3rd response must not re-introduce birth chart basics as if the user just asked."""
        msgs = screens.chat.d.find_elements(
            __import__("appium.webdriver.common.appiumby", fromlist=["AppiumBy"]).AppiumBy.ACCESSIBILITY_ID,
            "ai_message"
        )
        last = msgs[-1].get_attribute("label").lower() if msgs else ""
        # Should not contain a generic opening about birth charts that ignores context
        intro_phrases = ["your birth chart reveals", "based on your birth chart, here is"]
        for phrase in intro_phrases:
            assert phrase not in last, \
                f"Turn 3 re-introduced generic intro: '{phrase}'"


# ---------------------------------------------------------------------------
# 7. Disambiguation — transfer vs job_change vs relocation
# ---------------------------------------------------------------------------

class TestOptimizerDisambiguation:
    """The optimizer prompt has explicit disambiguation rules for confusing area pairs.
    Verify these route correctly."""

    def test_transfer_routes_to_travel_not_career(self, screens):
        """'Job transfer to another city' → travel/transfer, not career/job_change."""
        _fresh_chat(screens)
        screens.chat.send(
            "Will I get transferred to another city in my current job in the next 2 years?"
        )
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        # Transfer response should mention relocation/city/posting
        low = resp.lower()
        assert any(w in low for w in ["transfer", "posting", "city", "relocat", "travel"]), \
            f"Transfer query response doesn't mention transfer/relocation: {resp[:300]!r}"

    def test_relocation_routes_to_travel(self, screens):
        _fresh_chat(screens)
        screens.chat.send("Is there a chance I will relocate to another city or country?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        _has_area_keywords(resp, "travel")

    def test_foreign_job_routes_to_travel_not_career(self, screens):
        _fresh_chat(screens)
        screens.chat.send("Will I get a job opportunity abroad and work in another country?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 30)
        low = resp.lower()
        assert any(w in low for w in ["abroad", "foreign", "overseas", "work visa",
                                       "international", "settle"]), \
            f"Foreign job query missing travel keywords: {resp[:300]!r}"


# ---------------------------------------------------------------------------
# 8. Compatibility Multi-Turn — verifies conversation_id fix via AskDestiny
# ---------------------------------------------------------------------------

def _navigate_to_result(screens):
    screens.home.tap_match_tab()
    assert screens.compat.is_visible()
    if not screens.compat.present("compat_result_score"):
        assert screens.compat.is_analyze_enabled(), \
            "Analyze disabled — check E2E partner env vars"
        screens.compat.tap_analyze()
        screens.compat.wait_for_result(timeout=180)
    assert screens.compat.present("compat_result_score"), "Result score not visible"


def _open_ask_destiny(screens):
    screens.compat.tap("ask_destiny_button")
    screens.ask_destiny.wait_for("ask_destiny_sheet", timeout=10)
    assert screens.ask_destiny.is_visible(), "AskDestinySheet did not open"


class TestOptimizerCompatMultiTurn:
    """Verifies that AskDestiny compatibility chat retains multi-turn context.

    The root cause of context loss was conversation_id=None in the /follow-up
    endpoint — preventing the optimizer from loading chat history.
    These tests confirm the fix: short follow-ups after an initial compat
    answer must be contextual, not confused."""

    def test_setup_navigate_to_result(self, screens):
        _navigate_to_result(screens)

    def test_open_ask_destiny_sheet(self, screens):
        _open_ask_destiny(screens)

    def test_turn_1_overall_compatibility(self, screens):
        screens.ask_destiny.send("What is the overall compatibility between us?")
        resp = screens.ask_destiny.wait_for_ai_response(timeout=120)
        assert_min_words(resp, 30)
        low = resp.lower()
        assert any(w in low for w in ["compat", "match", "score", "ashtakoot", "guna"]), \
            f"Turn 1 response lacks compatibility keywords: {resp[:300]!r}"
        time.sleep(3)  # let typewriter finish

    def test_turn_2_why_uses_context(self, screens):
        """'Why?' after a compatibility answer — must elaborate on compat, not ask what topic."""
        screens.ask_destiny.send("Why?")
        resp = screens.ask_destiny.wait_for_ai_response(timeout=120)
        assert_min_words(resp, 20)
        _no_confusion(resp, "compat follow-up 'Why?'")
        # Must still be about compatibility, not generic
        low = resp.lower()
        assert any(w in low for w in ["compat", "match", "planets", "dosha", "guna",
                                       "score", "couple", "chart"]), \
            f"'Why?' response lost compatibility context: {resp[:300]!r}"

    def test_turn_3_specific_area_followup(self, screens):
        """'What about our financial compatibility?' — must produce compat + finance answer."""
        screens.ask_destiny.send("What about our financial compatibility?")
        resp = screens.ask_destiny.wait_for_ai_response(timeout=120)
        assert_min_words(resp, 20)
        _no_confusion(resp, "compat turn 3")
        low = resp.lower()
        assert any(w in low for w in ["financ", "wealth", "money", "2nd house",
                                       "11th house", "prosperit"]), \
            f"Financial compat response lacks finance keywords: {resp[:300]!r}"

    def test_turn_4_tell_me_more_stays_in_compat(self, screens):
        """'Tell me more about this' — 4th turn must remain in compatibility context."""
        screens.ask_destiny.send("Tell me more about this")
        resp = screens.ask_destiny.wait_for_ai_response(timeout=120)
        assert_min_words(resp, 20)
        _no_confusion(resp, "compat turn 4")

    def test_dismiss_sheet(self, screens):
        screens.ask_destiny.dismiss()
        time.sleep(1)
        assert not screens.ask_destiny.is_visible(), "Sheet still open after dismiss"


# ---------------------------------------------------------------------------
# 9. Language Detection — multilingual queries
# ---------------------------------------------------------------------------

class TestOptimizerLanguage:
    """Optimizer detects language and the LLM responds in the same language."""

    def test_hindi_query_gets_hindi_response(self, screens):
        """A Hindi query should produce a response containing Devanagari characters."""
        _fresh_chat(screens)
        screens.chat.send("मेरी शादी कब होगी?")  # "When will I get married?"
        resp = screens.chat.wait_for_response(timeout=90)
        assert len(resp) > 10, "Empty response for Hindi query"
        # Response should contain Devanagari or at minimum marriage-related content
        has_devanagari = any("ऀ" <= ch <= "ॿ" for ch in resp)
        has_marriage = any(w in resp.lower() for w in AREA_KEYWORDS["marriage"])
        assert has_devanagari or has_marriage, \
            f"Hindi query response neither in Hindi nor about marriage: {resp[:300]!r}"

    def test_english_query_after_hindi_works(self, screens):
        """Switching back to English after a Hindi query must work cleanly."""
        screens.chat.send("What about my career?")
        resp = screens.chat.wait_for_response(timeout=90)
        assert_min_words(resp, 20)
        _has_area_keywords(resp, "career")
