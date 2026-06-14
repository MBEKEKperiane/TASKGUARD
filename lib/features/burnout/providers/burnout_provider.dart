import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/burnout_detector.dart';
import '../models/burnout_result.dart';

class BurnoutNotifier extends StateNotifier<BurnoutResult?> {
  BurnoutNotifier() : super(null);

  Future<void> analyze() async {
    final result = await BurnoutDetector.analyze();
    if (mounted) state = result;
  }
}

final burnoutProvider =
    StateNotifierProvider<BurnoutNotifier, BurnoutResult?>(
  (_) => BurnoutNotifier(),
);
