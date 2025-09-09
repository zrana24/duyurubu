import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../language.dart';
import 'footer.dart';
import 'package:provider/provider.dart';
import '../image.dart';
import '../bluetooth_provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _screenBrightness1 = 1.0;
  double _screenBrightness2 = 1.0;
  double _screenBrightness4 = 1.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bluetoothProvider = Provider.of<BluetoothProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: screenHeight * 0.10,
        flexibleSpace: Container(
          width: double.infinity,
          height: double.infinity,
          child: ImageWidget(
            fit: BoxFit.cover,
            showBluetoothStatus: true,
            connection: bluetoothProvider.connection,
            connectedDevice: bluetoothProvider.connectedDevice,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingCard(
                context,
                title: languageProvider.getTranslation('main_screen'),
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                brightnessValue: _screenBrightness1,
                onChanged: (value) {
                  setState(() {
                    _screenBrightness1 = value;
                  });
                },
                languageProvider: languageProvider,
              ),
              SizedBox(height: screenHeight * 0.01),

              _buildSettingCard(
                context,
                title: languageProvider.getTranslation('name_screen1'),
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                brightnessValue: _screenBrightness2,
                onChanged: (value) {
                  setState(() {
                    _screenBrightness2 = value;
                  });
                },
                languageProvider: languageProvider,
              ),
              SizedBox(height: screenHeight * 0.01),

              _buildSettingCard(
                context,
                title: languageProvider.getTranslation('info_screen'),
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                brightnessValue: _screenBrightness4,
                onChanged: (value) {
                  setState(() {
                    _screenBrightness4 = value;
                  });
                },
                languageProvider: languageProvider,
              ),
              SizedBox(height: screenHeight * 0.02),

              Container(
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                  color: const Color(0xFFB0BEC5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.language, color: Color(0xFF37474F)),
                  label: Text(
                    languageProvider.getTranslation('language_options'),
                    style: TextStyle(
                      color: Color(0xFF37474F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LanguagePage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppFooter(activeTab: "settings"),
    );
  }

  Widget _buildSettingCard(BuildContext context,
      {required String title,
        required double screenWidth,
        required double screenHeight,
        required double brightnessValue,
        required ValueChanged<double> onChanged,
        required LanguageProvider languageProvider}) {
    return Container(
      width: screenWidth * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC5CAE9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            width: screenWidth * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF4DB6AC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.devices_other, color: Color(0xFF00695C)),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00695C),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.getTranslation('screen_brightness'),
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Color(0xFF78909C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF4DB6AC),
                          inactiveTrackColor: const Color(0xFFB0BEC5),
                          thumbColor: const Color(0xFF00695C),
                          overlayColor: const Color(0x294DB6AC),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                        ),
                        child: Slider(
                          value: brightnessValue,
                          min: 0.0,
                          max: 1.0,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      "${(brightnessValue * 100).round()}%",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF37474F),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    const Icon(
                      Icons.light_mode,
                      color: Color(0xFF37474F),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}