/// Shared at-war peace collectors and GP-war presence helpers (Refs #3941;
/// concern-split #4365 Slice A).
library;

import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import '../util/ai_validation_exception.dart';
import '../util/faction_query.dart';

/// Ascending-sorted Great Power ids the active player is at war with.
List<String> gpFactionIdsAtWarWith(Game game, AIWorldSnapshot snapshot) {
  return <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ]..sort();
}

/// At-war Great Powers satisfying [keep], ascending by factionId.
List<String> gpAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  required bool Function(String factionId) keep,
}) {
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.greatPower,
    keep: keep,
  );
}

/// At-war minor nations satisfying optional [keep], ascending by factionId.
List<String> minorAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.minorNation,
    keep: keep,
  );
}

/// At-war tribes satisfying optional [keep], ascending by factionId.
List<String> tribeAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.tribe,
    keep: keep,
  );
}

/// At-war non-Great-Power factions satisfying optional [keep].
List<String> nonGreatPowerAtWarPeaceTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  bool Function(String factionId)? keep,
}) {
  return _filterAtWarTargetsWhere(
    game: game,
    snapshot: snapshot,
    kind: _AtWarPeaceTargetKind.nonGreatPower,
    keep: keep,
  );
}

enum _AtWarPeaceTargetKind {
  greatPower,
  minorNation,
  tribe,
  nonGreatPower,
}

List<String> _filterAtWarTargetsWhere({
  required Game game,
  required AIWorldSnapshot snapshot,
  required _AtWarPeaceTargetKind kind,
  bool Function(String factionId)? keep,
}) {
  switch (kind) {
    case _AtWarPeaceTargetKind.greatPower:
      final requiredKeep = keep;
      if (requiredKeep == null) {
        throw AiValidationException.value(
          keep,
          'keep',
          'Great-power at-war peace targets require a keep predicate.',
        );
      }
      return <String>[
        for (final factionId in gpFactionIdsAtWarWith(game, snapshot))
          if (requiredKeep(factionId)) factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.minorNation:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (isMinorFaction(game, factionId) &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.tribe:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (isTribeFaction(game, factionId) &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
    case _AtWarPeaceTargetKind.nonGreatPower:
      return <String>[
        for (final factionId in snapshot.threats.atWarWith)
          if (game.playerById(factionId) == null &&
              (keep == null || keep(factionId)))
            factionId,
      ]..sort();
  }
}

/// [factionIds] with [blocker] removed, sorted ascending.
List<String> peaceTargetsExcludingBlocker({
  required Iterable<String> factionIds,
  required String? blocker,
}) => <String>[
  for (final factionId in factionIds)
    if (factionId != blocker) factionId,
]..sort();

/// Whether the active player is at war with any Great Power (short-circuit).
bool isAtWarWithAnyGreatPower(Game game, AIWorldSnapshot snapshot) =>
    snapshot.threats.atWarWith.any((id) => game.playerById(id) != null);
