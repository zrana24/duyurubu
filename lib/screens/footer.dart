import 'package:flutter/material.dart';
import 'management.dart';
import 'connect.dart';
import 'settings.dart';

class AppFooter extends StatelessWidget {
  final String activeTab;

  const AppFooter({Key? key, required this.activeTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                label: "YÖNETİM",
                isActive: activeTab == "YÖNETİM",
                onTap: () {
                  if (activeTab != "YÖNETİM") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Management()),
                    );
                  }
                },
              ),
              buildNavItem(
                context,
                icon: Icons.link,
                label: "BAĞLANTI",
                isActive: activeTab == "BAĞLANTI",
                onTap: () {
                  if (activeTab != "BAĞLANTI") {
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
                label: "AYARLAR",
                isActive: activeTab == "AYARLAR",
                onTap: () {
                  if (activeTab != "AYARLAR") {
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
