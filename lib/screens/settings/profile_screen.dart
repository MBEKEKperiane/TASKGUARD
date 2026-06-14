import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/mood/models/mood_entry.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage.dart';
import '../../services/mood_storage.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  // Wellness fields
  String _strength = 'Beginner'; // Beginner / Intermediate / Advanced / Elite
  MoodType _mood = MoodType.happy;
  int _sleepHours = 7;

  static const _strengthOptions = ['Beginner', 'Intermediate', 'Advanced', 'Elite'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cached = LocalStorage.getUser();
    if (cached != null) {
      _nameCtrl.text = cached['name'] ?? '';
      _emailCtrl.text = cached['email'] ?? '';
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _strength = prefs.getString('wellness_strength') ?? 'Beginner';
      _mood = MoodTypeX.fromStorage(
          prefs.getString('wellness_mood') ?? MoodType.happy.storageKey);
      _sleepHours = prefs.getInt('wellness_sleep') ?? 7;
      _loading = false;
    });

    try {
      final user = await AuthService().getMe();
      await LocalStorage.saveUser(user);
      if (mounted) {
        setState(() {
          _nameCtrl.text = user['name'] ?? '';
          _emailCtrl.text = user['email'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name cannot be empty.'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('wellness_strength', _strength),
        MoodStorage.save(_mood),
        prefs.setInt('wellness_sleep', _sleepHours),
      ]);

      final res = await ApiClient().patch('/auth/me', data: {'name': name});
      final updated = res.data['user'] as Map<String, dynamic>;
      await LocalStorage.saveUser(updated);

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile saved.'),
              backgroundColor: AppColors.primary),
        );
      }
    } catch (_) {
      // Save wellness locally even if server fails
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wellness_strength', _strength);
        await MoodStorage.save(_mood);
        await prefs.setInt('wellness_sleep', _sleepHours);
      } catch (_) {}
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Saved offline — will sync when connected.'),
              backgroundColor: AppColors.primary),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colBg,
      appBar: AppBar(
        backgroundColor: context.colSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Profile',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : Text('Save',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Account ──────────────────────────────────────────────
                  _sectionLabel('Account'),
                  const SizedBox(height: 12),
                  _textField('Full Name', _nameCtrl,
                      icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _textField('Email Address', _emailCtrl,
                      icon: Icons.mail_outline_rounded, readOnly: true),
                  const SizedBox(height: 6),
                  Text('Email cannot be changed.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: context.colHint)),

                  const SizedBox(height: 28),

                  // ── Wellness ─────────────────────────────────────────────
                  _sectionLabel('Wellness'),
                  const SizedBox(height: 12),

                  // Strength level
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.fitness_center_outlined,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Strength Level',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colText1)),
                        ]),
                        const SizedBox(height: 14),
                        Row(
                          children: _strengthOptions.map((opt) {
                            final selected = _strength == opt;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _strength = opt),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : context.colSurfaceVar,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(opt,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : context.colText2)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mood
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.mood_outlined,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Current Mood',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colText1)),
                        ]),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.6,
                          children: MoodType.values.map((m) {
                            final selected = _mood == m;
                            final c = m.color;
                            return GestureDetector(
                              onTap: () => setState(() => _mood = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? c.withValues(alpha: 0.12)
                                      : context.colCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? c : context.colDivider,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(m.emoji,
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(m.label,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? c
                                                  : context.colText1)),
                                    ),
                                    if (selected)
                                      Icon(Icons.check_circle_rounded,
                                          color: c, size: 15),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sleep hours
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.bedtime_outlined,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Sleep Hours',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.colText1)),
                          const Spacer(),
                          Text('$_sleepHours hrs',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor:
                                context.colPrimaryC,
                            thumbColor: AppColors.primary,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.12),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _sleepHours.toDouble(),
                            min: 3,
                            max: 12,
                            divisions: 9,
                            onChanged: (v) =>
                                setState(() => _sleepHours = v.round()),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('3h',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: context.colHint)),
                            Text('12h',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: context.colHint)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Sign out
                  Center(
                    child: TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.primary, size: 18),
                      label: Text('Sign Out',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.colHint,
            letterSpacing: 0.8),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: child,
      );

  Widget _textField(String label, TextEditingController ctrl,
      {required IconData icon, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colText2)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? context.colSurfaceVar : context.colCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colDivider),
          ),
          child: TextField(
            controller: ctrl,
            readOnly: readOnly,
            style: GoogleFonts.inter(
                fontSize: 14, color: context.colText1),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: context.colHint, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
