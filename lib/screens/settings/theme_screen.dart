import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/theme/providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);
    final t = AppLocalizations.of(context);

    final themes = [
      {
        'mode': AppThemeMode.light,
        'label': t.themeLight,
        'description': t.themeLightDesc,
        'icon': Icons.wb_sunny_outlined,
        'preview': <Color>[Colors.white, const Color(0xFFFFF0F7)],
      },
      {
        'mode': AppThemeMode.dark,
        'label': t.themeDark,
        'description': t.themeDarkDesc,
        'icon': Icons.nightlight_outlined,
        'preview': <Color>[
          const Color(0xFF0B0C1A),
          const Color(0xFF1A1B2E),
        ],
      },
      {
        'mode': AppThemeMode.pink,
        'label': t.themePink,
        'description': t.themePinkDesc,
        'icon': Icons.auto_awesome_outlined,
        'preview': <Color>[const Color(0xFFFCE4EC), AppColors.primary],
      },
    ];

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
        title: Text(t.theme,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colText1)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              t.tapThemeToApply,
              style: GoogleFonts.inter(fontSize: 13, color: context.colText2),
            ),
            const SizedBox(height: 16),
            ...themes.map((t) => _themeCard(context, ref, t, current)),
          ],
        ),
      ),
    );
  }

  Widget _themeCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> theme,
    AppThemeMode current,
  ) {
    final mode = theme['mode'] as AppThemeMode;
    final selected = current == mode;
    final colors = theme['preview'] as List<Color>;

    return GestureDetector(
      onTap: () => ref.read(themeProvider.notifier).set(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : context.colDivider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(theme['icon'] as IconData,
                  color:
                      selected ? AppColors.primary : context.colText2,
                  size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme['label'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colText1)),
                  const SizedBox(height: 3),
                  Text(theme['description'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: context.colText2)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 24),
            ),
          ],
        ),
      ),
    );
  }
}
