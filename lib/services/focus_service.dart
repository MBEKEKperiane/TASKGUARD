import 'api_client.dart';

class FocusService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> startSession({
    int plannedMins = 25,
    String? taskTitle,
  }) async {
    final res = await _api.post('/focus/start', data: {
      'plannedMins': plannedMins,
      if (taskTitle != null) 'taskTitle': taskTitle,
    });
    return res.data['session'] as Map<String, dynamic>;
  }

  /// [actualMins] is the real focused time (planned minus any pause/early exit).
  Future<Map<String, dynamic>> endSession(
    String sessionId, {
    int? actualMins,
  }) async {
    final res = await _api.patch(
      '/focus/$sessionId/end',
      data: {if (actualMins != null) 'actualMins': actualMins},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSessions({int limit = 20}) async {
    final res = await _api.get('/focus/sessions', params: {'limit': limit});
    return res.data['sessions'] as List;
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get('/focus/stats');
    return res.data as Map<String, dynamic>;
  }
}
