import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import 'language_screen.dart';
import 'notifications_screen.dart';
import 'privacy_screen.dart';
import 'profile_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppHeader(onSettingsTap: () {}),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.colText1)),
            const SizedBox(height: 4),
            Text('Manage your preferences.',
                style:
                    GoogleFonts.inter(fontSize: 14, color: context.colText2)),
            const SizedBox(height: 28),
            _tile(
              context: context,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              subtitle: 'Alerts, email & push preferences',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
            ),
            _divider(context),
            _tile(
              context: context,
              icon: Icons.palette_outlined,
              label: 'Theme',
              subtitle: 'Light, dark & colour options',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ThemeScreen())),
            ),
            _divider(context),
            _tile(
              context: context,
              icon: Icons.language_outlined,
              label: 'Language',
              subtitle: 'App display language',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const LanguageScreen())),
            ),
            _divider(context),
            _tile(
              context: context,
              icon: Icons.shield_outlined,
              label: 'Privacy Settings',
              subtitle: 'Data security & AI training controls',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            ),
            _divider(context),
            _tile(
              context: context,
              icon: Icons.manage_accounts_outlined,
              label: 'Account Settings',
              subtitle: 'Profile, wellness & sign out',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colPrimaryC,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.colText1)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: context.colText2)),
      trailing:
          Icon(Icons.chevron_right_rounded, color: context.colHint, size: 22),
      onTap: onTap,
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(color: context.colDivider, height: 1);
}
