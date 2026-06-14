import 'api_client.dart';

class InsightsService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> getWeeklyInsights() async {
    final res = await _api.get('/insights/weekly');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProductivityScore() async {
    final res = await _api.get('/insights/score');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPeakHours() async {
    final res = await _api.get('/insights/peak-hours');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMilestones() async {
    final res = await _api.get('/insights/milestones');
    return res.data as Map<String, dynamic>;
  }
}
