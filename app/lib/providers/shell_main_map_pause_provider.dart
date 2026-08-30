import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ref-count hold while a full-screen game feature (e.g. `GAME80001`) covers
/// the live map. The shell map [CtRegionMap] pauses its Flame engine when
/// hold > 0. Refs #4687.
class ShellMainMapPauseHold extends Notifier<int> {
  @override
  int build() => 0;

  void acquire() => state = state + 1;

  void release() {
    if (state <= 0) return;
    state = state - 1;
  }
}

final shellMainMapPauseHoldProvider =
    NotifierProvider<ShellMainMapPauseHold, int>(ShellMainMapPauseHold.new);
