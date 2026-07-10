// Shared incremental/full-pass equivalence helpers (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

export 'incremental_candidate_validator_equivalence_corpus.dart';

bool _fullPassAddOrderAccepted(
  Orders basePrefix,
  OrderValidationResult Function(OrderEngine engine) add,
) {
  final engine = OrderEngine(initialOrders: basePrefix);
  return add(engine).isAccepted;
}

bool fullPassMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  MoveOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) =>
          engine.addMoveOrderWithContext(game, topology, playerId, candidate),
    );

bool fullPassArmyMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  ArmyMoveOrder candidate,
) {
  final merged = applyArmyMoveOrderForPlayer(basePrefix, playerId, candidate);
  final engine = OrderEngine(initialOrders: merged);
  final results = engine.validatePlayerOrdersWithContext(
    game,
    topology,
    playerId,
  );
  if (results.isEmpty) return false;
  return results.every((r) => r.isAccepted);
}

bool fullPassBuildAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  BuildUnitOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) =>
          engine.addBuildOrderWithContext(game, topology, playerId, candidate),
    );

bool fullPassWorkAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) => engine.addWorkOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
        tileMapByRegion: tileMapByRegion,
      ),
    );

bool fullPassDiplomaticAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  DiplomaticOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) => engine.addDiplomaticOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
      ),
    );

bool fullPassNavalMoveAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  NavalMoveOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) =>
          engine.addNavalMoveOrderWithContext(game, topology, playerId, candidate),
    );

bool fullPassNavalMissionAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders basePrefix,
  NavalMissionOrder candidate,
) =>
    _fullPassAddOrderAccepted(
      basePrefix,
      (engine) => engine.addNavalMissionOrderWithContext(
        game,
        topology,
        playerId,
        candidate,
      ),
    );

IncrementalCandidateValidator _iceValidatorFor({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  Map<String, TileMapResult>? tileMapByRegion,
}) =>
    IncrementalCandidateValidator.forPlayer(
      game: game,
      topology: topology,
      playerId: playerId,
      basePrefix: basePrefix,
      tileMapByRegion: tileMapByRegion,
    );

void _expectIncrementalMatchesFullPass({
  required bool fullPass,
  required bool incremental,
  required String family,
  required String label,
}) {
  expect(
    incremental,
    equals(fullPass),
    reason:
        '$family candidate "$label" diverged: incremental=$incremental, fullPass=$fullPass',
  );
}

void expectCandidateFamilyEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required String family,
  required String label,
  required bool Function() fullPass,
  required bool Function(IncrementalCandidateValidator validator) incremental,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  _expectIncrementalMatchesFullPass(
    fullPass: fullPass(),
    incremental: incremental(
      _iceValidatorFor(
        game: game,
        topology: topology,
        playerId: playerId,
        basePrefix: basePrefix,
        tileMapByRegion: tileMapByRegion,
      ),
    ),
    family: family,
    label: label,
  );
}
