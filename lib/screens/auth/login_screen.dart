import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/models/auth_state.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_shell.dart';
import '../../widgets/responsive_layout.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscure = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BottomNavShell()),
          (_) => false,
        );
      } else if (next.status == AuthStatus.unverified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const EmailVerificationScreen()),
          (_) => false,
        );
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final isLoading =
        ref.watch(authProvider).status == AuthStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: context.colAuthGradient),
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
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.colPrimaryC,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: AppColors.primary, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text('TaskGuard AI',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(t.stressFreePrecision,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: context.colText2)),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.colCard,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(t.emailAddress),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: t.emailHint,
                              prefixIcon: Icon(Icons.mail_outline_rounded,
                                  color: context.colHint, size: 20),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _label(t.password),
                              TextButton(
                                onPressed: _forgotPassword,
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap),
                                child: Text(t.forgotPassword,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: context.colHint,
                                  size: 20),
                              suffixIcon: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: context.colHint,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary))
                              : _gradientButton(t.logIn, onTap: _login),
                          const SizedBox(height: 20),
                          Row(children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(t.or,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: context.colHint,
                                      fontWeight: FontWeight.w500)),
                            ),
                            const Expanded(child: Divider()),
                          ]),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: isLoading ? null : _googleLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.colText1,
                              side:
                                  BorderSide(color: context.colDivider),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.g_mobiledata,
                                  size: 16, color: Colors.black54),
                            ),
                            label: Text(t.continueWithGoogle,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.newHere,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: context.colText2)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(t.signUp,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 14, color: context.colHint),
                        const SizedBox(width: 5),
                        Text(t.securedByEncryption,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: context.colHint)),
                      ],
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

  void _login() {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).enterEmailAndPassword),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    ref.read(authProvider.notifier).login(email: email, password: password);
  }

  void _googleLogin() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.colText2));

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
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}
