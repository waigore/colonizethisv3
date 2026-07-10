part of 'incremental_candidate_validator_equivalence_test_helpers.dart';

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

void expectMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required MoveOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Move',
    label: label,
    fullPass: () => fullPassMoveAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isMoveAccepted(candidate),
  );
}

void expectArmyMoveEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required ArmyMoveOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Army move',
    label: label,
    fullPass: () => fullPassArmyMoveAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isArmyMoveAccepted(candidate),
  );
}

void expectBuildEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required BuildUnitOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Build',
    label: label,
    fullPass: () => fullPassBuildAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isBuildAccepted(candidate),
  );
}

void expectWorkEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required WorkOrder candidate,
  required String label,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Work',
    label: label,
    tileMapByRegion: tileMapByRegion,
    fullPass: () => fullPassWorkAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
      tileMapByRegion: tileMapByRegion,
    ),
    incremental: (validator) => validator.isWorkAccepted(candidate),
  );
}

void expectDiplomaticEquivalent({
  required Game game,
  required MapTopology topology,
  required String playerId,
  required Orders basePrefix,
  required DiplomaticOrder candidate,
  required String label,
}) {
  expectCandidateFamilyEquivalent(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: basePrefix,
    family: 'Diplomatic',
    label: label,
    fullPass: () => fullPassDiplomaticAccepted(
      game,
      topology,
      playerId,
      basePrefix,
      candidate,
    ),
    incremental: (validator) => validator.isDiplomaticAccepted(candidate),
  );
}
