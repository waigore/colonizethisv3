import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'order_validators.dart';
import 'unit_type_helpers.dart';

/// Incremental candidate validation primitive used by the order suggestion API
/// to evaluate single candidates against an already-accepted `basePrefix`
/// without running full-pass `validatePlayerOrdersWithContext`.
///
/// Spec: SPEC/program/order-suggestions.md § Incremental candidate validation;
/// SPEC/program/order-engine.md § Validation (candidate-probe context).
///
/// Equivalence: For any `basePrefix` whose every order is `accepted` by
/// `validatePlayerOrdersWithContext` for the player, the accept/reject decision
/// returned by these helpers for a candidate `c` is identical to running the
/// full-pass validator over `basePrefix ⊕ c` and inspecting `c`'s result.
/// This file covers all candidate types used by suggestion probes, including
/// stateful build/work/diplomatic validators via accepted-prefix replay.
class IncrementalCandidateValidator {
  IncrementalCandidateValidator._({
    required this.game,
    required this.topology,
    required this.playerId,
    required this.basePrefix,
    required this.view,
    required this.unitsById,
    required this.diplomaticOrders,
    required this.tileMapByRegion,
  });

  /// Builds a validator bound to the given `basePrefix` and player. Reuse one
  /// instance per suggestion pass to amortize the per-player view/unit lookup
  /// build cost across many candidate probes (the AI suggestion API enumerates
  /// many candidates per call).
  factory IncrementalCandidateValidator.forPlayer({
    required Game game,
    required MapTopology topology,
    required String playerId,
    required Orders basePrefix,
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final view = buildPlayerView(game, topology, playerId);
    final unitsById = unitsByIdFromWorld(game.worldState);
    final diplomaticOrders =
        basePrefix.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];
    return IncrementalCandidateValidator._(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: basePrefix,
      view: view,
      unitsById: unitsById,
      diplomaticOrders: diplomaticOrders,
      tileMapByRegion: tileMapByRegion,
    );
  }

  final Game game;
  final MapTopology topology;
  final String playerId;
  final Orders basePrefix;
  final PlayerView view;
  final Map<String, Unit> unitsById;
  final List<DiplomaticOrder> diplomaticOrders;
  final Map<String, TileMapResult>? tileMapByRegion;

  bool isMoveAccepted(MoveOrder candidate) {
    const validator = MoveValidator();
    final standalone = validator
        .validate(
          candidate,
          game,
          playerId,
          unitsById,
          diplomaticOrders,
          view,
          topology,
          previousRejected: false,
        )
        .isAccepted;
    if (!standalone) return false;

    // Cross-cutting effect: if the candidate move would add the unit to
    // [civilianDraftMoveUnitIds] (i.e. the unit has a non-empty tileKey),
    // any existing [WorkOrder] for the same unit in [basePrefix] becomes
    // rejected via the move XOR work rule (`kReasonCivilianMoveXorWorkOrder`
    // in [WorkOrderValidator]). The full-pass approach exposes this as a
    // cascade-driven rejection in `validatePlayerOrdersWithContext`'s last
    // result; mirror it here so the incremental decision matches the
    // full-pass `addMoveOrderWithContext(...).isAccepted` contract.
    final unit = unitsById[candidate.unitId];
    final unitTileKey = unit?.tileKey;
    if (unitTileKey == null || unitTileKey.isEmpty) {
      return true;
    }
    final works = basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    for (final w in works) {
      if (w.unitId == candidate.unitId) return false;
    }
    return true;
  }

  bool isArmyMoveAccepted(ArmyMoveOrder candidate) {
    const validator = ArmyMoveValidator();
    return validator
        .validate(
          candidate,
          game,
          playerId,
          diplomaticOrders,
          view,
          topology,
        )
        .isAccepted;
  }

  bool isNavalMoveAccepted(NavalMoveOrder candidate) {
    final validator = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    return validator
        .validateNavalMove(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isNavalMissionAccepted(NavalMissionOrder candidate) {
    final validator = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    return validator
        .validateNavalMission(candidate, previousRejected: false)
        .isAccepted;
  }

  bool isBuildAccepted(BuildUnitOrder candidate) {
    final player = _player();
    if (player == null) return false;
    final validator = BuildOrderValidator(game: game, player: player);
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    for (final existing in builds) {
      final result = validator.validate(existing, previousRejected: false);
      if (!result.isAccepted) return false;
    }
    return validator.validate(candidate, previousRejected: false).isAccepted;
  }

  bool isWorkAccepted(WorkOrder candidate) {
    final player = _player();
    if (player == null) return false;
    final economy = _projectEconomyAfterAcceptedBuildOrders(player);
    final view = buildPlayerView(game, topology, playerId);
    final devExclusiveTiles = devExclusiveTilesFromWorld(game.worldState, playerId);
    final workValidator = WorkOrderValidator(
      context: WorkOrderValidationContext(
        game: game,
        player: player,
        playerId: playerId,
        view: view,
        unitsById: unitsById,
        devExclusiveTiles: devExclusiveTiles,
        tileMapByRegion: tileMapByRegion,
        civilianDraftMoveUnitIds: _civilianDraftMoveUnitIds(),
        diplomaticOrders: diplomaticOrders,
        topology: topology,
      ),
      stockpile: economy.stockpile,
      treasury: economy.treasury,
    );
    final works = basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    for (final existing in works) {
      final result = workValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) return false;
    }
    return workValidator.validate(candidate, previousRejected: false).isAccepted;
  }

  bool isDiplomaticAccepted(DiplomaticOrder candidate) {
    final player = _player();
    if (player == null) return false;
    final economy = _projectEconomyAfterAcceptedBuildAndWorkOrders(player);
    final validator = DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: economy.treasury,
    );
    for (final existing in diplomaticOrders) {
      final result = validator.validate(existing, previousRejected: false);
      if (!result.result.isAccepted) return false;
    }
    return validator.validate(candidate, previousRejected: false).result.isAccepted;
  }

  ({Stockpile stockpile, int treasury}) _projectEconomyAfterAcceptedBuildOrders(
    Player player,
  ) {
    final buildValidator = BuildOrderValidator(game: game, player: player);
    final builds =
        basePrefix.buildUnitOrdersByPlayerId[playerId] ??
        const <BuildUnitOrder>[];
    for (final existing in builds) {
      final result = buildValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) {
        return (stockpile: player.stockpile, treasury: player.treasury);
      }
    }
    return (stockpile: buildValidator.stockpile, treasury: buildValidator.treasury);
  }

  ({Stockpile stockpile, int treasury})
  _projectEconomyAfterAcceptedBuildAndWorkOrders(Player player) {
    final afterBuild = _projectEconomyAfterAcceptedBuildOrders(player);
    final workValidator = WorkOrderValidator(
      context: WorkOrderValidationContext(
        game: game,
        player: player,
        playerId: playerId,
        view: view,
        unitsById: unitsById,
        devExclusiveTiles: devExclusiveTilesFromWorld(game.worldState, playerId),
        tileMapByRegion: tileMapByRegion,
        civilianDraftMoveUnitIds: _civilianDraftMoveUnitIds(),
        diplomaticOrders: diplomaticOrders,
        topology: topology,
      ),
      stockpile: afterBuild.stockpile,
      treasury: afterBuild.treasury,
    );
    final works = basePrefix.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
    for (final existing in works) {
      final result = workValidator.validate(existing, previousRejected: false);
      if (!result.isAccepted) {
        return afterBuild;
      }
    }
    return (stockpile: workValidator.stockpile, treasury: workValidator.treasury);
  }

  Set<String> _civilianDraftMoveUnitIds() {
    final ids = <String>{};
    final moves = basePrefix.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[];
    for (final move in moves) {
      final unit = unitsById[move.unitId];
      if (unit != null && unit.tileKey != null && unit.tileKey!.isNotEmpty) {
        ids.add(move.unitId);
      }
    }
    return ids;
  }

  Player? _player() {
    for (final p in game.players) {
      if (p.id == playerId) return p;
    }
    return null;
  }

}
