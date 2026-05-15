import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_projections.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import '../constants.dart';
import 'projected_effects.dart';
import 'order_validation_result.dart';
export 'order_validation_result.dart';
import 'unit_type_helpers.dart';
export 'validator_bundle.dart'
    show
        OrderValidators,
        buildWorkOrderValidationContext,
        createOrderValidators,
        createWorkOrderValidator;
import 'validator_bundle.dart';

part 'order_engine.g.dart';

// --- Test-only instrumentation (Refs #2237 AC2) ---
bool _trackValidatePlayerOrdersWithContextInvocationsForTests = false;
int _validatePlayerOrdersWithContextInvocationCountForTests = 0;

/// Test hook: when enabled, counts every call to [OrderEngine.validatePlayerOrdersWithContext].
void setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(
  bool enabled,
) {
  _trackValidatePlayerOrdersWithContextInvocationsForTests = enabled;
  _validatePlayerOrdersWithContextInvocationCountForTests = 0;
}

/// Test hook: invocations counted while tracking is enabled (Refs #2237).
int get orderEngineValidatePlayerOrdersWithContextInvocationCountForTests =>
    _validatePlayerOrdersWithContextInvocationCountForTests;

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

/// Deep-copy of order maps: new map and new list per player. Used by generated copy helpers.
Map<String, List<T>> _copyMapOfOrderLists<T>(Map<String, List<T>> map) =>
    Map.from(map)..updateAll((_, v) => List<T>.from(v));

class _OrderSlot<T> {
  const _OrderSlot({
    required this.getter,
    required this.updater,
    required this.label,
  });

  final Map<String, List<T>> Function(Orders) getter;
  final Orders Function(Orders, Map<String, List<T>>) updater;
  final String label;
}

typedef OrderValidatorFactory =
    OrderValidators Function(
      Game game,
      Player player,
      String playerId,
      PlayerView view,
      MapTopology topology,
      Map<String, Unit> unitsById,
      List<DiplomaticOrder> diplomaticOrders,
      Map<String, TileMapResult>? tileMapByRegion,
      Set<String> civilianDraftMoveUnitIds,
      Set<String> devExclusiveTiles,
      Stockpile stockpile,
      int treasury,
      DiplomacyFactionMembership factionMembership,
    );

/// One post–move/army validation round: caller constructs a fresh [OrderValidators]
/// bundle, then invokes this to append results and propagate economy state.
/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. SPEC/program/order-engine.md.
/// Slot table and public add/remove/withContext methods are generated from
/// [order_engine_manifest.yaml] → [order_engine.g.dart].
class OrderEngine with _OrderEngineGeneratedOrderMethods {
  OrderEngine({
    Orders initialOrders = const Orders(),
    OrderValidatorFactory? validatorFactory,
  }) : _orders = copyInitialOrdersForEngine(initialOrders),
       _validatorFactory = validatorFactory ?? _defaultOrderValidatorFactory;

  Orders _orders;
  final OrderValidatorFactory _validatorFactory;

  Orders get orders => copyOrdersSnapshotForEngine(_orders);

  // -- Generic helpers for add/remove --

  void _appendOrder<T>(
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = getter(_orders)[playerId] ?? [];
    _orders = updater(_orders, {
      ...getter(_orders),
      playerId: [...list, order],
    });
  }

  OrderValidationResult _addOrderWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
    String orderLabel, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    _appendOrder(playerId, order, getter, updater);
    logicLog.d('validating orders with context player=$playerId');
    final results = validatePlayerOrdersWithContext(
      game,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
    );
    if (results.isEmpty) {
      return OrderValidationResult.accepted();
    }
    final r = results.last;
    if (!r.isAccepted) {
      // Keep diagnostics bounded on probe-heavy paths by suppressing repeated
      // cascade rejections ("Previous invalid"), while preserving first-cause
      // rejection logging for debugging. Refs #2237 AC3.
      if (r.reason != previousInvalidOrderResult.reason) {
        logicLog.w(
          '$orderLabel order rejected player=$playerId reason=${r.reason}',
        );
      }
    }
    return r;
  }

  void _removeOrderAt<T>(
    String playerId,
    int index,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = List<T>.from(getter(_orders)[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = updater(_orders, {...getter(_orders), playerId: list});
    }
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  OrderValidationResult addOrderForSlot<T>(
    String playerId,
    T order,
    _OrderSlot<T> slot,
  ) {
    _appendOrder(playerId, order, slot.getter, slot.updater);
    return OrderValidationResult.accepted();
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  OrderValidationResult addOrderForSlotWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    _OrderSlot<T> slot, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    return _addOrderWithContext(
      game,
      topology,
      playerId,
      order,
      slot.getter,
      slot.updater,
      slot.label,
      tileMapByRegion: tileMapByRegion,
    );
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  void removeOrderForSlot<T>(String playerId, int index, _OrderSlot<T> slot) {
    _removeOrderAt(playerId, index, slot.getter, slot.updater);
  }

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    if (_trackValidatePlayerOrdersWithContextInvocationsForTests) {
      _validatePlayerOrdersWithContextInvocationCountForTests++;
    }
    final results = <OrderValidationResult>[];
    final player = game.playerById(playerId);
    if (player == null) return results;

    final view = buildPlayerView(game, topology, playerId);

    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final armyMoves = _orders.armyMoveOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    final diplomatic = _orders.diplomaticOrdersByPlayerId[playerId] ?? [];
    final navals = _orders.navalMoveOrdersByPlayerId[playerId] ?? [];
    final missions = _orders.navalMissionOrdersByPlayerId[playerId] ?? [];
    var rejected = false;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    final unitsById = Map<String, Unit>.from(
      unitsByIdFromWorld(game.worldState),
    );

    final devExclusiveTiles = devExclusiveTilesFromWorld(
      game.worldState,
      playerId,
    );

    final civilianDraftMoveUnitIds = <String>{};
    for (final m in moves) {
      final u = unitsById[m.unitId];
      if (u != null && u.tileKey != null && u.tileKey!.isNotEmpty) {
        civilianDraftMoveUnitIds.add(m.unitId);
      }
    }

    final factionMembership = DiplomacyFactionMembership.from(game);

    // Single-pass army index for full-pass army-move validation (Refs #2394,
    // SPEC/program/order-suggestions.md — same snapshot semantics as
    // [IncrementalCandidateValidator._armiesById] for read-only [game]).
    final armiesById = <String, Army>{
      for (final a in game.worldState.armies) a.id: a,
    };

    OrderValidators newValidatorBundle() => _validatorFactory(
      game,
      player,
      playerId,
      view,
      topology,
      unitsById,
      diplomatic,
      tileMapByRegion,
      civilianDraftMoveUnitIds,
      devExclusiveTiles,
      stockpile,
      treasury,
      factionMembership,
    );

    // One ordered list: move + army share the initial bundle; each later
    // category refreshes validators so stockpile/treasury/diplomatic state
    // matches incremental validation ordering (Refs #2391 AC7,
    // SPEC/program/order-engine.md).
    final validationPhases =
        <({bool refreshBundleBefore, void Function(OrderValidators) run})>[
          (
            refreshBundleBefore: false,
            run: (v) {
              rejected = _appendValidationResults(
                results,
                moves,
                rejected,
                (o, prev) => v.moveValidator.validate(
                  o,
                  game,
                  playerId,
                  unitsById,
                  diplomatic,
                  view,
                  topology,
                  previousRejected: prev,
                  factionMembership: factionMembership,
                ),
              );
            },
          ),
          (
            refreshBundleBefore: false,
            run: (v) {
              rejected = _appendValidationResults(
                results,
                armyMoves,
                rejected,
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
            },
          ),
          (
            refreshBundleBefore: true,
            run: (v) {
              rejected = _appendValidationResults(
                results,
                builds,
                rejected,
                (o, prev) =>
                    v.buildValidator.validate(o, previousRejected: prev),
              );
              stockpile = v.buildValidator.stockpile;
              treasury = v.buildValidator.treasury;
            },
          ),
          (
            refreshBundleBefore: true,
            run: (v) {
              rejected = _appendValidationResults(
                results,
                works,
                rejected,
                (o, prev) =>
                    v.workValidator.validate(o, previousRejected: prev),
              );
              stockpile = v.workValidator.stockpile;
              treasury = v.workValidator.treasury;
            },
          ),
          (
            refreshBundleBefore: true,
            run: (v) {
              final afterDiplomatic =
                  _appendValidationResultsWithState<DiplomaticOrder, int>(
                    results,
                    diplomatic,
                    rejected,
                    treasury,
                    (o, prev) {
                      final r = v.diplomaticValidator.validate(
                        o,
                        previousRejected: prev,
                      );
                      return (result: r.result, state: r.treasury);
                    },
                  );
              rejected = afterDiplomatic.rejected;
              treasury = afterDiplomatic.state;
            },
          ),
          (
            refreshBundleBefore: true,
            run: (v) {
              rejected = _appendValidationResults(
                results,
                navals,
                rejected,
                (o, prev) => v.navalValidator.validateNavalMove(
                  o,
                  previousRejected: prev,
                ),
              );
              rejected = _appendValidationResults(
                results,
                missions,
                rejected,
                (o, prev) => v.navalValidator.validateNavalMission(
                  o,
                  previousRejected: prev,
                ),
              );
            },
          ),
        ];

    var validators = newValidatorBundle();
    for (final phase in validationPhases) {
      if (phase.refreshBundleBefore) {
        validators = newValidatorBundle();
      }
      phase.run(validators);
    }
    return results;
  }

  /// Dry-run: apply orders via resolver (no mutation of [game]); return projected effects.
  /// Uses [projectOrderEffects] for worker count, treasury delta, unit locations, stockpile deltas.
  /// When [tileMapByRegion] is null or omitted, an empty map is used and projected extraction is zero
  /// (caller may pass tile maps when available so expected extraction is non-zero).
  ProjectedEffects projectedEffects(
    Game game,
    MapTopology topology,
    String playerId, {
    List<AssignedRecipe> defaultAssignments = const [],
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final tileMaps = tileMapByRegion ?? <String, TileMapResult>{};
    if (tileMaps.isEmpty) {
      logicLog.d(
        'projectedEffects called with no tileMapByRegion; expected extraction will be zero',
      );
    }
    return projectOrderEffects(
      game: game,
      orders: copyOrdersSnapshotForEngine(_orders),
      topology: topology,
      tileMapByRegion: tileMaps,
      playerId: playerId,
      defaultAssignments: defaultAssignments,
    );
  }
}

OrderValidators _defaultOrderValidatorFactory(
  Game game,
  Player player,
  String playerId,
  PlayerView view,
  MapTopology topology,
  Map<String, Unit> unitsById,
  List<DiplomaticOrder> diplomaticOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> civilianDraftMoveUnitIds,
  Set<String> devExclusiveTiles,
  Stockpile stockpile,
  int treasury,
  DiplomacyFactionMembership factionMembership,
) {
  return createOrderValidators(
    game: game,
    player: player,
    playerId: playerId,
    view: view,
    topology: topology,
    unitsById: unitsById,
    diplomaticOrders: diplomaticOrders,
    tileMapByRegion: tileMapByRegion,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    stockpile: stockpile,
    treasury: treasury,
    factionMembership: factionMembership,
  );
}
