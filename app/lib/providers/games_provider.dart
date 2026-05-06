import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';
import 'game_service_provider.dart';

/// List of saved game ids. Refreshed by reading from GameService.
final gameListIdsProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(gameServiceProvider);
  return service.listGameIds();
});

/// Currently loaded game, if any. Updated on load and after next turn.
class CurrentGameNotifier extends Notifier<Game?> {
  CurrentGameNotifier([this._initial]);

  final Game? _initial;

  @override
  Game? build() => _initial;

  void setGame(Game? game) {
    state = game;
  }

  void clear() {
    state = null;
  }
}

final currentGameProvider = NotifierProvider<CurrentGameNotifier, Game?>(
  CurrentGameNotifier.new,
);

/// True when the auto-save slot is valid. Rebuilds when [currentGameProvider] changes
/// so the main menu updates immediately after exiting to menu. SPEC/ui/main-menu.md.
final mainMenuAutoSaveAvailableProvider = Provider<bool>((ref) {
  ref.watch(currentGameProvider);
  if (!Hive.isBoxOpen(HiveBoxNames.games)) {
    return false;
  }
  final service = ref.watch(gameServiceProvider);
  return service.hasValidAutoSave();
});

/// Current-turn orders for the human player (work orders, move orders, etc.).
/// Updated when the player assigns/cancels work in the civilian panel; passed to nextTurn and reset after resolution.
class CurrentOrdersNotifier extends Notifier<Orders> {
  CurrentOrdersNotifier([this._initial = const Orders()]);

  final Orders _initial;

  @override
  Orders build() => _initial;

  void replaceAll(Orders next) {
    state = next;
  }

  void clear() {
    state = const Orders();
  }
}

final currentOrdersProvider = NotifierProvider<CurrentOrdersNotifier, Orders>(
  CurrentOrdersNotifier.new,
);

/// Sorted work target ids for one civilian unit that have ≥1 valid tile
/// (selected-unit availability). SPEC/program/order-suggestions.md (Refs #2133).
///
/// The app must not use broad [suggestWorkOrders] for per-unit Assign hot paths.
final availableWorkTargetIdsForUnitProvider =
    Provider.family<List<String>, String>((ref, unitId) {
      final game = ref.watch(currentGameProvider);
      if (game == null) return const [];

      final orders = ref.watch(currentOrdersProvider);
      final service = ref.watch(gameServiceProvider);
      final mapData = service.getMapData(game.id);
      final topology = mapData?.combinedTopology ?? const MapTopology();

      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final view = buildPlayerView(game, topology, humanPlayerId);

      return getAvailableWorkTargetsForUnit(
        view: view,
        game: game,
        topology: topology,
        currentOrders: orders,
        unitId: unitId,
        tileMapByRegion: mapData?.tileMapByRegion,
      ).availableWorkTargetIdsSorted();
    });

/// Tile keys reserved for the human player’s Builder/Engineer/Merchant
/// exclusivity (in-progress work + pending dev-exclusive work orders).
///
/// **SPEC/program/order-suggestions.md** § Dev-exclusive tile reservations.
/// Exposed for UI/diagnostics; availability for assignment still flows from
/// [availableWorkTargetIdsForUnitProvider] and
/// [getValidWorkOrderTileKeysWithVisibility].
final devExclusiveReservedWorkTileKeysProvider = Provider<Set<String>>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return {};

  final orders = ref.watch(currentOrdersProvider);
  final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  return devExclusiveReservedTileKeysForPlayer(game, orders, humanPlayerId);
});

/// Set of game ids for which the game-start intro dialogue has been shown.
/// SPEC/ai/dialogue-management.md § First dialogue emission point.
class GameIdsWithIntroShownNotifier extends Notifier<Set<String>> {
  GameIdsWithIntroShownNotifier([this._initial = const <String>{}]);

  final Set<String> _initial;

  @override
  Set<String> build() => _initial;

  void markShown(String gameId) {
    state = {...state, gameId};
  }
}

final gameIdsWithIntroShownProvider =
    NotifierProvider<GameIdsWithIntroShownNotifier, Set<String>>(
      GameIdsWithIntroShownNotifier.new,
    );

/// At most one blocking diplomacy gate from turn resolution (overture, intervention, CTA).
/// SPEC/ui/pending-diplomacy-state.md, SPEC/program/dialogue-system.md.
sealed class PendingDiplomacyState {
  const PendingDiplomacyState();
}

final class PendingDiplomacyOvertures extends PendingDiplomacyState {
  const PendingDiplomacyOvertures(this.offers);
  final List<OvertureOffer> offers;
}

final class PendingDiplomacyIntervention extends PendingDiplomacyState {
  const PendingDiplomacyIntervention(this.prompts);
  final List<InterventionPrompt> prompts;
}

final class PendingDiplomacyCallToArms extends PendingDiplomacyState {
  const PendingDiplomacyCallToArms(this.pending);
  final List<CallToArmsPending> pending;
}

class PendingDiplomacyNotifier extends Notifier<PendingDiplomacyState?> {
  PendingDiplomacyNotifier([this._initial]);

  final PendingDiplomacyState? _initial;

  @override
  PendingDiplomacyState? build() => _initial;

  void setOvertures(List<OvertureOffer> offers) {
    state = PendingDiplomacyOvertures(offers);
  }

  void setIntervention(List<InterventionPrompt> prompts) {
    state = PendingDiplomacyIntervention(prompts);
  }

  void setCallToArms(List<CallToArmsPending> pending) {
    state = PendingDiplomacyCallToArms(pending);
  }

  void clear() {
    state = null;
  }
}

final pendingDiplomacyProvider =
    NotifierProvider<PendingDiplomacyNotifier, PendingDiplomacyState?>(
      PendingDiplomacyNotifier.new,
    );
