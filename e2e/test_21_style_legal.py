# ios_app/e2e/test_21_style_legal.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_outcome_prediction(text: str):
    phrases = [
        "you will win",
        "you will lose",
        "case will be decided in your favor",
        "court will rule in your favor",
        "guaranteed victory",
        "certain to win",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Court outcome prediction found: '{phrase}'"


def assert_no_legal_strategy(text: str):
    phrases = [
        "you should file",
        "hire a lawyer",
        "you must appeal",
        "file an fir",
        "file a complaint",
        "you should sue",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Specific legal strategy found: '{phrase}'"


class TestStyleLegal:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_legal_disputes_court_readiness(self, screens):
        """legal_disputes: court readiness — no outcome prediction, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Will I win my court case? Am I suited for fighting legal battles or should I settle?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_outcome_prediction(response)
        screens.chat.tap_back()

    def test_legal_compliance_contracts(self, screens):
        """legal_compliance: contracts and government dealings — no guarantees, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Is this a good time to sign contracts? How does my chart support handling government approvals and tax filings?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_legal_protection_defamation(self, screens):
        """legal_protection: defamation and fraud — no outcome prediction, no strategy advice, timing, ≥40w."""
        response = self._ask_and_get(
            screens, "Am I protected against defamation and false accusations? What does my chart say about fraud risks and hidden enemies?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_outcome_prediction(response)
        assert_no_legal_strategy(response)
        screens.chat.tap_back()
