import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sentinel label for player chrome while in global observe mode.
const String kObserveNotDefinedLabel = 'not defined';

enum ObserveMode { off, global, player }

/// Session-only observe state (not persisted). SPEC/ui/observe-mode.md.
class ObserveSessionState {
  const ObserveSessionState({
    this.mode = ObserveMode.off,
    this.observedPlayerId,
    this.priorHumanPlayerId,
    this.lastControlledPlayerId,
    this.controlBaseline,
  });

  final ObserveMode mode;
  final String? observedPlayerId;
  final String? priorHumanPlayerId;
  final String? lastControlledPlayerId;
  final ObserveControlBaseline? controlBaseline;

  bool get isObserving => mode != ObserveMode.off;

  ObserveSessionState copyWith({
    ObserveMode? mode,
    String? observedPlayerId,
    bool clearObservedPlayerId = false,
    String? priorHumanPlayerId,
    bool clearPriorHumanPlayerId = false,
    String? lastControlledPlayerId,
    ObserveControlBaseline? controlBaseline,
    bool clearControlBaseline = false,
  }) {
    return ObserveSessionState(
      mode: mode ?? this.mode,
      observedPlayerId: clearObservedPlayerId
          ? null
          : (observedPlayerId ?? this.observedPlayerId),
      priorHumanPlayerId: clearPriorHumanPlayerId
          ? null
          : (priorHumanPlayerId ?? this.priorHumanPlayerId),
      lastControlledPlayerId:
          lastControlledPlayerId ?? this.lastControlledPlayerId,
      controlBaseline: clearControlBaseline
          ? null
          : (controlBaseline ?? this.controlBaseline),
    );
  }
}

class ObserveControlBaseline {
  const ObserveControlBaseline({
    required this.playerIsHuman,
    required this.aiControlByGpId,
  });

  final Map<String, bool> playerIsHuman;
  final Map<String, bool> aiControlByGpId;

  static ObserveControlBaseline fromGame(Game game) {
    return ObserveControlBaseline(
      playerIsHuman: {for (final p in game.players) p.id: p.isHuman},
      aiControlByGpId: Map<String, bool>.from(game.aiControlByGpId),
    );
  }
}

class ObserveSessionNotifier extends Notifier<ObserveSessionState> {
  @override
  ObserveSessionState build() => const ObserveSessionState();

  void reset() {
    state = const ObserveSessionState();
  }

  /// Applies AI handoff on [game] when entering observe from [ObserveMode.off].
  Game applyObserveHandoffIfNeeded(Game game) {
    if (state.isObserving) {
      return game;
    }
    final priorHuman = game.players
        .where((p) => p.isHuman)
        .map((p) => p.id)
        .firstOrNull;
    final baseline = ObserveControlBaseline.fromGame(game);
    final lastControlled =
        priorHuman ?? game.players.first.id;

    state = state.copyWith(
      priorHumanPlayerId: priorHuman,
      lastControlledPlayerId: lastControlled,
      controlBaseline: baseline,
    );

    return _gameWithAllGpAiControlled(game);
  }

  Game applyObserveOff(Game game) {
    final baseline = state.controlBaseline;
    final prior = state.priorHumanPlayerId;
    reset();
    if (baseline == null) {
      return game;
    }
    final players = [
      for (final p in game.players)
        p.copyWith(isHuman: prior != null && p.id == prior),
    ];
    return game.copyWith(
      players: players,
      aiControlByGpId: Map<String, bool>.from(baseline.aiControlByGpId),
    );
  }

  Game prepareGameForPersistence(Game game) {
    final baseline = state.controlBaseline;
    if (baseline == null) {
      return game;
    }
    final players = [
      for (final p in game.players)
        p.copyWith(isHuman: baseline.playerIsHuman[p.id] ?? p.isHuman),
    ];
    return game.copyWith(
      players: players,
      aiControlByGpId: Map<String, bool>.from(baseline.aiControlByGpId),
    );
  }

  void setModeGlobal() {
    state = state.copyWith(
      mode: ObserveMode.global,
      clearObservedPlayerId: true,
    );
  }

  void setModePlayer(String targetPlayerId) {
    state = state.copyWith(
      mode: ObserveMode.player,
      observedPlayerId: targetPlayerId,
    );
  }

  void setModeOff() {
    reset();
  }

  Game _gameWithAllGpAiControlled(Game game) {
    final aiFlags = {
      for (final p in game.players) p.id: true,
    };
    return game.copyWith(
      players: [for (final p in game.players) p.copyWith(isHuman: false)],
      aiControlByGpId: aiFlags,
    );
  }
}

final observeSessionProvider =
    NotifierProvider<ObserveSessionNotifier, ObserveSessionState>(
      ObserveSessionNotifier.new,
    );
