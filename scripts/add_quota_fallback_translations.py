#!/usr/bin/env python3
"""
Append the 4 quota_fallback_* keys to every Localizable.strings file.
Idempotent — skips a locale if the keys already exist.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "ios_app" / "ios_app"

# (key, en, hi, ta, te, kn, ml, es, fr, pt, de, ru, zh-Hans, ja)
ENTRIES = {
    "quota_fallback_overall_limit": {
        "en":      "You've reached your limit. Upgrade to continue your cosmic journey.",
        "hi":      "आपकी सीमा समाप्त हो गई है। अपनी ब्रह्मांडीय यात्रा जारी रखने के लिए अपग्रेड करें।",
        "ta":      "உங்கள் வரம்பை அடைந்துவிட்டீர்கள். உங்கள் பிரபஞ்சப் பயணத்தைத் தொடர மேம்படுத்துங்கள்.",
        "te":      "మీరు మీ పరిమితిని చేరుకున్నారు. మీ విశ్వ ప్రయాణాన్ని కొనసాగించడానికి అప్‌గ్రేడ్ చేయండి.",
        "kn":      "ನೀವು ನಿಮ್ಮ ಮಿತಿಯನ್ನು ತಲುಪಿದ್ದೀರಿ. ನಿಮ್ಮ ವಿಶ್ವ ಪ್ರಯಾಣವನ್ನು ಮುಂದುವರಿಸಲು ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ.",
        "ml":      "നിങ്ങൾ പരിധിയിലെത്തി. നിങ്ങളുടെ പ്രപഞ്ച യാത്ര തുടരാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക.",
        "es":      "Has alcanzado tu límite. Mejora para continuar tu viaje cósmico.",
        "fr":      "Vous avez atteint votre limite. Passez à un plan supérieur pour poursuivre votre voyage cosmique.",
        "pt":      "Você atingiu seu limite. Faça upgrade para continuar sua jornada cósmica.",
        "de":      "Sie haben Ihr Limit erreicht. Führen Sie ein Upgrade durch, um Ihre kosmische Reise fortzusetzen.",
        "ru":      "Вы достигли своего лимита. Перейдите на более высокий план, чтобы продолжить космическое путешествие.",
        "zh-Hans": "您已达到上限。升级以继续您的宇宙之旅。",
        "ja":      "上限に達しました。宇宙の旅を続けるにはアップグレードしてください。",
    },
    "quota_fallback_daily_limit": {
        "en":      "You've been busy today! Come back tomorrow at 12:00 AM UTC, or upgrade for higher limits.",
        "hi":      "आज आप बहुत व्यस्त रहे! कल UTC रात 12:00 बजे वापस आएं, या उच्च सीमा के लिए अपग्रेड करें।",
        "ta":      "இன்று நீங்கள் மிகவும் பணிமிகுந்திருந்தீர்கள்! நாளை UTC இரவு 12:00 மணிக்கு திரும்பவும், அல்லது அதிக வரம்புகளுக்கு மேம்படுத்துங்கள்.",
        "te":      "ఈరోజు మీరు చాలా బిజీగా ఉన్నారు! రేపు UTC అర్ధరాత్రి 12:00 గంటలకు తిరిగి రండి, లేదా ఎక్కువ పరిమితుల కోసం అప్‌గ్రేడ్ చేయండి.",
        "kn":      "ಇಂದು ನೀವು ತುಂಬಾ ಬ್ಯುಸಿಯಾಗಿದ್ದೀರಿ! ನಾಳೆ UTC ಮಧ್ಯರಾತ್ರಿ 12:00 ಕ್ಕೆ ಹಿಂತಿರುಗಿ, ಅಥವಾ ಹೆಚ್ಚಿನ ಮಿತಿಗಳಿಗಾಗಿ ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ.",
        "ml":      "ഇന്ന് നിങ്ങൾ വളരെ തിരക്കിലായിരുന്നു! നാളെ UTC അർദ്ധരാത്രി 12:00 മണിക്ക് മടങ്ങിവരൂ, അല്ലെങ്കിൽ ഉയർന്ന പരിധികൾക്കായി അപ്‌ഗ്രേഡ് ചെയ്യുക.",
        "es":      "¡Has estado ocupado hoy! Vuelve mañana a las 12:00 AM UTC o mejora para obtener límites más altos.",
        "fr":      "Vous avez été bien occupé aujourd'hui ! Revenez demain à minuit UTC, ou passez à un plan supérieur pour des limites plus élevées.",
        "pt":      "Você esteve ocupado hoje! Volte amanhã à meia-noite UTC, ou faça upgrade para limites maiores.",
        "de":      "Sie waren heute fleißig! Kommen Sie morgen um 0:00 Uhr UTC zurück oder upgraden Sie für höhere Limits.",
        "ru":      "Вы были заняты сегодня! Возвращайтесь завтра в 00:00 UTC или перейдите на более высокий план для увеличения лимитов.",
        "zh-Hans": "您今天很忙！请明天 UTC 凌晨 12:00 再来,或升级以获得更高的限额。",
        "ja":      "今日はお忙しかったですね!明日 UTC 午前 0:00 に再度ご利用いただくか、より高い上限のためにアップグレードしてください。",
    },
    "quota_fallback_fair_use": {
        "en":      "Fair use violation. Your usage has been restricted. Please contact support@destinyaiastrology.com for assistance.",
        "hi":      "उचित उपयोग का उल्लंघन। आपके उपयोग पर प्रतिबंध लगा दिया गया है। सहायता के लिए कृपया support@destinyaiastrology.com से संपर्क करें।",
        "ta":      "நியாயமான பயன்பாட்டு மீறல். உங்கள் பயன்பாடு கட்டுப்படுத்தப்பட்டுள்ளது. உதவிக்கு support@destinyaiastrology.com ஐ தொடர்பு கொள்ளவும்.",
        "te":      "ఫెయిర్ యూస్ ఉల్లంఘన. మీ వినియోగం పరిమితం చేయబడింది. సహాయం కోసం దయచేసి support@destinyaiastrology.com ని సంప్రదించండి.",
        "kn":      "ನ್ಯಾಯಯುತ ಬಳಕೆಯ ಉಲ್ಲಂಘನೆ. ನಿಮ್ಮ ಬಳಕೆಯನ್ನು ನಿರ್ಬಂಧಿಸಲಾಗಿದೆ. ಸಹಾಯಕ್ಕಾಗಿ ದಯವಿಟ್ಟು support@destinyaiastrology.com ಅನ್ನು ಸಂಪರ್ಕಿಸಿ.",
        "ml":      "ഫെയർ യൂസ് ലംഘനം. നിങ്ങളുടെ ഉപയോഗം നിയന്ത്രിച്ചിരിക്കുന്നു. സഹായത്തിനായി ദയവായി support@destinyaiastrology.com നെ ബന്ധപ്പെടുക.",
        "es":      "Violación del uso justo. Tu uso ha sido restringido. Contacta con support@destinyaiastrology.com para obtener asistencia.",
        "fr":      "Violation de l'usage équitable. Votre utilisation a été restreinte. Veuillez contacter support@destinyaiastrology.com pour obtenir de l'aide.",
        "pt":      "Violação de uso justo. Seu uso foi restrito. Entre em contato com support@destinyaiastrology.com para obter assistência.",
        "de":      "Verstoß gegen die Fair-Use-Richtlinie. Ihre Nutzung wurde eingeschränkt. Wenden Sie sich für Hilfe bitte an support@destinyaiastrology.com.",
        "ru":      "Нарушение правил справедливого использования. Ваше использование было ограничено. Пожалуйста, свяжитесь с support@destinyaiastrology.com для получения помощи.",
        "zh-Hans": "公平使用违规。您的使用已受到限制。请联系 support@destinyaiastrology.com 获取帮助。",
        "ja":      "フェアユース違反。ご利用が制限されています。サポートが必要な場合は support@destinyaiastrology.com までお問い合わせください。",
    },
    "quota_fallback_default": {
        "en":      "Upgrade to unlock unlimited access.",
        "hi":      "असीमित पहुंच को अनलॉक करने के लिए अपग्रेड करें।",
        "ta":      "வரம்பற்ற அணுகலைத் திறக்க மேம்படுத்துங்கள்.",
        "te":      "అపరిమిత యాక్సెస్‌ను అన్‌లాక్ చేయడానికి అప్‌గ్రేడ్ చేయండి.",
        "kn":      "ಅನಿಯಮಿತ ಪ್ರವೇಶವನ್ನು ಅನ್‌ಲಾಕ್ ಮಾಡಲು ಅಪ್‌ಗ್ರೇಡ್ ಮಾಡಿ.",
        "ml":      "പരിധിയില്ലാത്ത ആക്‌സസ് അൺലോക്ക് ചെയ്യാൻ അപ്‌ഗ്രേഡ് ചെയ്യുക.",
        "es":      "Mejora para desbloquear acceso ilimitado.",
        "fr":      "Passez à un plan supérieur pour débloquer un accès illimité.",
        "pt":      "Faça upgrade para desbloquear acesso ilimitado.",
        "de":      "Führen Sie ein Upgrade durch, um unbegrenzten Zugriff freizuschalten.",
        "ru":      "Перейдите на более высокий план, чтобы получить неограниченный доступ.",
        "zh-Hans": "升级以解锁无限访问。",
        "ja":      "アップグレードして無制限アクセスをアンロックしてください。",
    },
}

LOCALES = ["en", "hi", "ta", "te", "kn", "ml", "es", "fr", "pt", "de", "ru", "zh-Hans", "ja"]

def append_keys(locale: str) -> tuple[int, int]:
    """Returns (added, skipped) counts."""
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
        text += "\n// Quota fallback messages (iOS-11 fallback when backend message=null)\n"
        text += "\n".join(new_lines) + "\n"
        path.write_text(text, encoding="utf-8")
    return (added, skipped)

if __name__ == "__main__":
    print(f"{'Locale':10} {'Added':>6} {'Skipped':>8}")
    print("-" * 30)
    total_added = 0
    for loc in LOCALES:
        a, s = append_keys(loc)
        total_added += a
        print(f"{loc:10} {a:>6} {s:>8}")
    print("-" * 30)
    print(f"Total keys added: {total_added}")
