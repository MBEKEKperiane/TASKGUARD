import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bottom_nav_shell.dart';
import '../../widgets/responsive_layout.dart';

enum _Step { email, code, newPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _resetSessionToken;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError(AppLocalizations.of(context).enterEmailAndPassword);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).sendPasswordResetCode(email);
      if (mounted) {
        setState(() {
          _step = _Step.code;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).resetCodeSentCheckInbox),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(_extractMessage(e));
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _showError(AppLocalizations.of(context).enterSixDigitCode);
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await ref.read(authProvider.notifier).verifyPasswordResetCode(
            email: _emailCtrl.text.trim(),
            code: code,
          );
      if (mounted) {
        setState(() {
          _resetSessionToken = token;
          _step = _Step.newPassword;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(_extractMessage(e));
      }
    }
  }

  Future<void> _resetPassword() async {
    final t = AppLocalizations.of(context);
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;
    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError(t.fillAllFields);
      return;
    }
    if (newPass.length < 8) {
      _showError(t.passwordTooShort);
      return;
    }
    if (newPass != confirmPass) {
      _showError(t.passwordsDoNotMatch);
      return;
    }
    if (_resetSessionToken == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).completePasswordReset(
            resetSessionToken: _resetSessionToken!,
            newPassword: newPass,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const BottomNavShell(showLoginSuccessMessage: true),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(_extractMessage(e));
      }
    }
  }

  String _extractMessage(Object e) {
    final raw = e.toString();
    final match = RegExp(r'"error":"([^"]+)"').firstMatch(raw);
    if (match != null) return match.group(1)!;
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back_rounded,
                              color: context.colText1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: context.colPrimaryC,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.primary, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(t.resetPassword,
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
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
                      child: switch (_step) {
                        _Step.email => _emailStep(t),
                        _Step.code => _codeStep(t),
                        _Step.newPassword => _newPasswordStep(t),
                      },
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

  Widget _emailStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.enterEmailToReset,
            style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
        const SizedBox(height: 16),
        _label(t.emailAddress),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _sendCode(),
          decoration: InputDecoration(
            hintText: t.emailHint,
            prefixIcon: Icon(Icons.mail_outline_rounded,
                color: context.colHint, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _gradientButton(t.sendCode, onTap: _sendCode),
      ],
    );
  }

  Widget _codeStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.weSentCodeTo,
            style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
        const SizedBox(height: 4),
        Text(_emailCtrl.text.trim(),
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
        const SizedBox(height: 20),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _verifyCode(),
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
            color: context.colText1,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _gradientButton(t.verify, onTap: _verifyCode),
      ],
    );
  }

  Widget _newPasswordStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.chooseNewPasswordSubtitle,
            style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
        const SizedBox(height: 16),
        _label(t.newPassword),
        const SizedBox(height: 8),
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: context.colHint, size: 20),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureNew = !_obscureNew),
              child: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.colHint,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label(t.confirmPassword),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          onSubmitted: (_) => _resetPassword(),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: context.colHint, size: 20),
            suffixIcon: GestureDetector(
              onTap: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              child: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.colHint,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _gradientButton(t.resetPassword, onTap: _resetPassword),
      ],
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
        width: double.infinity,
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
