/// Shared diplomacy-resolution helpers extracted to eliminate copy-paste
/// duplication across the overture, FTP, intervention, call-to-arms, war, and
/// subsidy resolvers (Refs #3419). Behaviour-preserving consolidation only;
/// see SPEC/program/diplomacy-resolution.md and SPEC/game/diplomacy.md.
///
/// Identity / pending-human-decision helpers live in
/// [diplomacy_human_decision.dart] and are re-exported here so checker-pinned
/// and barrel import paths stay stable (Refs #4341).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

export 'diplomacy_human_decision.dart';

/// Removes overtures between [gpId] and [factionId] from [game].
///
/// Canonical replacement for the per-resolver inline overture-clearing filter
/// blocks (Refs #3562). By default only the directional overture
/// (`gpId -> factionId`) is cleared, matching the do-nothing intervention path.
/// When [bidirectional] is true the reverse overture (`factionId -> gpId`) is
/// also cleared, matching war-termination clearing.
///
/// Returns the (possibly unchanged) game alongside the overtures that were
/// removed, in their original `game.overtureStates` order. When nothing matches
/// the original [game] instance is returned with an empty `removed` list, so
/// callers can cheaply skip follow-up work (event logging, copy churn). Callers
/// that log per-removed overture should consume `removed` instead of re-deriving
/// the diff.
///
/// Note: this clears a single GP↔faction pair. Full faction teardown (removing
/// every overture that involves an absorbed faction, regardless of counterpart)
/// is a distinct single-faction operation and is intentionally not expressed
/// through this pair-scoped helper.
({Game game, List<OvertureState> removed}) clearOverturesBetweenGpAndFaction(
  Game game,
  String gpId,
  String factionId, {
  bool bidirectional = false,
}) {
  final removed = <OvertureState>[];
  final kept = <OvertureState>[];
  for (final o in game.overtureStates) {
    final directional = o.gpId == gpId && o.targetId == factionId;
    final reverse = bidirectional && o.gpId == factionId && o.targetId == gpId;
    if (directional || reverse) {
      removed.add(o);
    } else {
      kept.add(o);
    }
  }
  if (removed.isEmpty) return (game: game, removed: const <OvertureState>[]);
  return (game: game.copyWith(overtureStates: kept), removed: removed);
}

/// Overture pair key for GP→target lookups (directional).
String overturePairKey(String gpId, String targetId) => '$gpId\x1F$targetId';

/// Directional GP→target overture lookup in a working [overtures] list.
///
/// Mirrors [getOverture] for resolver rolling state that has not yet been
/// written back to [Game.overtureStates] (Refs #3825).
OvertureState? findOvertureForGpTarget(
  List<OvertureState> overtures,
  String gpId,
  String targetId,
) {
  for (final o in overtures) {
    if (o.gpId == gpId && o.targetId == targetId) return o;
  }
  return null;
}

/// Index of the directional GP→target overture in [overtures], or -1.
int indexOfOvertureForGpTarget(
  List<OvertureState> overtures,
  String gpId,
  String targetId,
) => overtures.indexWhere((o) => o.gpId == gpId && o.targetId == targetId);

/// Applies GP–GP war overture rules (Refs #3753 R1): preserve `embassy`,
/// downgrade `nap`/`joinEmpire` to `embassy`, remove stages below embassy.
///
/// Returns the updated game and overtures that changed (removed entirely or
/// downgraded from a higher treaty tier) for `agreementsClearedOnWar` logging.
({Game game, List<OvertureState> changed}) applyGpGpWarOvertureRules(
  Game game,
  String gpIdA,
  String gpIdB,
) {
  final keys = {overturePairKey(gpIdA, gpIdB), overturePairKey(gpIdB, gpIdA)};
  final changed = <OvertureState>[];
  final next = <OvertureState>[];
  for (final o in game.overtureStates) {
    final key = overturePairKey(o.gpId, o.targetId);
    if (!keys.contains(key)) {
      next.add(o);
      continue;
    }
    switch (o.stage) {
      case OvertureStage.embassy:
        next.add(o);
      case OvertureStage.nap:
      case OvertureStage.joinEmpire:
        changed.add(o);
        next.add(o.copyWith(stage: OvertureStage.embassy));
      case OvertureStage.tradeConsulate:
      case OvertureStage.none:
        changed.add(o);
    }
  }
  if (changed.isEmpty) return (game: game, changed: const <OvertureState>[]);
  return (game: game.copyWith(overtureStates: next), changed: changed);
}

/// Removes every overture that involves [factionId] on **either** side from
/// [game] (i.e. `o.gpId == factionId || o.targetId == factionId`).
///
/// Canonical full-faction-teardown counterpart to the pair-scoped
/// [clearOverturesBetweenGpAndFaction] (Refs #3562 AC1). Use this when an entire
/// faction is being removed — Join-Empire absorption of a Minor/Tribe or a Great
/// Power — so its inbound and outbound overtures all disappear regardless of the
/// counterpart. The pair-scoped helper, by contrast, clears only a single
/// GP↔faction pairing and is the wrong tool here.
///
/// Minor/Tribe targets never originate overtures (overtures are GP→target), so
/// for them the either-side filter is equivalent to the previous
/// `targetId == factionId` block; for an absorbed Great Power the either-side
/// filter matches the previous `gpId == factionId || targetId == factionId`
/// block. Both prior inline blocks are therefore behaviour-preserving here.
///
/// Returns the (possibly unchanged) game alongside the overtures that were
/// removed, in their original `game.overtureStates` order. When nothing matches
/// the original [game] instance is returned with an empty `removed` list.
({Game game, List<OvertureState> removed}) clearOverturesInvolvingFaction(
  Game game,
  String factionId,
) {
  final removed = <OvertureState>[];
  final kept = <OvertureState>[];
  for (final o in game.overtureStates) {
    if (o.gpId == factionId || o.targetId == factionId) {
      removed.add(o);
    } else {
      kept.add(o);
    }
  }
  if (removed.isEmpty) return (game: game, removed: const <OvertureState>[]);
  return (game: game.copyWith(overtureStates: kept), removed: removed);
}

/// Returns a new player list with the player at [index] debited [amount] from
/// its treasury.
///
/// Returns [players] unchanged when [index] is out of range or [amount] is not
/// positive, so callers can pass an unresolved index (`-1`) safely. When a
/// debit is applied the returned list is a fresh copy, preserving the original.
List<Player> debitPlayerTreasury(List<Player> players, int index, int amount) {
  if (amount <= 0 || index < 0 || index >= players.length) return players;
  final next = List<Player>.from(players);
  next[index] = next[index].copyWith(treasury: next[index].treasury - amount);
  return next;
}
