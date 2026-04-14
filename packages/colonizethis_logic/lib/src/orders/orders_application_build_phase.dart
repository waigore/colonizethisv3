part of 'orders_application.dart';

/// Home-fleet ship spawn when capital has a seaboard port (naval build slice, #1618).
class _NavalBuildState {
  _NavalBuildState(this._session);

  final _BuildWorkState _session;

  /// Spawns into home fleet when affordable build was already deducted; no-op if blocked.
  void spawnHomeFleetShipIfEligible(Player player, BuildUnitOrder order) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null) return;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    // Only add ship when capital is sea-bound (has a port). SPEC/game/ships-and-naval.md.
    if (_session.topology == null) return;
    final seaZoneAtCap = seaZoneIdForProvince(
      _session.topology!,
      ProvinceId.localIdFrom(capProvinceId),
      regionId: regionId,
    );
    if (seaZoneAtCap == null) return;

    var ws = _session.game.worldState;
    var fleets = List<Fleet>.from(ws.fleets);
    final homeFleetId = homeFleetIdFor(player.id);
    final existing = fleets.indexWhere(
      (f) => f.id == homeFleetId && f.ownerId == player.id,
    );
    var nextSeq = ws.nextShipInstanceSeq;
    final inferred = inferNextShipInstanceSeqFromFleets(fleets);
    if (nextSeq < inferred) nextSeq = inferred;
    final (seqAfter, minted) = mintShipInstances(
      nextShipInstanceSeq: nextSeq,
      typeIds: [order.unitType],
    );
    nextSeq = seqAfter;
    if (existing >= 0) {
      final f = fleets[existing];
      fleets = List<Fleet>.from(fleets)
        ..[existing] = f.copyWith(ships: [...f.ships, ...minted]);
    } else {
      fleets = [
        ...fleets,
        Fleet(
          id: homeFleetId,
          ownerId: player.id,
          seaZoneId: null,
          inPortAtProvinceId: capProvinceId,
          regionId: regionId,
          ships: minted,
        ),
      ];
    }
    _session.game = _session.game.copyWith(
      worldState: ws.copyWith(fleets: fleets, nextShipInstanceSeq: nextSeq),
    );
  }
}

/// Civilian unit spawn tile resolution (civilian build slice, #1618).
class _CivilianBuildState {
  _CivilianBuildState._();

  static String? spawnTileKeyForCategory({
    required BuildUnitCategory category,
    required Player player,
    required Game game,
  }) {
    if (category != BuildUnitCategory.civilian) return null;
    return resolveCivilianSpawnTileKey(
      player: player,
      worldState: game.worldState,
    );
  }
}

/// Military regiment placement after land unit creation (military build slice, #1618).
class _MilitaryBuildState {
  _MilitaryBuildState._();

  static void appendRegimentToArmy(
    _BuildWorkState state,
    Player player,
    String spawnProvinceId,
    String newUnitId,
  ) {
    _appendMilitaryRegimentToArmy(state, player, spawnProvinceId, newUnitId);
  }
}

/// Applies build orders for all players. Mutates [state.game] and [state.work] unit maps.
void _runBuildPhase(_BuildWorkState state) {
  final naval = _NavalBuildState(state);
  for (final player in state.game.players) {
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    for (final order in state.buildOrders[player.id] ?? const []) {
      final category = buildUnitCategoryForUnitType(order.unitType);
      if (category == BuildUnitCategory.unknown) continue;

      final check = canAffordBuild(player, order, workers, stockpile, treasury);
      if (!check.canAfford) continue;

      final after = applyBuildCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;

      if (category == BuildUnitCategory.naval) {
        naval.spawnHomeFleetShipIfEligible(player, order);
        continue;
      }

      final spawnProvinceId = resolveBuildSpawnProvinceId(
        player: player,
        worldState: state.game.worldState,
        order: order,
      );
      if (spawnProvinceId == null) continue;
      final regionId = ProvinceId.regionIdFrom(spawnProvinceId);
      final civilianTileKey = _CivilianBuildState.spawnTileKeyForCategory(
        category: category,
        player: player,
        game: state.game,
      );
      if (category == BuildUnitCategory.civilian && civilianTileKey == null) {
        throw StateError(
          '$kCivilianCapitalTileMissingReason: player=${player.id}',
        );
      }

      final newUnit = Unit(
        id: _buildUnitId(player.id, order, spawnProvinceId),
        type: order.unitType,
        ownerId: player.id,
        locationProvinceId: spawnProvinceId,
        tileKey: category == BuildUnitCategory.civilian
            ? civilianTileKey
            : null,
      );

      if (regionId == kRegionNewWorld) {
        state.work.newUnitsById[newUnit.id] = newUnit;
      } else {
        state.work.oldUnitsById[newUnit.id] = newUnit;
      }

      if (category == BuildUnitCategory.military) {
        _MilitaryBuildState.appendRegimentToArmy(
          state,
          player,
          spawnProvinceId,
          newUnit.id,
        );
      }
    }

    // Apply build-phase deductions to this player so _runWorkPhase sees updated state.
    state.game = state.game.copyWith(
      players: state.game.players
          .map(
            (p) => p.id == player.id
                ? p.copyWith(
                    stockpile: stockpile,
                    workerPool: workers,
                    treasury: treasury,
                  )
                : p,
          )
          .toList(),
    );
  }
}
