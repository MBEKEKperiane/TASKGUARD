import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/gamification_engine.dart';
import '../models/gamification_models.dart';

class GamificationNotifier extends StateNotifier<GamificationData> {
  GamificationNotifier() : super(const GamificationData()) {
    refresh();
  }

  void refresh() {
    state = GamificationEngine.load();
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationData>(
  (_) => GamificationNotifier(),
);
