import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/theme/providers/theme_provider.dart';
import 'services/local_storage.dart';
import 'services/local_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await LocalStorage.init();
  // flutter_local_notifications has no web support — skip on web
  if (!kIsWeb) await LocalNotificationService.init();

  // Read the persisted theme before the first frame so there is no flicker.
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString('app_theme_mode') ?? 'light';
  final initialTheme = AppThemeMode.values.firstWhere(
    (m) => m.name == savedMode,
    orElse: () => AppThemeMode.light,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(ProviderScope(
    overrides: [
      themeProvider.overrideWith((_) => ThemeNotifier(initialTheme)),
    ],
    child: const TaskGuardApp(),
  ));
}

class TaskGuardApp extends ConsumerWidget {
  const TaskGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appMode = ref.watch(themeProvider);

    // Keep status bar icon brightness in sync with the active theme.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: appMode == AppThemeMode.dark
          ? Brightness.light
          : Brightness.dark,
    ));

    return MaterialApp(
      title: 'TaskGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appMode.flutterMode,
      home: const SplashScreen(),
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        if (width <= 520) return child!;
        return Container(
          color: const Color(0xFFEDE7F3),
          child: Center(
            child: SizedBox(width: 520, child: child),
          ),
        );
      },
    );
  }
}
