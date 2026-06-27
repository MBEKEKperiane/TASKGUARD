import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/locale/providers/locale_provider.dart';
import '../../theme/app_colors.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    ('English', 'en', '🇺🇸'),
    ('French', 'fr', '🇫🇷'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(localeProvider).languageCode;

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
        title: Text('Language',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Select your preferred language.',
              style: GoogleFonts.inter(fontSize: 13, color: context.colText2)),
          const SizedBox(height: 16),
          ..._languages.map((lang) {
            final (name, code, flag) = lang;
            final isSelected = selected == code;
            return GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).set(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.colCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : context.colDivider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colText1)),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
