#!/usr/bin/env python3
"""
Append the subscription_expired_* keys to every Localizable.strings file.
Three keys per locale × 13 locales = 39 strings.
Idempotent — skips locales where keys already exist.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "ios_app" / "ios_app"

ENTRIES = {
    "subscription_expired_title": {
        "en":      "Your subscription has ended",
        "hi":      "आपकी सदस्यता समाप्त हो गई है",
        "ta":      "உங்கள் சந்தாக்கால அமைப்பு முடிவடைந்துவிட்டது",
        "te":      "మీ సబ్‌స్క్రిప్షన్ ముగిసింది",
        "kn":      "ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆ ಮುಗಿದಿದೆ",
        "ml":      "നിങ്ങളുടെ സബ്‌സ്‌ക്രിപ്‌ഷൻ അവസാനിച്ചു",
        "es":      "Tu suscripción ha terminado",
        "fr":      "Votre abonnement a pris fin",
        "pt":      "Sua assinatura terminou",
        "de":      "Ihr Abonnement ist abgelaufen",
        "ru":      "Ваша подписка закончилась",
        "zh-Hans": "您的订阅已结束",
        "ja":      "サブスクリプションが終了しました",
    },
    "subscription_expired_body": {
        "en":      "Renew to keep asking questions and accessing premium features.",
        "hi":      "प्रश्न पूछना और प्रीमियम सुविधाओं तक पहुंच जारी रखने के लिए नवीनीकरण करें।",
        "ta":      "கேள்விகள் கேட்கவும் பிரீமியம் அம்சங்களை அணுகவும் புதுப்பிக்கவும்.",
        "te":      "ప్రశ్నలు అడగడం మరియు ప్రీమియం ఫీచర్‌లను యాక్సెస్ చేయడం కొనసాగించడానికి పునరుద్ధరించండి.",
        "kn":      "ಪ್ರಶ್ನೆಗಳನ್ನು ಕೇಳಲು ಮತ್ತು ಪ್ರೀಮಿಯಂ ವೈಶಿಷ್ಟ್ಯಗಳನ್ನು ಪ್ರವೇಶಿಸಲು ನವೀಕರಿಸಿ.",
        "ml":      "ചോദ്യങ്ങൾ ചോദിക്കാനും പ്രീമിയം ഫീച്ചറുകൾ ഉപയോഗിക്കാനും പുതുക്കുക.",
        "es":      "Renueva para seguir haciendo preguntas y acceder a funciones premium.",
        "fr":      "Renouvelez pour continuer à poser des questions et accéder aux fonctionnalités premium.",
        "pt":      "Renove para continuar fazendo perguntas e acessando recursos premium.",
        "de":      "Verlängern Sie, um weiterhin Fragen zu stellen und Premium-Funktionen zu nutzen.",
        "ru":      "Обновите подписку, чтобы продолжать задавать вопросы и пользоваться премиум-функциями.",
        "zh-Hans": "续订以继续提问和使用高级功能。",
        "ja":      "更新して質問とプレミアム機能のご利用を続けてください。",
    },
    "subscription_expired_cta": {
        "en":      "Renew Plus",
        "hi":      "Plus नवीनीकरण करें",
        "ta":      "Plus புதுப்பிக்கவும்",
        "te":      "Plus పునరుద్ధరించండి",
        "kn":      "Plus ನವೀಕರಿಸಿ",
        "ml":      "Plus പുതുക്കുക",
        "es":      "Renovar Plus",
        "fr":      "Renouveler Plus",
        "pt":      "Renovar Plus",
        "de":      "Plus erneuern",
        "ru":      "Возобновить Plus",
        "zh-Hans": "续订 Plus",
        "ja":      "Plus を更新する",
    },
}

LOCALES = ["en", "hi", "ta", "te", "kn", "ml", "es", "fr", "pt", "de", "ru", "zh-Hans", "ja"]


def append_keys(locale: str) -> tuple[int, int]:
    path = ROOT / f"{locale}.lproj" / "Localizable.strings"
    if not path.exists():
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
        text += "\n// Subscription-expired paywall (state model: lapsed paid users)\n"
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
