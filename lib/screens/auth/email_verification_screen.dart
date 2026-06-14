import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_shell.dart';
import '../../widgets/responsive_layout.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _checking = false;
  bool _resending = false;

  @override
  Widget build(BuildContext context) {
    // Navigate automatically when the user verifies from another device/tab
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BottomNavShell()),
          (_) => false,
        );
      }
    });

    final email = ref.watch(authProvider).userEmail ?? '';

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF0F7), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -60,
            child: _orb(180, AppColors.primary.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _orb(140, AppColors.primaryLight.withValues(alpha: 0.15)),
          ),
          SafeArea(
            child: ResponsiveLayout(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded,
                          color: AppColors.primary, size: 42),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify Your Email',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We sent a verification link to',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click the link in that email to activate your account,\nthen tap the button below.',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _checking
                        ? const CircularProgressIndicator(
                            color: AppColors.primary)
                        : _gradientButton(
                            "I've Verified — Open Dashboard",
                            onTap: _checkVerification,
                          ),
                    const SizedBox(height: 16),
                    _resending
                        ? const SizedBox(
                            height: 50,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2)))
                        : OutlinedButton.icon(
                            onPressed: _resendEmail,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: Text('Resend Verification Email',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Check your spam or junk folder if the email doesn't arrive within a few minutes.",
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: _logout,
                      child: Text(
                        'Use a different account',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() => _checking = true);
    await ref.read(authProvider.notifier).checkVerification();
    if (!mounted) return;
    setState(() => _checking = false);
    final status = ref.read(authProvider).status;
    if (status == AuthStatus.unverified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet — please check your inbox and spam folder.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _resending = true);
    try {
      await ref.read(authProvider.notifier).resendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resend email. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Widget _orb(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _gradientButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}
