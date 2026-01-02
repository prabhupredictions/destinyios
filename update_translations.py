import os

translations = {
    "es": """
// Match Result Additions
"ask_more_match" = "Preguntar más sobre esta pareja...";
"mangal_dosha" = "Mangal Dosha";
"mangal_dosha_desc" = "Análisis de posición de Marte";
"kalsarpa_dosha" = "Kalsarpa Dosha";
"kalsarpa_dosha_desc" = "Análisis del eje Rahu-Ketu";
"additional_yoga" = "Yoga y Dosha Adicional";
"additional_yoga_desc" = "Otras combinaciones auspiciosas";
"charts" = "Cartas";
"history" = "Historial";
"report" = "Informe";
""",
    "fr": """
// Match Result Additions
"ask_more_match" = "En savoir plus sur ce match...";
"mangal_dosha" = "Mangal Dosha";
"mangal_dosha_desc" = "Analyse de la position de Mars";
"kalsarpa_dosha" = "Kalsarpa Dosha";
"kalsarpa_dosha_desc" = "Analyse de l'axe Rahu-Ketu";
"additional_yoga" = "Yoga & Dosha Supplémentaire";
"additional_yoga_desc" = "Autres combinaisons auspicieuses";
"charts" = "Thèmes";
"history" = "Historique";
"report" = "Rapport";
""",
    "de": """
// Match Result Additions
"ask_more_match" = "Mehr über dieses Match fragen...";
"mangal_dosha" = "Mangal Dosha";
"mangal_dosha_desc" = "Mars-Positionsanalyse";
"kalsarpa_dosha" = "Kalsarpa Dosha";
"kalsarpa_dosha_desc" = "Rahu-Ketu-Achsenanalyse";
"additional_yoga" = "Zusätzliche Yoga & Dosha";
"additional_yoga_desc" = "Andere glückverheißende Kombinationen";
"charts" = "Charts";
"history" = "Verlauf";
"report" = "Bericht";
""",
    "pt": """
// Match Result Additions
"ask_more_match" = "Perguntar mais sobre este par...";
"mangal_dosha" = "Mangal Dosha";
"mangal_dosha_desc" = "Análise da posição de Marte";
"kalsarpa_dosha" = "Kalsarpa Dosha";
"kalsarpa_dosha_desc" = "Análise do eixo Rahu-Ketu";
"additional_yoga" = "Yoga e Dosha Adicional";
"additional_yoga_desc" = "Outras combinações auspiciosas";
"charts" = "Mapas";
"history" = "Histórico";
"report" = "Relatório";
""",
    "ru": """
// Match Result Additions
"ask_more_match" = "Спросить больше об этом совпадении...";
"mangal_dosha" = "Мангал Доша";
"mangal_dosha_desc" = "Анализ положения Марса";
"kalsarpa_dosha" = "Калсарпа Доша";
"kalsarpa_dosha_desc" = "Анализ оси Раху-Кету";
"additional_yoga" = "Дополнительные Йога и Доша";
"additional_yoga_desc" = "Другие благоприятные комбинации";
"charts" = "Карты";
"history" = "История";
"report" = "Отчет";
""",
    "ja": """
// Match Result Additions
"ask_more_match" = "このマッチについてもっと聞く...";
"mangal_dosha" = "マンガル・ドーシャ";
"mangal_dosha_desc" = "火星の位置分析";
"kalsarpa_dosha" = "カルサルパ・ドーシャ";
"kalsarpa_dosha_desc" = "ラーフ・ケートゥ軸分析";
"additional_yoga" = "追加のヨガとドーシャ";
"additional_yoga_desc" = "その他の吉祥な組み合わせ";
"charts" = "チャート";
"history" = "履歴";
"report" = "レポート";
""",
    "zh-Hans": """
// Match Result Additions
"ask_more_match" = "询问更多关于此配对...";
"mangal_dosha" = "曼格尔多沙";
"mangal_dosha_desc" = "火星位置分析";
"kalsarpa_dosha" = "卡尔萨帕多沙";
"kalsarpa_dosha_desc" = "罗睺-计都轴线分析";
"additional_yoga" = "其他瑜伽与多沙";
"additional_yoga_desc" = "其他吉利组合";
"charts" = "图表";
"history" = "历史";
"report" = "报告";
""",
    "ta": """
// Match Result Additions
"ask_more_match" = "இந்த பொருத்தம் பற்றி மேலும் கேட்க...";
"mangal_dosha" = "செவ்வாய் தோஷம்";
"mangal_dosha_desc" = "செவ்வாய் நிலை பகுப்பாய்வு";
"kalsarpa_dosha" = "கால சர்ப்ப தோஷம்";
"kalsarpa_dosha_desc" = "ராகு-கேது அச்சு பகுப்பாய்வு";
"additional_yoga" = "கூடுதல் யோகம் & தோஷம்";
"additional_yoga_desc" = "பிற மங்களகரமான சேர்க்கைகள்";
"charts" = "ஜாதகம்";
"history" = "வரலாறு";
"report" = "அறிக்கை";
""",
    "te": """
// Match Result Additions
"ask_more_match" = "ఈ మ్యాచ్ గురించి మరింత అడగండి...";
"mangal_dosha" = "కుజ దోషం";
"mangal_dosha_desc" = "కుజ గ్రహ విశ్లేషణ";
"kalsarpa_dosha" = "కాలసర్ప దోషం";
"kalsarpa_dosha_desc" = "రాహు-కేతు అక్షం విశ్లేషణ";
"additional_yoga" = "అదనపు యోగం & దోషం";
"additional_yoga_desc" = "ఇతర శుభ కలయికలు";
"charts" = "చార్ట్";
"history" = "చరిత్ర";
"report" = "నివేదిక";
""",
    "kn": """
// Match Result Additions
"ask_more_match" = "ಈ ಹೊಂದಾಣಿಕೆಯ ಬಗ್ಗೆ ಇನ್ನಷ್ಟು ಕೇಳಿ...";
"mangal_dosha" = "ಕುಜ ದೋಷ";
"mangal_dosha_desc" = "ಕುಜ ಗ್ರಹ ವಿಶ್ಲೇಷಣೆ";
"kalsarpa_dosha" = "ಕಾಲಸರ್ಪ ದೋಷ";
"kalsarpa_dosha_desc" = "ರಾಹು-ಕೇತು ಅಕ್ಷ ವಿಶ್ಲೇಷಣೆ";
"additional_yoga" = "ಹೆಚ್ಚುವರಿ ಯೋಗ ಮತ್ತು ದೋಷ";
"additional_yoga_desc" = "ಇತರೆ ಶುಭ ಸಂಯೋಜನೆಗಳು";
"charts" = "ಜಾತಕ";
"history" = "ಇತಿಹಾಸ";
"report" = "ವರದಿ";
""",
    "ml": """
// Match Result Additions
"ask_more_match" = "ഈ പൊരുത്തത്തെക്കുറിച്ച് കൂടുതൽ ചോദിക്കുക...";
"mangal_dosha" = "ചൊവ്വ ദോഷം";
"mangal_dosha_desc" = "ചൊവ്വ സ്ഥാനം വിശകലനം";
"kalsarpa_dosha" = "കാളസര്പ്പ ദോഷം";
"kalsarpa_dosha_desc" = "രാഹു-കേതു വിശകലനം";
"additional_yoga" = "അധിക യോഗവും ദോഷവും";
"additional_yoga_desc" = "മറ്റ് ശുഭകരമായ യോഗങ്ങൾ";
"charts" = "ചാർട്ട്";
"history" = "ചരിത്രം";
"report" = "റിപ്പോർട്ട്";
"""
}

base_dir = "/Users/i074917/Documents/destiny_ai_astrology/ios_app/ios_app"

for lang, content in translations.items():
    path = os.path.join(base_dir, f"{lang}.lproj", "Localizable.strings")
    if os.path.exists(path):
        print(f"Updating {lang}...")
        with open(path, "r") as f:
            lines = f.readlines()
        
        # Remove lines starting from Match Result Additions
        new_lines = []
        for line in lines:
            if "// Match Result Additions" in line:
                break
            new_lines.append(line)
            
        # Append new translated content
        with open(path, "w") as f:
            f.writelines(new_lines)
            f.write("\n")
            f.write(content.strip())
            f.write("\n")
            
print("All files updated.")
