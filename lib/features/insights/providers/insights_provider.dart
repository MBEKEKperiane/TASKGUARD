import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/insights_service.dart';
import '../../../services/local_insights_engine.dart';
import '../models/insights_data.dart';

class InsightsNotifier extends StateNotifier<InsightsData> {
  InsightsNotifier() : super(InsightsData.loading);

  Future<void> load() async {
    // 1. Compute immediately from local storage — always available offline.
    final local = LocalInsightsEngine.compute();
    state = local;

    // 2. Optionally enrich weekly breakdown from server.
    try {
      final weekly = await InsightsService().getWeeklyInsights();
      if (mounted) {
        state = LocalInsightsEngine.mergeServerWeekly(local, weekly);
      }
    } catch (_) {
      // Keep local data — server is optional.
    }
  }
}

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsData>(
  (_) => InsightsNotifier(),
);
