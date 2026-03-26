import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';

/// Tracks generals that have already commanded an **attack** this Combat phase.
/// Mutable; created once per phase and passed into each battle. SPEC/program/combat-resolution.md §3.
/// Scope: any `ownerId` (faction) that has entries in [Game.generals].
class CombatPhaseGeneralLedger {
  /// Per faction: general ids already assigned as **attacking** commander in a completed battle this phase.
  final Map<String, Set<String>> attackCommanderGeneralIdsByFaction = {};
}

/// Assignment result for one side (attacker or defender) in a battle.
class AssignedGeneralForBattle {
  const AssignedGeneralForBattle({
    required this.generalId,
    required this.medals,
  });

  /// Null when no general assigned (fallback medals only).
  final String? generalId;
  final int medals;
}

/// General picks for one [BattleContext] before resolution.
class BattleGeneralAssignment {
  const BattleGeneralAssignment({
    required this.attackerByFactionId,
    required this.defenderGeneralId,
    required this.defenderMedals,
  });

  final Map<String, AssignedGeneralForBattle> attackerByFactionId;
  final String? defenderGeneralId;
  final int defenderMedals;
}

/// Deterministic RNG for general assignment (auto-resolve and Quick Battle).
/// Same seed recipe for both modes. SPEC/program/combat-resolution.md §3.
Random battleAssignmentRng(Game game, BattleContext ctx) {
  return Random(
    Object.hash(
      game.globalGameSeed ?? 0,
      game.worldState.turnState.turnNumber,
      ctx.regionId,
      ctx.provinceId,
      ctx.defenderFactionId,
      ctx.attackers.length,
    ),
  );
}

/// Assigns generals per [BattleContext], respecting in-battle dedupe and
/// [CombatPhaseGeneralLedger] for per-turn attack commander consumption.
BattleGeneralAssignment assignGeneralsForBattleContext({
  required Game game,
  required BattleContext ctx,
  required Random rng,
  required CombatPhaseGeneralLedger ledger,
}) {
  final assignedGeneralIdsThisBattle = <String>{};

  AssignedGeneralForBattle assignForAttacker(String factionId) {
    final usedThisTurn =
        ledger.attackCommanderGeneralIdsByFaction[factionId] ?? const <String>{};
    final available = game.generals
        .where(
          (g) =>
              g.ownerId == factionId &&
              !assignedGeneralIdsThisBattle.contains(g.id) &&
              !usedThisTurn.contains(g.id),
        )
        .toList();
    if (available.isEmpty) {
      return AssignedGeneralForBattle(
        generalId: null,
        medals: fallbackGeneralMedalsFromLeader(game, factionId),
      );
    }
    final selected = available[rng.nextInt(available.length)];
    assignedGeneralIdsThisBattle.add(selected.id);
    return AssignedGeneralForBattle(
      generalId: selected.id,
      medals: selected.medals.clamp(0, 4),
    );
  }

  AssignedGeneralForBattle assignForDefender(String factionId) {
    final available = game.generals
        .where(
          (g) =>
              g.ownerId == factionId &&
              !assignedGeneralIdsThisBattle.contains(g.id),
        )
        .toList();
    if (available.isEmpty) {
      return AssignedGeneralForBattle(
        generalId: null,
        medals: fallbackGeneralMedalsFromLeader(game, factionId),
      );
    }
    final selected = available[rng.nextInt(available.length)];
    assignedGeneralIdsThisBattle.add(selected.id);
    return AssignedGeneralForBattle(
      generalId: selected.id,
      medals: selected.medals.clamp(0, 4),
    );
  }

  final attackerByFactionId = <String, AssignedGeneralForBattle>{};
  for (final attacker in ctx.attackers) {
    attackerByFactionId[attacker.factionId] =
        assignForAttacker(attacker.factionId);
  }
  final defender = assignForDefender(ctx.defenderFactionId);
  return BattleGeneralAssignment(
    attackerByFactionId: attackerByFactionId,
    defenderGeneralId: defender.generalId,
    defenderMedals: defender.medals,
  );
}

/// After a battle completes, record attacking commanders for turn-wide cap.
void recordAttackCommandersForResolvedBattle(
  BattleContext ctx,
  BattleGeneralAssignment assignment,
  CombatPhaseGeneralLedger ledger,
) {
  for (final att in ctx.attackers) {
    final info = assignment.attackerByFactionId[att.factionId];
    final gid = info?.generalId;
    if (gid != null) {
      ledger.attackCommanderGeneralIdsByFaction
          .putIfAbsent(att.factionId, () => <String>{})
          .add(gid);
    }
  }
}
