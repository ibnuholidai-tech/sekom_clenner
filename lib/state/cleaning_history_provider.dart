import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cleaning_history_service.dart';

class CleaningHistoryNotifier extends StateNotifier<List<CleaningRecord>> {
  CleaningHistoryNotifier() : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    state = await CleaningHistoryService.instance.load();
  }

  Future<void> append(CleaningRecord record) async {
    await CleaningHistoryService.instance.append(record);
    await refresh();
  }

  Future<void> clear() async {
    await CleaningHistoryService.instance.clear();
    state = const [];
  }
}

final cleaningHistoryProvider =
    StateNotifierProvider<CleaningHistoryNotifier, List<CleaningRecord>>(
      (ref) => CleaningHistoryNotifier(),
    );
