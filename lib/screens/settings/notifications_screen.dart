import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
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
        title: Text(t.notifications,
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
            _sectionLabel(t.pushNotifications),
            _tile(t.enablePushNotifications, t.masterToggleAllAlerts,
                _pushEnabled, (v) => setState(() => _pushEnabled = v)),
            _tile(t.taskReminders, t.getRemindedBeforeDue,
                _taskReminders,
                (v) => setState(() => _taskReminders = v),
                enabled: _pushEnabled),
            _tile(t.focusSessionAlerts, t.timerStartEndNotifications,
                _focusAlerts,
                (v) => setState(() => _focusAlerts = v),
                enabled: _pushEnabled),
            _tile(t.burnoutWarnings, t.aiWellnessOverloadAlerts,
                _burnoutAlerts,
                (v) => setState(() => _burnoutAlerts = v),
                enabled: _pushEnabled),
            const SizedBox(height: 20),
            _sectionLabel(t.alarmSound),
            _actionTile(
              icon: Icons.music_note_rounded,
              title: t.changeAlarmRingtone,
              subtitle: t.chooseAlarmSound,
              onTap: () => _showRingtoneInstructions(context),
            ),
            const SizedBox(height: 20),
            _sectionLabel(t.summaries),
            _tile(t.dailySummary, t.morningBriefing,
                _dailySummary,
                (v) => setState(() => _dailySummary = v)),
            _tile(t.emailDigest, t.weeklyReportViaEmail,
                _emailDigest,
                (v) => setState(() => _emailDigest = v)),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(t.notificationPreferencesSaved),
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
                child: Text(t.savePreferences,
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
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.changeAlarmSound,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.followStepsOnPhone,
                style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
            const SizedBox(height: 12),
            ...[
              t.ringtoneStep1,
              t.ringtoneStep2,
              t.ringtoneStep3,
              t.ringtoneStep4,
              t.ringtoneStep5,
            ].map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(step,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colText1)),
                )),
            const SizedBox(height: 8),
            Text(t.checkAlarmVolumeNotMuted,
                style: GoogleFonts.inter(fontSize: 12, color: context.colHint)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.gotIt,
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
