import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_rng.dart';
import 'conflict_detection.dart';
import 'leader_bonus_helpers.dart';

/// Tracks generals that are already bound to an attacking army this phase.
class CombatPhaseGeneralLedger {
  /// Per faction: general ids already bound to an attacking army this phase.
  final Map<String, Set<String>> attackCommanderGeneralIdsByFaction = {};
}

class AssignedGeneralForBattle {
  const AssignedGeneralForBattle({
    required this.generalId,
    required this.medals,
  });
  final String? generalId;
  final int medals;
}

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

/// Runs one pre-combat pass and binds generals to attacking armies and
/// primary defending armies across all provided battle contexts.
List<BattleContext> bindGeneralsForCombatPhase({
  required Game game,
  required List<BattleContext> contexts,
  required CombatPhaseGeneralLedger ledger,
}) {
  final rng = preCombatBindingRng(game);
  final defenderUsedByFaction = <String, Set<String>>{};
  final generalsByFaction = <String, List<General>>{};
  for (final general in game.generals) {
    generalsByFaction
        .putIfAbsent(general.ownerId, () => <General>[])
        .add(general);
  }
  for (final entry in generalsByFaction.entries) {
    entry.value.sort((a, b) => a.id.compareTo(b.id));
  }

  final ordered = List<BattleContext>.from(contexts)
    ..sort((a, b) {
      final byRegion = a.regionId.compareTo(b.regionId);
      if (byRegion != 0) return byRegion;
      return a.provinceId.compareTo(b.provinceId);
    });
  final bound = <BattleContext>[];

  for (final ctx in ordered) {
    final attackers = <AttackingSide>[];
    for (final attacker in ctx.attackers) {
      final factionId = attacker.factionId;
      final usedAttackers =
          ledger.attackCommanderGeneralIdsByFaction[factionId] ??
          const <String>{};
      final available = (generalsByFaction[factionId] ?? const <General>[])
          .where((g) => !usedAttackers.contains(g.id))
          .toList();
      if (available.isEmpty) {
        attackers.add(
          attacker.copyWith(
            clearGeneralId: true,
            generalMedals: fallbackGeneralMedalsFromLeader(game, factionId),
          ),
        );
        continue;
      }
      final selected = available[rng.nextInt(available.length)];
      ledger.attackCommanderGeneralIdsByFaction
          .putIfAbsent(factionId, () => <String>{})
          .add(selected.id);
      attackers.add(
        attacker.copyWith(
          generalId: selected.id,
          generalMedals: selected.medals.clamp(0, 4),
        ),
      );
    }

    final defenderFactionId = ctx.defenderFactionId;
    final usedDefenders = defenderUsedByFaction.putIfAbsent(
      defenderFactionId,
      () => <String>{},
    );
    final defenderAvailable =
        (generalsByFaction[defenderFactionId] ?? const <General>[])
            .where((g) => !usedDefenders.contains(g.id))
            .toList();
    String? defenderGeneralId;
    int defenderMedals;
    if (defenderAvailable.isEmpty) {
      defenderGeneralId = null;
      defenderMedals = fallbackGeneralMedalsFromLeader(game, defenderFactionId);
    } else {
      final selected = defenderAvailable[rng.nextInt(defenderAvailable.length)];
      defenderGeneralId = selected.id;
      defenderMedals = selected.medals.clamp(0, 4);
      usedDefenders.add(selected.id);
    }

    bound.add(
      ctx.copyWith(
        attackers: attackers,
        defenderGeneralId: defenderGeneralId,
        defenderGeneralMedals: defenderMedals,
      ),
    );
  }

  return bound;
}

/// Kept for compatibility with existing call sites.
void recordAttackCommandersForResolvedBattle(
  BattleContext ctx,
  BattleGeneralAssignment? assignment,
  CombatPhaseGeneralLedger ledger,
) {
  for (final att in ctx.attackers) {
    final fromCtx = att.generalId;
    final fromAssignment =
        assignment?.attackerByFactionId[att.factionId]?.generalId;
    final gid = fromCtx ?? fromAssignment;
    if (gid == null) continue;
    ledger.attackCommanderGeneralIdsByFaction
        .putIfAbsent(att.factionId, () => <String>{})
        .add(gid);
  }
}

BattleGeneralAssignment assignGeneralsForBattleContext({
  required Game game,
  required BattleContext ctx,
  required Random rng,
  required CombatPhaseGeneralLedger ledger,
}) {
  final hasPreboundAttackers = ctx.attackers.any((a) => a.generalId != null);
  final hasPreboundDefender = ctx.defenderGeneralId != null;
  if (!hasPreboundAttackers && !hasPreboundDefender) {
    final attackerByFactionId = <String, AssignedGeneralForBattle>{};
    for (final attacker in ctx.attackers) {
      final used =
          ledger.attackCommanderGeneralIdsByFaction[attacker.factionId] ??
          const <String>{};
      final available = game.generals
          .where((g) => g.ownerId == attacker.factionId && !used.contains(g.id))
          .toList();
      if (available.isEmpty) {
        attackerByFactionId[attacker.factionId] = AssignedGeneralForBattle(
          generalId: null,
          medals: fallbackGeneralMedalsFromLeader(game, attacker.factionId),
        );
        continue;
      }
      final selected = available[rng.nextInt(available.length)];
      attackerByFactionId[attacker.factionId] = AssignedGeneralForBattle(
        generalId: selected.id,
        medals: selected.medals.clamp(0, 4),
      );
    }
    final availableDefenders = game.generals
        .where((g) => g.ownerId == ctx.defenderFactionId)
        .toList();
    final selectedDefender = availableDefenders.isEmpty
        ? null
        : availableDefenders[rng.nextInt(availableDefenders.length)];
    return BattleGeneralAssignment(
      attackerByFactionId: attackerByFactionId,
      defenderGeneralId: selectedDefender?.id,
      defenderMedals:
          selectedDefender?.medals.clamp(0, 4) ??
          fallbackGeneralMedalsFromLeader(game, ctx.defenderFactionId),
    );
  }

  final attackerByFactionId = <String, AssignedGeneralForBattle>{};
  for (final att in ctx.attackers) {
    final gid = att.generalId;
    attackerByFactionId[att.factionId] = AssignedGeneralForBattle(
      generalId: gid,
      medals: att.generalMedals,
    );
    if (gid != null) {
      ledger.attackCommanderGeneralIdsByFaction
          .putIfAbsent(att.factionId, () => <String>{})
          .add(gid);
    }
  }
  return BattleGeneralAssignment(
    attackerByFactionId: attackerByFactionId,
    defenderGeneralId: ctx.defenderGeneralId,
    defenderMedals: ctx.defenderGeneralMedals,
  );
}
