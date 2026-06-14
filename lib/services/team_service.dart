import 'package:dio/dio.dart';
import 'local_storage.dart';
import 'api_client.dart';

/// Handles all team collaboration API calls with offline fallback.
///
/// Endpoint convention:
///   GET    /teams                          — list my teams
///   POST   /teams                          — create team
///   GET    /teams/:id                      — team detail
///   DELETE /teams/:id                      — delete team
///   GET    /teams/:id/members              — list members
///   POST   /teams/:id/invites              — invite by email
///   DELETE /teams/:id/members/:memberId    — remove member
///   GET    /teams/invites                  — my pending invites
///   POST   /teams/invites/:id/accept       — accept invite
///   POST   /teams/invites/:id/decline      — decline invite
///   POST   /tasks/:id/share               — share task with members
///   POST   /tasks/:id/assign              — assign task to one member
///   GET    /teams/:id/tasks               — all tasks in a team
///   GET    /tasks/assigned-to-me          — tasks assigned to me
///   GET    /tasks/shared-with-me          — tasks shared with me
///   GET    /teams/:id/progress            — team progress & activity
class TeamService {
  final _api = ApiClient();

  // ── Teams ──────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyTeams() async {
    try {
      final res = await _api.get('/teams');
      final teams = (res.data['teams'] as List).cast<Map<String, dynamic>>();
      await LocalStorage.saveTeams(teams);
      return teams;
    } on DioException {
      return LocalStorage.getTeams();
    }
  }

  Future<Map<String, dynamic>> createTeam({
    required String name,
    String description = '',
  }) async {
    final res = await _api.post('/teams', data: {
      'name': name,
      'description': description,
    });
    final team = res.data['team'] as Map<String, dynamic>;
    final cached = LocalStorage.getTeams();
    await LocalStorage.saveTeams([team, ...cached]);
    return team;
  }

  Future<Map<String, dynamic>> getTeam(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId');
      return res.data['team'] as Map<String, dynamic>;
    } on DioException {
      return LocalStorage.getTeams()
          .firstWhere((t) => t['id'] == teamId, orElse: () => {});
    }
  }

  Future<void> deleteTeam(String teamId) async {
    await _api.delete('/teams/$teamId');
    final cached = LocalStorage.getTeams()
        .where((t) => t['id'] != teamId)
        .toList();
    await LocalStorage.saveTeams(cached);
  }

  // ── Members ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembers(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId/members');
      final members =
          (res.data['members'] as List).cast<Map<String, dynamic>>();
      await LocalStorage.saveTeamMembers(teamId, members);
      return members;
    } on DioException {
      return LocalStorage.getTeamMembers(teamId);
    }
  }

  Future<void> inviteMember(String teamId, String email) async {
    await _api.post('/teams/$teamId/invites', data: {'email': email});
  }

  Future<void> removeMember(String teamId, String memberId) async {
    await _api.delete('/teams/$teamId/members/$memberId');
    final cached = LocalStorage.getTeamMembers(teamId)
        .where((m) => m['id'] != memberId)
        .toList();
    await LocalStorage.saveTeamMembers(teamId, cached);
  }

  // ── Invites ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMyInvites() async {
    try {
      final res = await _api.get('/teams/invites');
      final invites =
          (res.data['invites'] as List).cast<Map<String, dynamic>>();
      await LocalStorage.saveTeamInvites(invites);
      return invites;
    } on DioException {
      return LocalStorage.getTeamInvites();
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    await _api.post('/teams/invites/$inviteId/accept');
    _removeInvite(inviteId);
  }

  Future<void> declineInvite(String inviteId) async {
    await _api.post('/teams/invites/$inviteId/decline');
    _removeInvite(inviteId);
  }

  Future<void> _removeInvite(String inviteId) async {
    final cached = LocalStorage.getTeamInvites()
        .where((i) => i['id'] != inviteId)
        .toList();
    await LocalStorage.saveTeamInvites(cached);
  }

  // ── Task sharing & assignment ──────────────────────────────────────────────

  Future<Map<String, dynamic>> shareTask(
    String taskId, {
    required List<String> memberIds,
    String? teamId,
  }) async {
    final res = await _api.post('/tasks/$taskId/share', data: {
      'memberIds': memberIds,
      if (teamId != null) 'teamId': teamId,
    });
    return res.data['task'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> assignTask(
    String taskId,
    String assigneeId,
  ) async {
    final res = await _api.post('/tasks/$taskId/assign',
        data: {'assigneeId': assigneeId});
    return res.data['task'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getTeamTasks(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId/tasks');
      return (res.data['tasks'] as List).cast<Map<String, dynamic>>();
    } on DioException {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedToMe() async {
    try {
      final res = await _api.get('/tasks/assigned-to-me');
      final tasks =
          (res.data['tasks'] as List).cast<Map<String, dynamic>>();
      await LocalStorage.saveAssignedTasks(tasks);
      return tasks;
    } on DioException {
      return LocalStorage.getAssignedTasks();
    }
  }

  Future<List<Map<String, dynamic>>> getSharedWithMe() async {
    try {
      final res = await _api.get('/tasks/shared-with-me');
      final tasks =
          (res.data['tasks'] as List).cast<Map<String, dynamic>>();
      await LocalStorage.saveSharedTasks(tasks);
      return tasks;
    } on DioException {
      return LocalStorage.getSharedTasks();
    }
  }

  // ── Progress ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTeamProgress(String teamId) async {
    try {
      final res = await _api.get('/teams/$teamId/progress');
      final progress = res.data['progress'] as Map<String, dynamic>;
      await LocalStorage.saveTeamProgress(teamId, progress);
      return progress;
    } on DioException {
      return LocalStorage.getTeamProgress(teamId) ?? {};
    }
  }
}
