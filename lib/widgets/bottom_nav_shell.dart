import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/settings/profile_screen.dart';
import '../theme/app_colors.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    ChatScreen(),
    InsightsScreen(),
    ProfileScreen(),
  ];

  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.auto_awesome_outlined,
    Icons.bar_chart_rounded,
    Icons.person_outline_rounded,
  ];

  static const _activeIcons = [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.auto_awesome_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colSurface,
          boxShadow: [
            BoxShadow(
              color: context.isDark
                  ? const Color(0x40000000)
                  : const Color(0x12000000),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final active = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 64,
                    height: 60,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 46 : 32,
                        height: active ? 46 : 32,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          active ? _activeIcons[i] : _icons[i],
                          color: active ? Colors.white : context.colIcon,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
