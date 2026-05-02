# ios_app/e2e/test_12_style_finance.py
from helpers.assertions import (
    assert_min_words, assert_no_guarantees, assert_has_timing_window,
    assert_has_recovery_path, assert_no_bankruptcy,
)


class TestStyleFinance:
    def _ask_and_get(self, screens, question: str) -> str:
        screens.home.tap_chat_tab()
        screens.chat.tap_new_chat()
        screens.chat.send(question)
        return screens.chat.wait_for_response(timeout=90)

    def test_finance_core_wealth_response(self, screens):
        """finance_core group: wealth potential — timing window, no guarantees, ≥50 words."""
        response = self._ask_and_get(screens, "What is my wealth potential and financial outlook?")
        assert_min_words(response, 50)
        assert_no_guarantees(response)
        assert_has_timing_window(response)
        screens.chat.tap_back()

    def test_finance_speculation_response(self, screens):
        """finance_speculation group: stock market — no guarantees, no specific tickers."""
        response = self._ask_and_get(screens, "What does my chart say about stock market investments?")
        assert_no_guarantees(response)
        assert_min_words(response, 30)
        import re
        assert not re.search(r'\b(AAPL|TSLA|RELIANCE|NIFTY|SENSEX)\b', response), \
            "Response contains specific stock tickers"
        screens.chat.tap_back()

    def test_finance_losses_response(self, screens):
        """finance_losses group: financial stress — recovery path, no 'bankruptcy'."""
        response = self._ask_and_get(
            screens, "I have been facing financial stress. What does my chart indicate?"
        )
        assert_min_words(response, 30)
        assert_has_recovery_path(response)
        assert_no_bankruptcy(response)
        screens.chat.tap_back()

    def test_finance_windfall_response(self, screens):
        """finance_windfall group: inheritance — no guarantees, honest framing."""
        response = self._ask_and_get(screens, "Will I receive any inheritance or unexpected wealth?")
        assert_no_guarantees(response)
        assert_min_words(response, 30)
        screens.chat.tap_back()
