import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'capital_and_gp_fall_eligibility.dart';
import 'capital_reassignment_fatal.dart';
import 'province_lookup.dart';

/// Faction-agnostic configuration for one runtime capital-reassignment pass.
///
/// Captures the per-faction-type differences (collection, identity, capital
/// presence, the "capital cleared" mutation, and the "new capital applied"
/// mutation) so a single generic loop ([applyCapitalReassignmentForFaction])
/// drives Great Powers, Minor Nations, and Tribes with identical control flow
/// and log messages. Refs #3544.
class FactionReassignmentConfig<T> {
  const FactionReassignmentConfig({
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
Game applyCapitalReassignmentForFaction<T>(
  Game state, {
  required MapTopology topology,
  Map<String, MapTopology>? topologyByRegion,
  required FactionReassignmentConfig<T> config,
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

    final tile = resolveReassignmentTileOrThrow(
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

CapitalTile resolveReassignmentTileOrThrow({
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
