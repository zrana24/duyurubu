import 'package:flutter/material.dart';
import 'management.dart';
import 'connect.dart';
import 'settings.dart';
import 'package:provider/provider.dart';
import '../language.dart';

class AppFooter extends StatelessWidget {
  final String activeTab;

  const AppFooter({Key? key, required this.activeTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: screenHeight * 0.11,
          color: const Color(0xFF263238),
          child: Row(
            children: [
              buildNavItem(
                context,
                icon: Icons.manage_accounts,
                label: languageProvider.getTranslation('management'),
                isActive: activeTab == "management",
                onTap: () {
                  if (activeTab != "management") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Management()),
                    );
                  }
                },
              ),
              buildNavItem(
                context,
                icon: Icons.link,
                label: languageProvider.getTranslation('connection'),
                isActive: activeTab == "connection",
                onTap: () {
                  if (activeTab != "connection") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => ConnectPage()),
                    );
                  }
                },
              ),
              buildNavItem(
                context,
                icon: Icons.settings,
                label: languageProvider.getTranslation('settings'),
                isActive: activeTab == "settings",
                onTap: () {
                  if (activeTab != "settings") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsPage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFF263238),
          child: Center(
            child: Image.asset(
              "assets/images/footer.png",
              fit: BoxFit.fitHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildNavItem(BuildContext context,
      {required IconData icon,
        required String label,
        bool isActive = false,
        VoidCallback? onTap}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: isActive ? const Color(0xFF37474F) : const Color(0xFF263238),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.06,
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.030,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}