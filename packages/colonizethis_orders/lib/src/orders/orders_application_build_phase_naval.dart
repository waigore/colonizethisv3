import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

/// Home-fleet ship spawn when capital has a seaboard port (naval build slice, #1618).
class NavalBuildSession {
  NavalBuildSession(this._game, this._topology)
    : _fleetById = fleetsByIdForWorld(_game.worldState);

  Game _game;
  final MapTopology _topology;

  /// Cached O(1) index of [WorldState.fleets] by fleet id. Rebuilt on
  /// [rebase] so home-fleet lookups during build orders avoid a per-order
  /// `indexWhere` over `WorldState.fleets`. Refs #2394.
  Map<String, Fleet> _fleetById;

  /// Rebases session state onto the latest build-phase game snapshot.
  void rebase(Game game) {
    _game = game;
    _fleetById = fleetsByIdForWorld(_game.worldState);
  }

  /// Spawns into home fleet when affordable build was already deducted; no-op if blocked.
  void spawnHomeFleetShipIfEligible(Player player, BuildUnitOrder order) {
    final capProvinceId = player.capitalProvinceId;
    if (capProvinceId == null) return;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    // Only add ship when capital is sea-bound (has a port). SPEC/game/ships-and-naval.md.
    final seaZoneAtCap = seaZoneIdForProvince(
      _topology,
      ProvinceId.localIdFrom(capProvinceId),
      regionId: regionId,
    );
    if (seaZoneAtCap == null) return;

    final ws = _game.worldState;
    final homeFleetId = homeFleetIdFor(player.id);
    // O(1) home-fleet lookup via the rebased index (Refs #2394). When the map
    // entry exists but is owned by another faction, treat as "no home fleet"
    // for this player and create a fresh one — same semantics as the legacy
    // `indexWhere((f) => f.id == ... && f.ownerId == ...)` predicate.
    final mapped = _fleetById[homeFleetId];
    final Fleet? existingFleet = (mapped != null && mapped.ownerId == player.id)
        ? mapped
        : null;
    var nextSeq = ws.nextShipInstanceSeq;
    final inferred = inferNextShipInstanceSeqFromFleets(ws.fleets);
    if (nextSeq < inferred) nextSeq = inferred;
    final (seqAfter, minted) = mintShipInstances(
      nextShipInstanceSeq: nextSeq,
      typeIds: [order.unitType],
    );
    nextSeq = seqAfter;
    final List<Fleet> nextFleets;
    if (existingFleet != null) {
      final updated = existingFleet.copyWith(
        ships: [...existingFleet.ships, ...minted],
      );
      nextFleets = <Fleet>[
        for (final f in ws.fleets)
          if (f.id == homeFleetId && f.ownerId == player.id) updated else f,
      ];
      _fleetById[homeFleetId] = updated;
    } else {
      final newFleet = Fleet(
        id: homeFleetId,
        ownerId: player.id,
        seaZoneId: null,
        inPortAtProvinceId: capProvinceId,
        regionId: regionId,
        ships: minted,
      );
      nextFleets = [...ws.fleets, newFleet];
      _fleetById[homeFleetId] = newFleet;
    }
    _game = _game.updateWorldState(
      (ws) => ws.copyWith(fleets: nextFleets, nextShipInstanceSeq: nextSeq),
    );
  }

  Game get game => _game;
}
