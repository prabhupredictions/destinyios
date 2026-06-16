#!/usr/bin/env python3
"""
Append the quota_daily_limit_title key to every Localizable.strings file.
Idempotent — skips locales where the key already exists.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "ios_app" / "ios_app"

ENTRIES = {
    "quota_daily_limit_title": {
        "en":      "Daily limit reached",
        "hi":      "दैनिक सीमा समाप्त",
        "ta":      "தினசரி வரம்பு எட்டப்பட்டது",
        "te":      "రోజువారీ పరిమితి చేరింది",
        "kn":      "ದೈನಂದಿನ ಮಿತಿ ತಲುಪಿದೆ",
        "ml":      "ദൈനംദിന പരിധി എത്തി",
        "es":      "Límite diario alcanzado",
        "fr":      "Limite quotidienne atteinte",
        "pt":      "Limite diário atingido",
        "de":      "Tageslimit erreicht",
        "ru":      "Дневной лимит достигнут",
        "zh-Hans": "已达每日上限",
        "ja":      "本日の上限に達しました",
    },
}

LOCALES = ["en", "hi", "ta", "te", "kn", "ml", "es", "fr", "pt", "de", "ru", "zh-Hans", "ja"]


def append_keys(locale: str) -> tuple[int, int]:
    path = ROOT / f"{locale}.lproj" / "Localizable.strings"
    if not path.exists():
        print(f"⚠️  {locale}: file missing, skipping")
        return (0, 0)
    text = path.read_text(encoding="utf-8")
    added = 0
    skipped = 0
    new_lines = []
    for key, translations in ENTRIES.items():
        if f'"{key}"' in text:
            skipped += 1
            continue
        value = translations[locale].replace('"', '\\"')
        new_lines.append(f'"{key}" = "{value}";')
        added += 1
    if new_lines:
        if not text.endswith("\n"):
            text += "\n"
        text += "\n// Daily-limit headline (chunk 5 — distinguishes from permanent limit)\n"
        text += "\n".join(new_lines) + "\n"
        path.write_text(text, encoding="utf-8")
    return (added, skipped)


if __name__ == "__main__":
    print(f"{'Locale':10} {'Added':>6} {'Skipped':>8}")
    print("-" * 30)
    total = 0
    for loc in LOCALES:
        a, s = append_keys(loc)
        total += a
        print(f"{loc:10} {a:>6} {s:>8}")
    print("-" * 30)
    print(f"Total added: {total}")
