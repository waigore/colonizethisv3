import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub provider for offline action queue (multiplayer). Phase 0: MVP has no backend.
class OfflineQueueNotifier extends Notifier<List<Object?>> {
  @override
  List<Object?> build() => const [];

  void enqueueAll(List<Object?> actions) {
    state = [...state, ...actions];
  }

  void dropFirst() {
    if (state.isEmpty) return;
    state = state.skip(1).toList();
  }

  void clear() {
    state = const [];
  }
}

final offlineQueueProvider =
    NotifierProvider<OfflineQueueNotifier, List<Object?>>(
      OfflineQueueNotifier.new,
    );
