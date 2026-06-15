#!/usr/bin/env python3
"""
Paywall v2 — 13-language Localization Sweep
============================================
For every paywall-related key in en.lproj/Localizable.strings, asserts:
  1. Every other supported locale has the key
  2. The translation is non-empty and not just the English value verbatim
     (which usually means "untranslated placeholder")
  3. Format specifiers (%@, %d, %.1f, %1$@) match between en and locale

Exit code 0 = all locales clean. Exit code 1 = gaps found.
Output: a Markdown table of gaps suitable for paste into the tracker.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "ios_app" / "ios_app"
LOCALES = [
    "en", "hi", "ta", "te", "kn", "ml",
    "es", "fr", "pt", "de", "ru", "zh-Hans", "ja",
]

# Paywall scope = these substrings classify a key as paywall-relevant
PAYWALL_KEY_PATTERNS = [
    "paywall", "trial", "subscription", "subscribe",
    "plus", "core", "upgrade", "free_week", "unlimited",
    "fair_use", "restore", "purchase", "manage", "auto_renew",
    "apple_subscription", "apple_id", "iap", "intro_offer",
    "premium", "cosmic_guidance", "starts_format",
    "everything_in", "redeem", "promo", "offer",
    "conflict_banner", "no_purchases",
]

# Strings that SHOULD remain in English by design (proper nouns, etc.)
ENGLISH_BY_DESIGN = {
    "Apple ID", "App Store", "Plus", "Core",  # product/brand names
}


def parse_strings_file(path: Path) -> dict:
    """Lightweight parser for .strings files. Handles standard
    "key" = "value"; entries (NOT escaped quotes inside values).
    """
    out = {}
    if not path.exists():
        return out
    text = path.read_text(encoding="utf-8")
    # Match: "key" = "value";
    pattern = re.compile(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', re.MULTILINE)
    for m in pattern.finditer(text):
        out[m.group(1)] = m.group(2)
    return out


def is_paywall_key(key: str) -> bool:
    k = key.lower()
    return any(p in k for p in PAYWALL_KEY_PATTERNS)


def format_specs(s: str) -> list:
    """Return ordered format-specifier tokens like %@, %d, %.1f, %1$@.
    Used to assert translations preserve the format contract.

    Match must end at a recognized type letter (@dsxof…) so a sentence-period
    after %@ doesn't get glommed into the spec.
    """
    return re.findall(r'%(?:\d+\$)?(?:\.\d+)?[@dsxofF]', s)


def main():
    en_path = ROOT / "en.lproj" / "Localizable.strings"
    if not en_path.exists():
        print(f"❌ Missing baseline: {en_path}")
        return 1

    en = parse_strings_file(en_path)
    paywall_keys = [k for k in en if is_paywall_key(k)]
    print(f"🔍 Paywall-relevant keys in en: {len(paywall_keys)} / {len(en)} total")
    print()

    issues = []  # rows of (locale, key, problem, en_val, locale_val)

    for loc in LOCALES:
        if loc == "en":
            continue
        loc_path = ROOT / f"{loc}.lproj" / "Localizable.strings"
        loc_strings = parse_strings_file(loc_path)
        if not loc_strings:
            issues.append((loc, "<file>", "Locale file missing or empty", "", ""))
            continue

        for k in paywall_keys:
            en_val = en[k]
            loc_val = loc_strings.get(k)
            if loc_val is None:
                issues.append((loc, k, "MISSING", en_val, ""))
                continue
            if not loc_val.strip():
                issues.append((loc, k, "EMPTY", en_val, loc_val))
                continue
            # Untranslated heuristic: identical to English AND English is >2 words
            if loc_val == en_val and len(en_val.split()) > 2 and en_val not in ENGLISH_BY_DESIGN:
                issues.append((loc, k, "VERBATIM_EN (likely untranslated)", en_val, loc_val))
            # Format specifier mismatch
            en_specs = format_specs(en_val)
            loc_specs = format_specs(loc_val)
            if sorted(en_specs) != sorted(loc_specs):
                issues.append((
                    loc, k, "FORMAT_MISMATCH",
                    f"specs={en_specs}  '{en_val[:60]}'",
                    f"specs={loc_specs}  '{loc_val[:60]}'",
                ))

    # Summary by locale
    summary = {}
    for loc, _, problem, _, _ in issues:
        summary.setdefault(loc, {"MISSING": 0, "EMPTY": 0,
                                  "VERBATIM_EN (likely untranslated)": 0,
                                  "FORMAT_MISMATCH": 0})
        if problem in summary[loc]:
            summary[loc][problem] += 1

    print("## Paywall Localization Sweep — Summary")
    print()
    print("| Locale | Missing | Empty | Verbatim-EN | Format Mismatch | Total Issues |")
    print("|---|---|---|---|---|---|")
    total = 0
    for loc in LOCALES:
        if loc == "en":
            continue
        s = summary.get(loc, {})
        m = s.get("MISSING", 0)
        e = s.get("EMPTY", 0)
        v = s.get("VERBATIM_EN (likely untranslated)", 0)
        f = s.get("FORMAT_MISMATCH", 0)
        t = m + e + v + f
        total += t
        flag = "✅" if t == 0 else "⚠️" if t < 5 else "❌"
        print(f"| {loc} | {m} | {e} | {v} | {f} | {t} {flag} |")
    print(f"\n**Grand total issues:** {total}")
    print(f"**Paywall keys checked:** {len(paywall_keys)}")
    print(f"**Locales checked:** {len(LOCALES) - 1}")

    if issues:
        print()
        print("## Top 30 issues (full list available with --verbose)")
        print()
        print("| Locale | Key | Problem | EN | Locale |")
        print("|---|---|---|---|---|")
        for loc, key, problem, en_v, loc_v in issues[:30]:
            en_disp = (en_v[:50] + "…") if len(en_v) > 50 else en_v
            loc_disp = (loc_v[:50] + "…") if len(loc_v) > 50 else loc_v
            print(f"| {loc} | `{key}` | {problem} | {en_disp} | {loc_disp} |")

    return 1 if total > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
