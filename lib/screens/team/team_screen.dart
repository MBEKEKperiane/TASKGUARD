import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/team/models/team_models.dart';
import '../../features/team/providers/team_provider.dart';
import '../../theme/app_colors.dart';
import 'team_detail_screen.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Team',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(
              controller: nameCtrl,
              hint: 'Team name (e.g. Study Group)',
              context: context,
            ),
            const SizedBox(height: 12),
            _DialogField(
              controller: descCtrl,
              hint: 'Short description (optional)',
              context: context,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: _hint(context))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final team = await ref.read(teamProvider.notifier).createTeam(
                    name: name,
                    description: descCtrl.text.trim(),
                  );
              if (team != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TeamDetailScreen(team: team)),
                );
              }
            },
            child: Text('Create',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProvider);
    final badgeCount = state.pendingInviteCount;

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _text1(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Teams',
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.refresh_rounded,
                    color: AppColors.primary, size: 22),
            onPressed: state.isLoading
                ? null
                : () => ref.read(teamProvider.notifier).loadAll(),
          ),
          IconButton(
            icon: const Icon(Icons.group_add_rounded,
                color: AppColors.primary, size: 22),
            tooltip: 'Create team',
            onPressed: _showCreateDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: _hint(context),
          labelStyle: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            const Tab(text: 'My Teams'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Assigned'),
                  if (state.assignedTasks.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: state.assignedTasks.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Shared'),
                  if (state.sharedTasks.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _Badge(count: state.sharedTasks.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Invite banner
          if (badgeCount > 0)
            _InvitesBanner(
              invites: state.invites
                  .where(inviteIsPending)
                  .toList(),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _MyTeamsTab(teams: state.teams, isLoading: state.isLoading),
                _TaskListTab(
                  tasks: state.assignedTasks,
                  emptyIcon: Icons.assignment_ind_outlined,
                  emptyLabel: 'No tasks assigned to you',
                  label: 'Assigned to me',
                  teams: state.teams,
                ),
                _TaskListTab(
                  tasks: state.sharedTasks,
                  emptyIcon: Icons.share_outlined,
                  emptyLabel: 'No shared tasks yet',
                  label: 'Shared with me',
                  teams: state.teams,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invites banner ────────────────────────────────────────────────────────────

class _InvitesBanner extends ConsumerWidget {
  final List<Map<String, dynamic>> invites;

  const _InvitesBanner({required this.invites});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${invites.length} pending invite${invites.length > 1 ? "s" : ""}',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          ...invites.map((inv) => _InviteRow(invite: inv)),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerWidget {
  final Map<String, dynamic> invite;

  const _InviteRow({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(teamProvider.notifier);
    final id = inviteId(invite);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_rounded,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inviteTeamName(invite),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text1(context))),
                Text('Invited by ${inviterName(invite)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _hint(context))),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => notifier.declineInvite(id),
            child: Text('Decline',
                style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => notifier.acceptInvite(id),
            child: Text('Join',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── My Teams tab ──────────────────────────────────────────────────────────────

class _MyTeamsTab extends StatelessWidget {
  final List<Map<String, dynamic>> teams;
  final bool isLoading;

  const _MyTeamsTab({required this.teams, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading && teams.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2.5));
    }

    if (teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 56, color: _hint(context)),
            const SizedBox(height: 16),
            Text('No teams yet',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _text1(context))),
            const SizedBox(height: 6),
            Text('Create or join a team to collaborate',
                style: GoogleFonts.inter(
                    fontSize: 13, color: _text2(context))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      itemBuilder: (_, i) => _TeamCard(team: teams[i]),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final tid = teamId(team);
    final color = teamColor(tid);
    final rate = teamCompletionRate(team);
    final memberCount = teamMemberCount(team);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Team avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    teamName(team).isNotEmpty
                        ? teamName(team)[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teamName(team),
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _text1(context))),
                      if (teamDesc(team).isNotEmpty)
                        Text(teamDesc(team),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: _text2(context))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: _hint(context), size: 20),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rate.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: _divider(context),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.group_rounded,
                    size: 13, color: _hint(context)),
                const SizedBox(width: 4),
                Text('$memberCount member${memberCount != 1 ? "s" : ""}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: _text2(context))),
                const Spacer(),
                Text('${(rate * 100).round()}% complete',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assigned / Shared task list tab ──────────────────────────────────────────

class _TaskListTab extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final IconData emptyIcon;
  final String emptyLabel;
  final String label;
  final List<Map<String, dynamic>> teams;

  const _TaskListTab({
    required this.tasks,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.label,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: _hint(context)),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: GoogleFonts.inter(
                    fontSize: 14, color: _text2(context))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _CollabTaskCard(task: tasks[i], teams: teams),
    );
  }
}

class _CollabTaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final List<Map<String, dynamic>> teams;

  const _CollabTaskCard({required this.task, required this.teams});

  @override
  Widget build(BuildContext context) {
    final title = task['title'] as String? ?? 'Untitled';
    final priority =
        (task['priority'] as String?)?.toUpperCase() ?? 'MEDIUM';
    final isCompleted = task['isCompleted'] == true;
    final assigneeName = taskAssigneeName(task);
    final ownerName = taskOwnerName(task);
    final teamId_ = task['teamId'] as String?;
    final teamMap = teamId_ != null
        ? teams.firstWhere((t) => t['id'] == teamId_,
            orElse: () => <String, dynamic>{})
        : null;
    final color = teamMap != null && teamId_ != null
        ? teamColor(teamId_)
        : _hint(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider(context)),
      ),
      child: Row(
        children: [
          // Priority strip
          Container(
            width: 3,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _priorityColor(priority),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? _hint(context)
                            : _text1(context),
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (assigneeName.isNotEmpty) ...[
                      Icon(Icons.person_outline_rounded,
                          size: 12, color: _hint(context)),
                      const SizedBox(width: 3),
                      Text(assigneeName,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _text2(context))),
                      const SizedBox(width: 8),
                    ],
                    if (ownerName.isNotEmpty) ...[
                      Icon(Icons.shield_outlined,
                          size: 12, color: _hint(context)),
                      const SizedBox(width: 3),
                      Text('by $ownerName',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: _hint(context))),
                    ],
                  ],
                ),
                if (teamMap != null && teamMap.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(teamName(teamMap),
                          style: GoogleFonts.inter(
                              fontSize: 10, color: color)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Status indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.secondary.withValues(alpha: 0.12)
                  : _priorityColor(priority).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCompleted ? 'Done' : priority,
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isCompleted
                      ? AppColors.secondary
                      : _priorityColor(priority)),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) {
        'URGENT' => const Color(0xFFDC2626),
        'HIGH' => AppColors.priorityHigh,
        'MEDIUM' => AppColors.priorityMedium,
        _ => AppColors.priorityLow,
      };
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8)),
      child: Text('$count',
          style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white)),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final BuildContext context;

  const _DialogField({
    required this.controller,
    required this.hint,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 14, color: _text1(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: _hint(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

// ── Theme helpers ─────────────────────────────────────────────────────────────

Color _bg(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
}

Color _card(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF1E293B) : Colors.white;
}

Color _text1(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
}

Color _text2(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
}

Color _hint(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
}

Color _divider(BuildContext ctx) {
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
}
