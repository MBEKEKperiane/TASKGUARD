import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/team_service.dart';

class TeamState {
  final List<Map<String, dynamic>> teams;
  final Map<String, List<Map<String, dynamic>>> membersByTeam;
  final List<Map<String, dynamic>> invites;
  final Map<String, Map<String, dynamic>> progressByTeam;
  final List<Map<String, dynamic>> assignedTasks;
  final List<Map<String, dynamic>> sharedTasks;
  final bool isLoading;
  final String? selectedTeamId;
  final String? error;

  const TeamState({
    this.teams = const [],
    this.membersByTeam = const {},
    this.invites = const [],
    this.progressByTeam = const {},
    this.assignedTasks = const [],
    this.sharedTasks = const [],
    this.isLoading = false,
    this.selectedTeamId,
    this.error,
  });

  TeamState copyWith({
    List<Map<String, dynamic>>? teams,
    Map<String, List<Map<String, dynamic>>>? membersByTeam,
    List<Map<String, dynamic>>? invites,
    Map<String, Map<String, dynamic>>? progressByTeam,
    List<Map<String, dynamic>>? assignedTasks,
    List<Map<String, dynamic>>? sharedTasks,
    bool? isLoading,
    String? selectedTeamId,
    String? error,
  }) =>
      TeamState(
        teams: teams ?? this.teams,
        membersByTeam: membersByTeam ?? this.membersByTeam,
        invites: invites ?? this.invites,
        progressByTeam: progressByTeam ?? this.progressByTeam,
        assignedTasks: assignedTasks ?? this.assignedTasks,
        sharedTasks: sharedTasks ?? this.sharedTasks,
        isLoading: isLoading ?? this.isLoading,
        selectedTeamId: selectedTeamId ?? this.selectedTeamId,
        error: error,
      );

  int get pendingInviteCount =>
      invites.where((i) => i['status'] == 'pending').length;

  int get totalBadgeCount => pendingInviteCount + assignedTasks.length;

  List<Map<String, dynamic>> membersOf(String teamId) =>
      membersByTeam[teamId] ?? const [];

  Map<String, dynamic>? progressOf(String teamId) =>
      progressByTeam[teamId];
}

class TeamNotifier extends StateNotifier<TeamState> {
  final _service = TeamService();

  TeamNotifier() : super(const TeamState());

  // ── Load everything ────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _service.getMyTeams(),
        _service.getMyInvites(),
        _service.getAssignedToMe(),
        _service.getSharedWithMe(),
      ]);
      if (mounted) {
        state = state.copyWith(
          teams: results[0],
          invites: results[1],
          assignedTasks: results[2],
          sharedTasks: results[3],
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  // ── Teams ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> createTeam({
    required String name,
    String description = '',
  }) async {
    try {
      final team = await _service.createTeam(name: name, description: description);
      state = state.copyWith(teams: [team, ...state.teams]);
      return team;
    } catch (e) {
      if (mounted) state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> deleteTeam(String teamId) async {
    await _service.deleteTeam(teamId);
    state = state.copyWith(
      teams: state.teams.where((t) => t['id'] != teamId).toList(),
    );
  }

  void selectTeam(String? teamId) {
    state = state.copyWith(selectedTeamId: teamId);
  }

  // ── Members ────────────────────────────────────────────────────────────────

  Future<void> loadMembers(String teamId) async {
    final members = await _service.getMembers(teamId);
    if (mounted) {
      state = state.copyWith(
        membersByTeam: {...state.membersByTeam, teamId: members},
      );
    }
  }

  Future<bool> inviteMember(String teamId, String email) async {
    try {
      await _service.inviteMember(teamId, email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeMember(String teamId, String memberId) async {
    await _service.removeMember(teamId, memberId);
    final updated = (state.membersByTeam[teamId] ?? [])
        .where((m) => m['id'] != memberId)
        .toList();
    state = state.copyWith(
      membersByTeam: {...state.membersByTeam, teamId: updated},
    );
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  Future<void> acceptInvite(String inviteId) async {
    await _service.acceptInvite(inviteId);
    _removeInvite(inviteId);
    await loadAll();
  }

  Future<void> declineInvite(String inviteId) async {
    await _service.declineInvite(inviteId);
    _removeInvite(inviteId);
  }

  void _removeInvite(String inviteId) {
    state = state.copyWith(
      invites: state.invites.where((i) => i['id'] != inviteId).toList(),
    );
  }

  // ── Task sharing & assignment ──────────────────────────────────────────────

  Future<bool> shareTask(
    String taskId, {
    required List<String> memberIds,
    String? teamId,
  }) async {
    try {
      await _service.shareTask(taskId, memberIds: memberIds, teamId: teamId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignTask(String taskId, String assigneeId) async {
    try {
      await _service.assignTask(taskId, assigneeId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Progress ───────────────────────────────────────────────────────────────

  Future<void> loadProgress(String teamId) async {
    final progress = await _service.getTeamProgress(teamId);
    if (mounted) {
      state = state.copyWith(
        progressByTeam: {...state.progressByTeam, teamId: progress},
      );
    }
  }
}

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>(
  (_) => TeamNotifier(),
);
