import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/gamification/models/gamification_models.dart';
import '../../features/gamification/providers/gamification_provider.dart';
import '../../theme/app_colors.dart';

// ── Theme helpers ──────────────────────────────────────────────────────────────
Color _bg(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF0F172A)
    : const Color(0xFFF8FAFC);
Color _card(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF1E293B)
    : Colors.white;
Color _text1(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFFF1F5F9)
    : const Color(0xFF0F172A);
Color _text2(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF94A3B8)
    : const Color(0xFF475569);
Color _hint(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark
    ? const Color(0xFF475569)
    : const Color(0xFF94A3B8);
Color _divider(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

// ── Screen ─────────────────────────────────────────────────────────────────────

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gamificationProvider);
    final level = data.level;
    final levelColor = gamificationLevelColor(level);
    final earnedIds = data.earnedBadgeIds.toSet();
    final earnedCount = earnedIds.length;

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: _text1(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Achievements',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$earnedCount/${kAllBadges.length} badges',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _text2(context)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: _hint(context),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Badges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(data: data, levelColor: levelColor),
          _BadgesTab(data: data),
        ],
      ),
    );
  }
}

// ── Overview Tab ───────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final GamificationData data;
  final Color levelColor;

  const _OverviewTab({required this.data, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Level Card ──────────────────────────────────────────────────────
          _LevelCard(data: data, levelColor: levelColor),
          const SizedBox(height: 16),

          // ── Stats row ───────────────────────────────────────────────────────
          Row(children: [
            Expanded(
                child: _StatBox(
              icon: Icons.task_alt_rounded,
              value: '${data.totalTasksCompleted}',
              label: 'Tasks Done',
              color: AppColors.secondary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatBox(
              icon: Icons.timer_rounded,
              value: '${data.focusSessionsCompleted}',
              label: 'Focus Sessions',
              color: AppColors.primary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatBox(
              icon: Icons.emoji_events_rounded,
              value: '${data.earnedBadgeIds.length}',
              label: 'Badges',
              color: const Color(0xFFF59E0B),
            )),
          ]),
          const SizedBox(height: 16),

          // ── Streak card ─────────────────────────────────────────────────────
          _StreakCard(data: data),
          const SizedBox(height: 16),

          // ── Recent badges ───────────────────────────────────────────────────
          if (data.earnedBadgeIds.isNotEmpty) ...[
            Text('Recent Badges',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _text1(context))),
            const SizedBox(height: 10),
            _RecentBadges(earnedIds: data.earnedBadgeIds),
          ] else
            _EmptyBadges(),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final GamificationData data;
  final Color levelColor;

  const _LevelCard({required this.data, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final level = data.level;
    final label = gamificationLevelLabel(level);
    final progress = data.levelProgress;
    final xpToNext = data.xpToNextLevel;
    final isMax = level >= 10;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withValues(alpha: 0.18),
            levelColor.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: levelColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    levelColor.withValues(alpha: 0.25),
                    levelColor.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(color: levelColor, width: 2.5),
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: levelColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _text1(context))),
                  const SizedBox(height: 2),
                  Text('${data.xp} XP total',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: _text2(context))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: levelColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(levelColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMax
                ? '🏆 Maximum level reached!'
                : '$xpToNext XP to Level ${level + 1}',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: levelColor),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _text1(context))),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: _hint(context)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final GamificationData data;

  const _StreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    const streakColor = Color(0xFFF97316);
    final isActive = data.currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _divider(context)),
      ),
      child: Row(children: [
        // Flame icon
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: streakColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              isActive ? '🔥' : '💤',
              style: const TextStyle(fontSize: 26),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive
                    ? '${data.currentStreak}-Day Streak!'
                    : 'No Active Streak',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isActive ? streakColor : _text1(context)),
              ),
              const SizedBox(height: 3),
              Text(
                isActive
                    ? 'Complete a task today to keep it going'
                    : 'Complete a task to start a streak',
                style: GoogleFonts.inter(
                    fontSize: 12, color: _text2(context)),
              ),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${data.longestStreak}',
              style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: streakColor)),
          Text('best',
              style: GoogleFonts.inter(
                  fontSize: 10, color: _hint(context))),
        ]),
      ]),
    );
  }
}

class _RecentBadges extends StatelessWidget {
  final List<String> earnedIds;

  const _RecentBadges({required this.earnedIds});

  @override
  Widget build(BuildContext context) {
    final set = earnedIds.toSet();
    final earned = kAllBadges.where((b) => set.contains(b.id)).toList();
    final recent = earned.reversed.take(6).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: recent.map((b) => _BadgeChip(badge: b, earned: true)).toList(),
    );
  }
}

class _EmptyBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Column(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text('No badges yet',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _text1(context))),
          const SizedBox(height: 4),
          Text('Complete tasks to earn your first badge',
              style: GoogleFonts.inter(
                  fontSize: 13, color: _text2(context))),
        ],
      ),
    );
  }
}

// ── Badges Tab ─────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final GamificationData data;

  const _BadgesTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final earned = data.earnedBadgeIds.toSet();

    // Group badges by category
    final taskBadges =
        kAllBadges.where((b) => _isTaskBadge(b.id)).toList();
    final streakBadges =
        kAllBadges.where((b) => _isStreakBadge(b.id)).toList();
    final focusBadges =
        kAllBadges.where((b) => _isFocusBadge(b.id)).toList();
    final specialBadges =
        kAllBadges.where((b) => _isSpecialBadge(b.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BadgeSection(title: '📋 Tasks', badges: taskBadges, earned: earned),
          const SizedBox(height: 20),
          _BadgeSection(title: '🔥 Streaks', badges: streakBadges, earned: earned),
          const SizedBox(height: 20),
          _BadgeSection(title: '🎯 Focus', badges: focusBadges, earned: earned),
          const SizedBox(height: 20),
          _BadgeSection(title: '⭐ Special', badges: specialBadges, earned: earned),
        ],
      ),
    );
  }

  static bool _isTaskBadge(String id) => const {
        'first_step',
        'productive',
        'momentum',
        'task_crusher',
        'overachiever',
        'centurion',
        'elite',
        'legend_tasks',
      }.contains(id);

  static bool _isStreakBadge(String id) => const {
        'consistent',
        'hot_streak',
        'on_fire',
        'ironclad',
        'iron_will',
        'streak_legend',
      }.contains(id);

  static bool _isFocusBadge(String id) => const {
        'in_the_zone',
        'deep_worker',
        'flow_master',
      }.contains(id);

  static bool _isSpecialBadge(String id) => const {
        'early_bird',
        'night_owl',
        'rising_star',
        'master',
      }.contains(id);
}

class _BadgeSection extends StatelessWidget {
  final String title;
  final List<BadgeDef> badges;
  final Set<String> earned;

  const _BadgeSection({
    required this.title,
    required this.badges,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = badges.where((b) => earned.contains(b.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _text1(context))),
          const Spacer(),
          Text('$doneCount/${badges.length}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _hint(context))),
        ]),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: badges.length,
          itemBuilder: (_, i) {
            final b = badges[i];
            final isEarned = earned.contains(b.id);
            return _BadgeCell(badge: b, earned: isEarned);
          },
        ),
      ],
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final BadgeDef badge;
  final bool earned;

  const _BadgeCell({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final rarityColor = badge.rarity.color;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: earned
              ? rarityColor.withValues(alpha: 0.08)
              : _card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? rarityColor.withValues(alpha: 0.40)
                : _divider(context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji or lock
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 30,
                    color: earned ? null : Colors.transparent,
                  ),
                ),
                if (!earned)
                  Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 30,
                      foreground: Paint()
                        ..colorFilter = const ColorFilter.mode(
                            Color(0xFF94A3B8), BlendMode.srcIn),
                    ),
                  ),
                if (!earned)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              earned ? badge.name : '???',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: earned ? _text1(context) : _hint(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _BadgeDetailDialog(badge: badge, earned: earned),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeDef badge;
  final bool earned;

  const _BadgeChip({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final color = badge.rarity.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(badge.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(badge.name,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _text1(context))),
      ]),
    );
  }
}

class _BadgeDetailDialog extends StatelessWidget {
  final BadgeDef badge;
  final bool earned;

  const _BadgeDetailDialog({required this.badge, required this.earned});

  @override
  Widget build(BuildContext context) {
    final rarityColor = badge.rarity.color;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: _card(context),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: earned
                    ? rarityColor.withValues(alpha: 0.12)
                    : const Color(0xFF94A3B8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  earned ? badge.emoji : '🔒',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Name
            Text(badge.name,
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _text1(context))),
            const SizedBox(height: 6),

            // Description / requirement
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: _text2(context), height: 1.4),
            ),
            const SizedBox(height: 14),

            // Rarity + XP
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: badge.rarity.gradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge.rarity.label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              if (badge.xpReward > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: rarityColor.withValues(alpha: 0.35)),
                  ),
                  child: Text('+${badge.xpReward} XP',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rarityColor)),
                ),
              ],
            ]),
            const SizedBox(height: 8),

            // Status chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: earned
                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                    : _bg(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: earned
                      ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                      : _divider(context),
                ),
              ),
              child: Text(
                earned ? '✓  Earned' : 'Not yet earned',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: earned
                        ? const Color(0xFF22C55E)
                        : _hint(context)),
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _divider(context)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Close',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _text1(context))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
