import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/team/models/team_models.dart';
import '../../features/team/providers/team_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/member_avatar.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _inviting = false;
  final _inviteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = teamId(widget.team);
      ref.read(teamProvider.notifier)
        ..loadMembers(id)
        ..loadProgress(id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  String get _tid => teamId(widget.team);

  // ── Invite dialog ──────────────────────────────────────────────────────────

  void _showInviteDialog() {
    _inviteCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Invite Member',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        content: TextField(
          controller: _inviteCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 14, color: _text1(context)),
          decoration: InputDecoration(
            hintText: 'colleague@example.com',
            hintStyle:
                GoogleFonts.inter(fontSize: 13, color: _hint(context)),
            prefixIcon:
                Icon(Icons.email_outlined, size: 18, color: _hint(context)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
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
              final email = _inviteCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _inviting = true);
              final ok = await ref
                  .read(teamProvider.notifier)
                  .inviteMember(_tid, email);
              if (mounted) {
                setState(() => _inviting = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Invite sent to $email'
                      : 'Failed to send invite'),
                  backgroundColor:
                      ok ? AppColors.secondary : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text('Send Invite',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Remove member ──────────────────────────────────────────────────────────

  void _confirmRemove(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Member',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        content: Text(
            'Remove ${memberName(member)} from ${teamName(widget.team)}?',
            style: GoogleFonts.inter(
                fontSize: 14, color: _text2(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: _hint(context))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(teamProvider.notifier)
                  .removeMember(_tid, memberId(member));
            },
            child: Text('Remove',
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
    final members = state.membersOf(_tid);
    final progress = state.progressOf(_tid);
    final color = teamColor(_tid);
    final myRole = _myRole(state);
    final canInviteMembers = canInvite(myRole);

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
        title: Text(teamName(widget.team),
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _text1(context))),
        actions: [
          if (canInviteMembers)
            _inviting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary)),
                  )
                : IconButton(
                    icon: const Icon(Icons.person_add_rounded,
                        color: AppColors.primary, size: 22),
                    tooltip: 'Invite member',
                    onPressed: _showInviteDialog,
                  ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: color,
          labelColor: color,
          unselectedLabelColor: _hint(context),
          labelStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Progress'),
            Tab(text: 'Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ProgressTab(
              team: widget.team, progress: progress, members: members),
          _MembersTab(
            members: members,
            myRole: myRole,
            onRemove: _confirmRemove,
          ),
        ],
      ),
    );
  }

  String _myRole(TeamState state) {
    final user = state.membersOf(_tid).firstWhere(
        (m) => m['isCurrentUser'] == true,
        orElse: () => <String, dynamic>{});
    return memberRole(user);
  }
}

// ── Progress tab ──────────────────────────────────────────────────────────────

class _ProgressTab extends StatelessWidget {
  final Map<String, dynamic> team;
  final Map<String, dynamic>? progress;
  final List<Map<String, dynamic>> members;

  const _ProgressTab({
    required this.team,
    required this.progress,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final color = teamColor(teamId(team));
    final rate = progress != null ? progressRate(progress!) : 0.0;
    final completed =
        progress != null ? progressCompleted(progress!) : 0;
    final total = progress != null ? progressTotal(progress!) : 0;
    final memberProgress =
        progress != null ? progressMembers(progress!) : <Map<String, dynamic>>[];
    final activity =
        progress != null ? progressActivity(progress!) : <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overall score card ─────────────────────────────────────────────
        _OverallCard(
          color: color,
          rate: rate,
          completed: completed,
          total: total,
          memberCount: members.length,
        ),
        const SizedBox(height: 20),

        // ── Per-member breakdown ───────────────────────────────────────────
        if (memberProgress.isNotEmpty) ...[
          _sectionHeader(context, 'Member Progress'),
          const SizedBox(height: 10),
          ...memberProgress
              .map((mp) => _MemberProgressRow(data: mp, members: members)),
          const SizedBox(height: 20),
        ],

        // ── Activity feed ──────────────────────────────────────────────────
        if (activity.isNotEmpty) ...[
          _sectionHeader(context, 'Recent Activity'),
          const SizedBox(height: 10),
          ...activity.map((a) => _ActivityTile(activity: a)),
        ],

        if (progress == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 48, color: _hint(context)),
                  const SizedBox(height: 12),
                  Text('No progress data yet',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: _text2(context))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _text1(context)));
}

class _OverallCard extends StatelessWidget {
  final Color color;
  final double rate;
  final int completed;
  final int total;
  final int memberCount;

  const _OverallCard({
    required this.color,
    required this.rate,
    required this.completed,
    required this.total,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Progress',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 4),
                    Text('$pct%',
                        style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Stat(icon: Icons.check_circle_outline_rounded,
                      label: '$completed done', dark: isDark),
                  const SizedBox(height: 6),
                  _Stat(icon: Icons.assignment_outlined,
                      label: '$total tasks', dark: isDark),
                  const SizedBox(height: 6),
                  _Stat(icon: Icons.group_rounded,
                      label: '$memberCount members', dark: isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;

  const _Stat({required this.icon, required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9))),
      ],
    );
  }
}

class _MemberProgressRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> members;

  const _MemberProgressRow({required this.data, required this.members});

  @override
  Widget build(BuildContext context) {
    final uid = data['memberId'] as String? ?? '';
    final name = data['name'] as String? ?? 'Unknown';
    final completed = (data['completed'] as num?)?.toInt() ?? 0;
    final assigned = (data['assigned'] as num?)?.toInt() ?? 0;
    final rate = (data['rate'] as num?)?.toDouble() ?? 0.0;

    final member = members.firstWhere(
        (m) => memberUserId(m) == uid || memberId(m) == uid,
        orElse: () => {'name': name});

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider(context)),
      ),
      child: Row(
        children: [
          MemberAvatar(member: member, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(name,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _text1(context))),
                    ),
                    Text('$completed/$assigned',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _hint(context))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: _divider(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColor(rate)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${(rate * 100).round()}%',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _progressColor(rate))),
        ],
      ),
    );
  }

  Color _progressColor(double rate) {
    if (rate >= 0.8) return AppColors.secondary;
    if (rate >= 0.5) return AppColors.warning;
    return AppColors.error;
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final name = activity['memberName'] as String? ?? '';
    final action = activity['action'] as String? ?? 'updated';
    final taskTitle = activity['taskTitle'] as String? ?? '';
    final atRaw = activity['at'] as String?;
    final member = <String, dynamic>{'name': name};

    String timeLabel = '';
    if (atRaw != null) {
      try {
        final dt = DateTime.parse(atRaw);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeLabel = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeLabel = '${diff.inHours}h ago';
        } else {
          timeLabel = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(member: member, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 13, color: _text2(context)),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A)),
                  ),
                  TextSpan(text: ' $action '),
                  TextSpan(
                    text: '"$taskTitle"',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(timeLabel,
              style:
                  GoogleFonts.inter(fontSize: 11, color: _hint(context))),
        ],
      ),
    );
  }
}

// ── Members tab ───────────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String myRole;
  final void Function(Map<String, dynamic>) onRemove;

  const _MembersTab({
    required this.members,
    required this.myRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 48, color: _hint(context)),
            const SizedBox(height: 12),
            Text('No members yet',
                style: GoogleFonts.inter(
                    fontSize: 14, color: _text2(context))),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: _divider(context)),
      itemBuilder: (_, i) {
        final m = members[i];
        final role = memberRole(m);
        final isMe = m['isCurrentUser'] == true;
        final canRemoveThis = canRemove(myRole) && !isMe && role != kRoleOwner;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          leading: MemberAvatar(member: m, radius: 22, showRoleDot: true),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  memberName(m) + (isMe ? ' (you)' : ''),
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _text1(context)),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor(role).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(roleLabel(role),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: roleColor(role))),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(memberEmail(m),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: _hint(context))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 12, color: AppColors.secondary),
                  const SizedBox(width: 3),
                  Text('${memberCompleted(m)} done',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _text2(context))),
                  const SizedBox(width: 10),
                  Icon(Icons.assignment_outlined,
                      size: 12, color: _hint(context)),
                  const SizedBox(width: 3),
                  Text('${memberAssigned(m)} assigned',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: _text2(context))),
                ],
              ),
            ],
          ),
          trailing: canRemoveThis
              ? IconButton(
                  icon: Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: () => onRemove(m),
                )
              : null,
        );
      },
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
