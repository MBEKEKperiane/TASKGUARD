import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _aiTraining = false;
  bool _analytics = true;
  bool _crashReports = true;
  bool _dataExport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Privacy',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('AI & Data'),
            _tile(
              'AI Model Training',
              'Allow TaskGuard to use your data to improve AI responses',
              _aiTraining,
              (v) => setState(() => _aiTraining = v),
            ),
            _tile(
              'Usage Analytics',
              'Share anonymised usage data to improve the app',
              _analytics,
              (v) => setState(() => _analytics = v),
            ),
            _tile(
              'Crash Reports',
              'Automatically send crash logs to our team',
              _crashReports,
              (v) => setState(() => _crashReports = v),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Your Data'),
            _tile(
              'Data Export',
              'Include your data in periodic export packages',
              _dataExport,
              (v) => setState(() => _dataExport = v),
            ),
            const SizedBox(height: 8),
            _actionTile(
              icon: Icons.download_outlined,
              label: 'Export My Data',
              subtitle: 'Download all your tasks, sessions and insights',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Export requested. You\'ll receive an email shortly.'),
                    backgroundColor: AppColors.primary),
              ),
            ),
            const SizedBox(height: 4),
            _actionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete My Account',
              subtitle: 'Permanently remove all your data from TaskGuard',
              onTap: () => _confirmDelete(context),
              destructive: true,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Privacy settings saved.'),
                    backgroundColor: AppColors.primary),
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text('Save Settings',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
            'This will permanently delete all your data. This action cannot be undone.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.8)),
      );

  Widget _tile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(color: Colors.white),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primaryContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      leading: Icon(icon,
          color: destructive ? AppColors.error : AppColors.primary, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: destructive ? AppColors.error : AppColors.textPrimary)),
      subtitle: Text(subtitle,
          style:
              GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textHint, size: 20),
    );
  }
}
