part of 'capital_and_gp_fall.dart';

/// Faction-agnostic configuration for one runtime capital-reassignment pass.
///
/// Captures the per-faction-type differences (collection, identity, capital
/// presence, the "capital cleared" mutation, and the "new capital applied"
/// mutation) so a single generic loop ([_applyCapitalReassignmentForFaction])
/// drives Great Powers, Minor Nations, and Tribes with identical control flow
/// and log messages. Refs #3544.
class _FactionReassignmentConfig<T> {
  const _FactionReassignmentConfig({
    required this.label,
    required this.factionsOf,
    required this.idOf,
    required this.capitalProvinceIdOf,
    required this.hasCapitalTile,
    required this.clearCapital,
    required this.applyNewCapital,
  });

  /// Log label for the faction type (`player`, `minor`, `tribe`).
  final String label;

  /// Resolves the iteration source from the original input [Game] snapshot.
  final List<T> Function(Game state) factionsOf;

  final String Function(T faction) idOf;
  final String? Function(T faction) capitalProvinceIdOf;
  final bool Function(T faction) hasCapitalTile;

  /// Returns the game with this faction's capital cleared.
  final Game Function(Game game, T faction) clearCapital;

  /// Returns the game with this faction's capital reassigned to [newProvinceId].
  final Game Function({
    required Game game,
    required T faction,
    required String regionId,
    required String newProvinceId,
    required CapitalTile tile,
  })
  applyNewCapital;
}

/// Single generic reassignment core shared by Great Power, Minor Nation, and
/// Tribe paths (Refs #3544). Iterates the original [state] snapshot, threading
/// the evolving [Game] through eligibility, clear, and apply mutations exactly
/// as the previous per-faction loops did.
Game _applyCapitalReassignmentForFaction<T>(
  Game state, {
  required MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
  required _FactionReassignmentConfig<T> config,
}) {
  Game game = state;
  for (final faction in config.factionsOf(state)) {
    final id = config.idOf(faction);
    final capProvinceId = config.capitalProvinceIdOf(faction);
    if (capProvinceId == null || !config.hasCapitalTile(faction)) continue;
    final regionId = ProvinceId.regionIdFrom(capProvinceId);
    final regionTopology = topologyByRegion?[regionId] ?? topology;
    final province = state.worldState.tryGetProvince(capProvinceId);
    if (province == null) continue;
    if (province.ownerId == id) continue;

    final eligibility = evaluateCapitalReassignmentEligibility(
      state: game,
      playerId: id,
      regionId: regionId,
      regionTopology: regionTopology,
    );
    if (!eligibility.eligible) {
      game = config.clearCapital(game, faction);
      worldLog.i(
        '${config.label} $id lost capital and has no provinces in $regionId; capital cleared',
      );
      continue;
    }

    final tile = _resolveReassignmentTileOrThrow(
      game: game,
      eligibility: eligibility,
      regionId: regionId,
      factionLabel: '${config.label} $id',
    );
    final newProvinceId = eligibility.candidateProvinceId!;
    game = config.applyNewCapital(
      game: game,
      faction: faction,
      regionId: regionId,
      newProvinceId: newProvinceId,
      tile: tile,
    );
    worldLog.i(
      '${config.label} $id capital reassigned to $newProvinceId (${tile.toTileKey()}) after loss',
    );
  }
  return game;
}

Game applyCapitalReassignmentAfterCombat(
  Game state,
  MapTopology topology, {
  Map<String, MapTopology>? topologyByRegion,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  return _applyCapitalReassignmentForFaction<Player>(
    state,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: _FactionReassignmentConfig<Player>(
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
  var game = _applyCapitalReassignmentForFaction<MinorNation>(
    state,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: _FactionReassignmentConfig<MinorNation>(
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

  game = _applyCapitalReassignmentForFaction<Tribe>(
    game,
    topology: topology,
    topologyByRegion: topologyByRegion,
    config: _FactionReassignmentConfig<Tribe>(
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

CapitalTile _resolveReassignmentTileOrThrow({
  required Game game,
  required CapitalReassignmentEligibility eligibility,
  required String regionId,
  required String factionLabel,
}) {
  final newProvinceId = eligibility.candidateProvinceId;
  if (newProvinceId == null || newProvinceId.isEmpty) {
    final msg =
        'capital reassignment: missing deterministic candidate in region $regionId for $factionLabel';
    final err = StateError(msg);
    worldLog.e(msg, error: err, stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg, err);
  }
  final newProvince = game.worldState.tryGetProvince(newProvinceId);
  if (newProvince == null) {
    final msg =
        'capital reassignment: province $newProvinceId not found in region $regionId for $factionLabel';
    worldLog.e(msg, error: StateError(msg), stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg);
  }
  final rawTown = newProvince.townTileKey;
  if (rawTown == null || rawTown.isEmpty) {
    final msg =
        'capital reassignment: missing townTileKey for province $newProvinceId $factionLabel';
    final err = StateError(msg);
    worldLog.e(msg, error: err, stackTrace: StackTrace.current);
    throw CapitalReassignmentFatalError(msg, err);
  }
  try {
    return CapitalTile.parseTownTileKey(rawTown, newProvinceId);
  } catch (e, st) {
    final msg =
        'capital reassignment: invalid townTileKey for province $newProvinceId $factionLabel raw="$rawTown"';
    worldLog.e(msg, error: e, stackTrace: st);
    throw CapitalReassignmentFatalError(
      'Invalid townTileKey for province $newProvinceId ($factionLabel): $e',
      e,
    );
  }
}
