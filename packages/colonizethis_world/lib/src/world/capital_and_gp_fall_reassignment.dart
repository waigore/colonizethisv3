import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_and_gp_fall_reassignment_core.dart';
import 'capital_reassignment.dart';
import 'town_capital_tile_strip.dart';
import 'player_state_pipeline.dart';

Game applyCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  return applyCapitalReassignmentForFaction<Player>(
    state,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: FactionReassignmentConfig<Player>(
      label: 'player',
      factionsOf: (s) => s.players,
      idOf: (p) => p.id,
      capitalProvinceIdOf: (p) => p.capitalProvinceId,
      hasCapitalTile: (p) => p.capitalTile != null,
      clearCapital: (game, player) => game.mapPlayers(
        (p) => p.id != player.id
            ? p
            : p.copyWith(capitalProvinceId: null, capitalTile: null),
      ),
      applyNewCapital:
          ({
            required game,
            required faction,
            required regionId,
            required newProvinceId,
            required tile,
          }) {
            try {
              var next = setCapitalForReassignment(
                game: game,
                playerId: faction.id,
                provinceId: newProvinceId,
                tile: tile,
              );
              next = next.copyWith(
                worldState: applyGreatPowerCapitalProvinceTownDevelopment(
                  next.worldState,
                  regionId,
                  newProvinceId,
                ),
              );
              final strip = stripResourcesAndExtractionImprovementsOnTileKeys(
                next,
                tileMapByRegion,
                [tile.toTileKey()],
              );
              next = strip.$1;
              final stripMaps = strip.$2;
              if (stripMaps != null && tileMapByRegion != null) {
                for (final e in stripMaps.entries) {
                  tileMapByRegion[e.key] = e.value;
                }
              }
              return next;
            } catch (e, st) {
              final msg =
                  'capital reassignment: failed to apply new capital for ${faction.id}';
              worldLog.e(msg, error: e, stackTrace: st);
              rethrow;
            }
          },
    ),
  );
}

/// Runtime capital reassignment for **Minor Nations** and **Tribes** after combat
/// (and after debug `/flip_province`). Parallel to [applyCapitalReassignmentAfterCombat]
/// for Great Powers, but updates only `capitalProvinceId` and `capitalTile` on the
/// faction entry; no port/road wiring, no `townDevelopmentLevel` mutation, no
/// `townTileKey` mutation. Uses the same faction-agnostic
/// `pickCapitalProvinceIdForReassignment(ownedProvinceIds, topology)` picker.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
Game applyFactionCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
}) {
  var game = applyCapitalReassignmentForFaction<MinorNation>(
    state,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: FactionReassignmentConfig<MinorNation>(
      label: 'minor',
      factionsOf: (s) => s.minorNations,
      idOf: (m) => m.id,
      capitalProvinceIdOf: (m) => m.capitalProvinceId,
      hasCapitalTile: (m) => m.capitalTile != null,
      clearCapital: (game, minor) => game.copyWith(
        minorNations: game.minorNations
            .map(
              (m) => m.id != minor.id
                  ? m
                  : MinorNation(
                      id: m.id,
                      displayName: m.displayName,
                      effectiveMilitaryLevel: m.effectiveMilitaryLevel,
                    ),
            )
            .toList(),
      ),
      applyNewCapital:
          ({
            required game,
            required faction,
            required regionId,
            required newProvinceId,
            required tile,
          }) => setCapitalForMinorReassignment(
            game: game,
            minorId: faction.id,
            provinceId: newProvinceId,
            tile: tile,
          ),
    ),
  );

  game = applyCapitalReassignmentForFaction<Tribe>(
    game,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: FactionReassignmentConfig<Tribe>(
      label: 'tribe',
      factionsOf: (s) => s.tribes,
      idOf: (t) => t.id,
      capitalProvinceIdOf: (t) => t.capitalProvinceId,
      hasCapitalTile: (t) => t.capitalTile != null,
      clearCapital: (game, tribe) => game.copyWith(
        tribes: game.tribes
            .map(
              (t) => t.id != tribe.id
                  ? t
                  : Tribe(
                      id: t.id,
                      displayName: t.displayName,
                      effectiveMilitaryLevel: t.effectiveMilitaryLevel,
                    ),
            )
            .toList(),
      ),
      applyNewCapital:
          ({
            required game,
            required faction,
            required regionId,
            required newProvinceId,
            required tile,
          }) => setCapitalForTribeReassignment(
            game: game,
            tribeId: faction.id,
            provinceId: newProvinceId,
            tile: tile,
          ),
    ),
  );

  return game;
}
