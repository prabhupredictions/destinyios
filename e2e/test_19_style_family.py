# ios_app/e2e/test_19_style_family.py
from helpers.assertions import (
    assert_min_words,
    assert_no_guarantees,
    assert_has_timing_window,
    assert_no_planet_names,
    assert_no_em_dashes,
)


def assert_no_child_fatalism(text: str):
    phrases = [
        "you will never have children",
        "you cannot have children",
        "you are infertile",
        "you will not have a child",
        "childlessness is certain",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Child fatalism found: '{phrase}'"


def assert_no_family_death_prediction(text: str):
    phrases = [
        "your parent will die",
        "your sibling will die",
        "permanent estrangement",
        "you will never reconcile",
    ]
    for phrase in phrases:
        assert phrase not in text.lower(), f"Family death/estrangement prediction found: '{phrase}'"


class TestStyleFamily:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_family_children_parenthood(self, screens):
        """family_children: parenthood question — no child fatalism, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "Will I have children? What is my parenting potential?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_child_fatalism(response)
        screens.chat.tap_back()

    def test_family_harmony_bonding(self, screens):
        """family_harmony: family bonding style — no planets, timing window, ≥40w."""
        response = self._ask_and_get(
            screens, "How is my family life? Am I suited for joint family living?"
        )
        assert_min_words(response, 40)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_family_death_prediction(response)
        screens.chat.tap_back()

    def test_family_separation_siblings(self, screens):
        """family_separation: sibling and elder care — no death predictions, timing, ≥40w."""
        response = self._ask_and_get(
            screens, "How are my sibling relationships? Will I take care of my parents?"
        )
        assert_min_words(response, 40)
        assert_no_guarantees(response)
        assert_no_planet_names(response)
        assert_no_em_dashes(response)
        assert_has_timing_window(response)
        assert_no_family_death_prediction(response)
        screens.chat.tap_back()
