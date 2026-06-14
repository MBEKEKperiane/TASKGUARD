import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushEnabled = true;
  bool _taskReminders = true;
  bool _focusAlerts = true;
  bool _dailySummary = false;
  bool _burnoutAlerts = true;
  bool _emailDigest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppBar(
        backgroundColor: context.colSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.colText1, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Push Notifications'),
            _tile('Enable Push Notifications', 'Master toggle for all alerts',
                _pushEnabled, (v) => setState(() => _pushEnabled = v)),
            _tile('Task Reminders', 'Get reminded before tasks are due',
                _taskReminders,
                (v) => setState(() => _taskReminders = v),
                enabled: _pushEnabled),
            _tile('Focus Session Alerts', 'Timer start and end notifications',
                _focusAlerts,
                (v) => setState(() => _focusAlerts = v),
                enabled: _pushEnabled),
            _tile('Burnout Warnings', 'AI wellness & overload alerts',
                _burnoutAlerts,
                (v) => setState(() => _burnoutAlerts = v),
                enabled: _pushEnabled),
            const SizedBox(height: 20),
            _sectionLabel('Alarm Sound'),
            _actionTile(
              icon: Icons.music_note_rounded,
              title: 'Change Alarm Ringtone',
              subtitle: 'Choose the sound that plays for task alarms',
              onTap: () => _showRingtoneInstructions(context),
            ),
            const SizedBox(height: 20),
            _sectionLabel('Summaries'),
            _tile('Daily Summary', 'Morning briefing of your day\'s plan',
                _dailySummary,
                (v) => setState(() => _dailySummary = v)),
            _tile('Email Digest', 'Weekly productivity report via email',
                _emailDigest,
                (v) => setState(() => _emailDigest = v)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Notification preferences saved.'),
                      backgroundColor: AppColors.primary),
                );
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text('Save Preferences',
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

  void _showRingtoneInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Alarm Sound',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Follow these steps on your phone:',
                style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
            const SizedBox(height: 12),
            ...[
              '1. Open phone Settings',
              '2. Go to Apps → TaskGuard AI',
              '3. Tap Notifications',
              '4. Tap "Task Alarms"',
              '5. Tap Sound and choose your ringtone',
            ].map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(step,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colText1)),
                )),
            const SizedBox(height: 8),
            Text('Also check that your Alarm volume is not muted (use volume buttons while an alarm plays).',
                style: GoogleFonts.inter(fontSize: 12, color: context.colHint)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',
                style: GoogleFonts.inter(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        color: context.colCard,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: context.colPrimaryC,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          title: Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.colText1)),
          subtitle: Text(subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: context.colText2)),
          trailing: Icon(Icons.chevron_right_rounded,
              color: context.colHint, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.colHint,
                letterSpacing: 0.8)),
      );

  Widget _tile(String title, String subtitle, bool value,
      ValueChanged<bool> onChanged,
      {bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: context.colCard),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: AppColors.primary,
        activeTrackColor: context.colPrimaryC,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? context.colText1 : context.colHint)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(
                fontSize: 12, color: context.colText2)),
      ),
    );
  }
}
