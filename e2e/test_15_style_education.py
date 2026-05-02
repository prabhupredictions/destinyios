# ios_app/e2e/test_15_style_education.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
    assert_no_education_fail_verdict,
)


class TestStyleEducation:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_education_core_academic_potential(self, screens):
        """education_core: academic potential — plain language, no planets, timing window, ≥50w."""
        response = self._ask_and_get(screens, "What is my academic potential and learning style?")
        assert_min_words(response, 50)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_education_competitive_exam_potential(self, screens):
        """education_competitive: competitive exams — conditional framing, no failure verdict, timing."""
        response = self._ask_and_get(
            screens, "Will I succeed in competitive exams? What is my best window?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_education_fail_verdict(response)
        assert_has_timing_window(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        screens.chat.tap_back()

    def test_education_advanced_phd_research(self, screens):
        """education_advanced: PhD/research — no guarantees, plain language, timing window."""
        response = self._ask_and_get(
            screens, "Should I pursue a PhD? Am I suited for research?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_has_timing_window(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        screens.chat.tap_back()

    def test_education_vocational_teaching(self, screens):
        """education_vocational: teaching potential — plain language, timing, no planet names."""
        response = self._ask_and_get(
            screens, "What skills suit my chart? Am I built for teaching?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()
