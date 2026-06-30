"""
E2E: streaming chat path.

Pre-reqs:
- Staging backend deployed with STREAMING_ENABLED=true, STREAMING_COHORT_PERCENT=100
- iOS Debug build run with UI_TEST_MODE arg — note that UI_TEST_MODE pins
  AppConfig.shared.shouldStreamFor() to FALSE, so this test bypasses the
  cohort gate by injecting AppConfig directly via launchEnvironment.

Run:
    cd ios_app/e2e
    source ../../astrology_api/astroapi-v2/venv/bin/activate
    TEST_ENV=staging STREAMING_E2E_FORCE_ON=1 pytest test_24_chat_streaming.py -v

NOTE: These tests cannot be executed in CI without a running Appium server and
a staging backend deployed with STREAMING_ENABLED=true. They are skipped
automatically in environments where the Appium server is unreachable
(conftest.py raises on driver init). Run them manually before each rollout step.
"""
import pytest
from helpers.screens import ChatScreen, HomeScreen


@pytest.fixture(scope="module")
def chat(screens):
    home: HomeScreen = screens["home"]
    home.tap_chat_tab()
    return screens["chat"]


def test_streaming_completes_within_30s(chat: ChatScreen, driver):
    """End-to-end: send a question, expect placeholder bubble → streaming
    bubble (plain text) → MarkdownTextView (final rendering) within 30s.

    UI_TEST_MODE injects AppConfig override via launch env:
      STREAMING_E2E_FORCE_ON=1 → AppConfig.shared.streamingEnabled=true and
      AppConfig.shared.streamingCohortPercent=100 at startup.
    """
    chat.send("Will my career improve this year?")

    # Streaming bubble visible within 5s of send.
    chat.wait_for_element("chat_assistant_streaming_bubble", timeout=5)

    # Final markdown bubble visible within 30s.
    chat.wait_for_element("chat_assistant_final_bubble", timeout=30)

    # User message preserved at top of latest pair.
    assert chat.last_user_message_text() == "Will my career improve this year?"


def test_stop_button_discards_partial(chat: ChatScreen, driver):
    """Stop mid-stream → user message preserved, no assistant bubble persists."""
    chat.send("Tell me about Saturn's transit")
    chat.wait_for_element("chat_assistant_streaming_bubble", timeout=5)
    chat.tap("chat_stop_button")

    # Streaming bubble is gone within 2s.
    chat.wait_for_element_gone("chat_assistant_streaming_bubble", timeout=2)
    # No final bubble created.
    assert not chat.element_exists("chat_assistant_final_bubble", from_last_send=True)
    # User message preserved.
    assert chat.last_user_message_text() == "Tell me about Saturn's transit"


def test_kill_switch_falls_back_to_sync(chat: ChatScreen, driver):
    """When server returns 410 (streaming_enabled=false), client falls
    back to sync /predict transparently — user sees a normal answer."""
    # Test fixture toggles STREAMING_ENABLED=false on staging via env-flip.
    pytest.skip("Requires staging env flip — run manually before rollout step 2")
