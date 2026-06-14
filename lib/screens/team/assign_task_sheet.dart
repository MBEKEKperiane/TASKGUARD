import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/team/models/team_models.dart';
import '../../features/team/providers/team_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/member_avatar.dart';

enum AssignMode { share, assign }

/// Bottom sheet for sharing or assigning a task to team members.
///
/// Usage:
///   showAssignTaskSheet(context, taskId: '...', teamId: '...');
Future<void> showAssignTaskSheet(
  BuildContext context, {
  required String taskId,
  required String teamId,
  AssignMode mode = AssignMode.assign,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AssignTaskSheet(
      taskId: taskId,
      teamId: teamId,
      mode: mode,
    ),
  );
}

class AssignTaskSheet extends ConsumerStatefulWidget {
  final String taskId;
  final String teamId;
  final AssignMode mode;

  const AssignTaskSheet({
    super.key,
    required this.taskId,
    required this.teamId,
    required this.mode,
  });

  @override
  ConsumerState<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends ConsumerState<AssignTaskSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _selectedIds = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamProvider.notifier).loadMembers(widget.teamId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isShare => widget.mode == AssignMode.share;

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> members) {
    if (_query.isEmpty) return members;
    final q = _query.toLowerCase();
    return members
        .where((m) =>
            memberName(m).toLowerCase().contains(q) ||
            memberEmail(m).toLowerCase().contains(q))
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _submitting = true);

    final notifier = ref.read(teamProvider.notifier);
    bool ok;

    if (_isShare) {
      ok = await notifier.shareTask(
        widget.taskId,
        memberIds: _selectedIds.toList(),
        teamId: widget.teamId,
      );
    } else {
      ok = await notifier.assignTask(
        widget.taskId,
        _selectedIds.first,
      );
    }

    if (mounted) {
      setState(() => _submitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (_isShare ? 'Task shared successfully' : 'Task assigned successfully')
            : 'Failed — check your connection'),
        backgroundColor: ok ? AppColors.secondary : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final members = _filtered(teamState.membersOf(widget.teamId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text1 = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final text2 = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final divider = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final surface = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isShare ? 'Share Task' : 'Assign Task',
                      style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: text1),
                    ),
                  ),
                  if (_isShare)
                    Text('Select multiple',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: text2)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(fontSize: 14, color: text1),
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle:
                      GoogleFonts.inter(fontSize: 13, color: text2),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: text2),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divider),

            // Member list
            Expanded(
              child: teamState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : members.isEmpty
                      ? Center(
                          child: Text('No members found',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: text2)))
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: divider),
                          itemBuilder: (_, i) {
                            final m = members[i];
                            final id = memberId(m);
                            final selected = _selectedIds.contains(id);
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              leading:
                                  MemberAvatar(member: m, radius: 20),
                              title: Text(memberName(m),
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: text1)),
                              subtitle: Text(memberEmail(m),
                                  style: GoogleFonts.inter(
                                      fontSize: 11, color: text2)),
                              trailing: _isShare
                                  ? Checkbox(
                                      value: selected,
                                      activeColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      onChanged: (_) => setState(() {
                                        selected
                                            ? _selectedIds.remove(id)
                                            : _selectedIds.add(id);
                                      }),
                                    )
                                  : Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? AppColors.primary
                                              : const Color(0xFF94A3B8),
                                          width: 2,
                                        ),
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check_rounded,
                                              size: 14, color: Colors.white)
                                          : null,
                                    ),
                              onTap: () => setState(() {
                                if (_isShare) {
                                  selected
                                      ? _selectedIds.remove(id)
                                      : _selectedIds.add(id);
                                } else {
                                  _selectedIds
                                    ..clear()
                                    ..add(id);
                                }
                              }),
                            );
                          },
                        ),
            ),

            // Action button
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedIds.isEmpty
                          ? divider
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selectedIds.isEmpty || _submitting
                        ? null
                        : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(
                            _isShare
                                ? 'Share with ${_selectedIds.length} member${_selectedIds.length > 1 ? "s" : ""}'
                                : 'Assign',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
