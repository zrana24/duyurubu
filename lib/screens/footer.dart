import 'package:flutter/material.dart';
import 'management.dart';
import 'connect.dart';
import 'settings.dart';
import 'package:provider/provider.dart';
import '../language.dart';
import 'info.dart';

class AppFooter extends StatefulWidget {
  final String activeTab;

  const AppFooter({Key? key, required this.activeTab}) : super(key: key);

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  bool showManagementSubmenu = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showManagementSubmenu)
          Container(
            height: screenHeight * 0.08,
            color: const Color(0xFF37474F),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Management()),
                      );
                    },
                    child: Container(
                      color: const Color(0xFF37474F),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.badge,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              languageProvider.getTranslation('name_screen_'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: screenHeight * 0.06,
                  color: const Color(0xFF263238),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const InfoScreen()),
                      );
                    },
                    child: Container(
                      color: const Color(0xFF37474F),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              languageProvider.getTranslation('info_screen_'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Ana menü
        Container(
          height: screenHeight * 0.11,
          color: const Color(0xFF263238),
          child: Row(
            children: [
              buildNavItem(
                context,
                icon: Icons.manage_accounts,
                label: languageProvider.getTranslation('management'),
                isActive: widget.activeTab == "management" || showManagementSubmenu,
                onTap: () {
                  setState(() {
                    showManagementSubmenu = !showManagementSubmenu;
                  });
                },
              ),
              buildNavItem(
                context,
                icon: Icons.link,
                label: languageProvider.getTranslation('connection'),
                isActive: widget.activeTab == "connection",
                onTap: () {
                  if (showManagementSubmenu) {
                    setState(() {
                      showManagementSubmenu = false;
                    });
                  }

                  if (widget.activeTab != "connection") {
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
                isActive: widget.activeTab == "settings",
                onTap: () {
                  if (showManagementSubmenu) {
                    setState(() {
                      showManagementSubmenu = false;
                    });
                  }

                  if (widget.activeTab != "settings") {
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