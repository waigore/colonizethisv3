part of 'order_engine.dart';

/// Appends one [OrderValidationResult] per order; short-circuits when [rejected].
/// Returns the new rejected flag (true if any result was rejected).
bool _appendValidationResults<T>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  OrderValidationResult Function(T order, bool previousRejected) validate,
) {
  var r = rejected;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res);
    if (!res.isAccepted) r = true;
  }
  return r;
}

/// Like [_appendValidationResults] for validators that also return updated state (e.g. treasury).
/// Appends each result to [results], propagates [rejected], and returns (rejected, finalState).
({bool rejected, S state}) _appendValidationResultsWithState<T, S>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  S initialState,
  ({OrderValidationResult result, S state}) Function(
    T order,
    bool previousRejected,
  )
  validate,
) {
  var r = rejected;
  var s = initialState;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res.result);
    if (!res.result.isAccepted) r = true;
    s = res.state;
  }
  return (rejected: r, state: s);
}

/// Mutable state threaded through [_runOrderValidationPhases].
/// Holds the running rejected flag, treasury, stockpile, worker pool, and
/// the accumulated [OrderValidationResult] list. Existing only inside
/// [OrderEngine.validatePlayerOrdersWithContext]'s call stack.
class _OrderValidationRunState {
  _OrderValidationRunState({
    required this.results,
    required this.stockpile,
    required this.treasury,
    required this.workerPool,
  });

  final List<OrderValidationResult> results;
  bool rejected = false;
  Stockpile stockpile;
  int treasury;
  WorkerPool workerPool;
}

/// Build and run the per-category validation phases for one player.
/// Mutates [state] (results / rejected / stockpile / treasury / workerPool)
/// in submission order: move, army-move, recruit-worker, build, work,
/// diplomatic, naval, naval-mission, trade.
///
/// [resolution] is the per-pass [OrderResolutionContext] snapshot built
/// once in [OrderEngine.validatePlayerOrdersWithContext] (view + unitsById +
/// provinceById); both the per-bundle validator factory and the per-move
/// validator share this exact record so probes do not rebuild equivalent
/// maps (Refs #2836 AC 3; SPEC/program/logic-validator-units-params.md).
void _runOrderValidationPhases({
  required OrderValidatorFactory validatorFactory,
  required OrderEffectsProjector? projector,
  required Orders orders,
  required _OrderValidationRunState state,
  required Game game,
  required Player player,
  required String playerId,
  required OrderResolutionContext resolution,
  required MapTopology topology,
  required Map<String, TileMapResult>? tileMapByRegion,
  required List<DiplomaticOrder> diplomatic,
  required Set<String> civilianDraftMoveUnitIds,
  required Set<String> devExclusiveTiles,
  required DiplomacyFactionMembership factionMembership,
  required Map<String, Army> armiesById,
  required List<MoveOrder> moves,
  required List<ArmyMoveOrder> armyMoves,
  required List<RecruitWorkerOrder> recruitWorkers,
  required List<BuildUnitOrder> builds,
  required List<WorkOrder> works,
  required List<NavalMoveOrder> navals,
  required List<NavalMissionOrder> missions,
  required List<TradeOrder> tradeOrders,
}) {
  OrderValidators newValidatorBundle() => validatorFactory(
    game,
    player,
    playerId,
    resolution,
    topology,
    diplomatic,
    tileMapByRegion,
    civilianDraftMoveUnitIds,
    devExclusiveTiles,
    state.stockpile,
    state.treasury,
    factionMembership,
    state.workerPool,
  );

  // One ordered list: move + army share the initial bundle; each later
  // category refreshes validators so stockpile/treasury/diplomatic state
  // matches incremental validation ordering (Refs #2391 AC7,
  // SPEC/program/order-engine.md). Worker pool orders (recruit / train)
  // come before unit builds in both validation and resolution so the
  // peasant reservation ledger reflects accepted recruit consumes before
  // military / naval builds check their own peasant requirement
  // (SPEC/game/workers-and-population.md § Peasant reservation;
  // SPEC/program/turn-resolution-phase-details.md § Build / work).
  final validationPhases =
      <({bool refreshBundleBefore, void Function(OrderValidators) run})>[
        (
          refreshBundleBefore: false,
          run: (v) => _runMovePhase(
            v,
            state,
            moves,
            game,
            playerId,
            resolution,
            diplomatic,
            topology,
            factionMembership,
          ),
        ),
        (
          refreshBundleBefore: false,
          run: (v) => _runArmyMovePhase(
            v,
            state,
            armyMoves,
            game,
            playerId,
            diplomatic,
            resolution.view,
            topology,
            armiesById,
            factionMembership,
          ),
        ),
        (
          refreshBundleBefore: true,
          run: (v) => _runRecruitWorkerPhase(v, state, recruitWorkers),
        ),
        (
          refreshBundleBefore: true,
          run: (v) => _runBuildPhase(v, state, builds),
        ),
        (refreshBundleBefore: true, run: (v) => _runWorkPhase(v, state, works)),
        (
          refreshBundleBefore: true,
          run: (v) => _runDiplomaticPhase(v, state, diplomatic),
        ),
        (
          refreshBundleBefore: true,
          run: (v) => _runNavalPhase(v, state, navals, missions),
        ),
        (
          refreshBundleBefore: false,
          run: (v) => _runTradeOrderPhase(
            state,
            game,
            playerId,
            tradeOrders,
            topology,
            copyOrdersSnapshotForEngine(orders),
            tileMapByRegion,
            projector,
          ),
        ),
      ];

  var validators = newValidatorBundle();
  for (final phase in validationPhases) {
    if (phase.refreshBundleBefore) {
      validators = newValidatorBundle();
    }
    phase.run(validators);
  }
}

void _runMovePhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<MoveOrder> moves,
  Game game,
  String playerId,
  OrderResolutionContext resolution,
  List<DiplomaticOrder> diplomatic,
  MapTopology topology,
  DiplomacyFactionMembership factionMembership,
) {
  // [resolution] is the per-pass snapshot built once in
  // [validatePlayerOrdersWithContext]; the per-move
  // [MoveValidator.validate] call reuses it directly so probes do not
  // rebuild equivalent `view` / `unitsById` maps (Refs #2836 AC 3;
  // SPEC/program/logic-validator-units-params.md).
  state.rejected = _appendValidationResults(
    state.results,
    moves,
    state.rejected,
    (o, prev) => v.moveValidator.validate(
      o,
      game,
      playerId,
      resolution,
      diplomatic,
      topology,
      previousRejected: prev,
      factionMembership: factionMembership,
    ),
  );
}

void _runArmyMovePhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<ArmyMoveOrder> armyMoves,
  Game game,
  String playerId,
  List<DiplomaticOrder> diplomatic,
  PlayerView view,
  MapTopology topology,
  Map<String, Army> armiesById,
  DiplomacyFactionMembership factionMembership,
) {
  state.rejected = _appendValidationResults(
    state.results,
    armyMoves,
    state.rejected,
    (o, prev) => prev
        ? previousInvalidOrderResult
        : v.armyMoveValidator.validate(
            o,
            game,
            playerId,
            diplomatic,
            view,
            topology,
            armiesById: armiesById,
            factionMembership: factionMembership,
          ),
  );
}

void _runRecruitWorkerPhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<RecruitWorkerOrder> recruitWorkers,
) {
  state.rejected = _appendValidationResults(
    state.results,
    recruitWorkers,
    state.rejected,
    (o, prev) => v.recruitWorkerValidator.validate(o, previousRejected: prev),
  );
  state.workerPool = v.recruitWorkerValidator.workers;
  state.stockpile = v.recruitWorkerValidator.stockpile;
  state.treasury = v.recruitWorkerValidator.treasury;
}

void _runBuildPhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<BuildUnitOrder> builds,
) {
  state.rejected = _appendValidationResults(
    state.results,
    builds,
    state.rejected,
    (o, prev) => v.buildValidator.validate(o, previousRejected: prev),
  );
  state.workerPool = v.buildValidator.workers;
  state.stockpile = v.buildValidator.stockpile;
  state.treasury = v.buildValidator.treasury;
}

void _runWorkPhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<WorkOrder> works,
) {
  state.rejected = _appendValidationResults(
    state.results,
    works,
    state.rejected,
    (o, prev) => v.workValidator.validate(o, previousRejected: prev),
  );
  state.stockpile = v.workValidator.stockpile;
  state.treasury = v.workValidator.treasury;
}

void _runDiplomaticPhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<DiplomaticOrder> diplomatic,
) {
  final afterDiplomatic =
      _appendValidationResultsWithState<DiplomaticOrder, int>(
        state.results,
        diplomatic,
        state.rejected,
        state.treasury,
        (o, prev) {
          final r = v.diplomaticValidator.validate(o, previousRejected: prev);
          return (result: r.result, state: r.treasury);
        },
      );
  state.rejected = afterDiplomatic.rejected;
  state.treasury = afterDiplomatic.state;
}

void _runNavalPhase(
  OrderValidators v,
  _OrderValidationRunState state,
  List<NavalMoveOrder> navals,
  List<NavalMissionOrder> missions,
) {
  state.rejected = _appendValidationResults(
    state.results,
    navals,
    state.rejected,
    (o, prev) => v.navalValidator.validateNavalMove(o, previousRejected: prev),
  );
  state.rejected = _appendValidationResults(
    state.results,
    missions,
    state.rejected,
    (o, prev) =>
        v.navalValidator.validateNavalMission(o, previousRejected: prev),
  );
}

void _runTradeOrderPhase(
  _OrderValidationRunState state,
  Game game,
  String playerId,
  List<TradeOrder> tradeOrders,
  MapTopology topology,
  Orders stagedOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderEffectsProjector? projector,
) {
  if (tradeOrders.isEmpty) return;
  if (state.rejected) {
    for (var i = 0; i < tradeOrders.length; i++) {
      state.results.add(previousInvalidOrderResult);
    }
    return;
  }
  // The projected non-bid treasury delta is a turn-layer dry-run
  // (`projectOrderEffects` calls `resolveTurnForGame`) that lives in the neutral
  // `lib/src/projections/` core module — above the `orders` domain. The engine
  // therefore receives it as an injected [OrderEffectsProjector] (Refs #3290
  // C2) and hands the resulting delta to the (economy-local) context builder,
  // keeping both `orders` free of any `projections`/`turn` import and `economy`
  // free of any `orders`/`turn` import per
  // `SPEC/program/logic-package-split-phase0.md`.
  if (projector == null) {
    throw StateError(
      'OrderEngine trade-order validation requires an injected '
      'OrderEffectsProjector; construct OrderEngine(projector: '
      'projectOrderEffects).',
    );
  }
  final projected = projector(
    game: game,
    orders: stagedOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion ?? const {},
    playerId: playerId,
  );
  final context = tradeOrderValidationContextFromGame(
    game,
    playerId,
    stagedOrders: stagedOrders,
    projectedTreasuryDelta: projected.treasuryDelta ?? 0,
  );
  final tradeResults = TradeOrderValidator.validate(
    context: context,
    proposedOrders: tradeOrders,
  );
  state.results.addAll(tradeResults);
  if (tradeResults.any((r) => !r.isAccepted)) {
    state.rejected = true;
  }
}
