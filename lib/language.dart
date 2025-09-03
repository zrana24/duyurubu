import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr', 'TR');
  // Bu çeviriler, çeviri API'si arızalanırsa veya çevrimdışı kullanım için bir yedek görevi görür.
  final Map<String, Map<String, String>> _translations = {
    'tr': {'select_button': 'Seç'},
    'en': {'select_button': 'Select'},
    'ru': {'select_button': 'Выбрать'},
    'ar': {'select_button': 'اختر'},
  };

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  // Senkron kullanım için basit getter
  String getTranslation(String key) {
    return _translations[_locale.languageCode]?[key] ?? key;
  }
}

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<Map<String, String>> languages = [
    {'code': 'tr', 'name': 'TÜRKÇE', 'flag': '🇹🇷'},
    {'code': 'en', 'name': 'ENGLISH', 'flag': '🇺🇸'},
    {'code': 'ru', 'name': 'РУССКИЙ', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'اللغة العربية', 'flag': '🇸🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        title: Text(
          "Dil Seçenekleri",
          style: TextStyle(
            color: const Color(0xFF37474F),
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: const Color(0xFF4DB6AC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00695C)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.03,
          ),
          child: Column(
            children: languages.map((lang) {
              bool isSelected =
                  languageProvider.locale.languageCode == lang['code'];
              return GestureDetector(
                onTap: () {
                  languageProvider.setLocale(Locale(lang['code']!));
                },
                child: Container(
                  width: screenWidth * 0.9,
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFC5CAE9) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF37474F)
                          : const Color(0xFFC5CAE9),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang['flag']!,
                        style: TextStyle(fontSize: screenWidth * 0.06),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        decoration: const BoxDecoration(
          color: Color(0xFFE8EAF6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                final selectedLanguage = languages.firstWhere(
                      (lang) => lang['code'] == languageProvider.locale.languageCode,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${selectedLanguage['name']} seçildi."),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D8094),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.1,
                  vertical: screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    languageProvider.getTranslation('select_button'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
