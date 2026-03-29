import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import 'economy_debt_rules.dart';
import 'economy_tech_effects.dart';
import 'research_rules.dart';

final _log = logicLogger();

/// Research phase resolution. SPEC/program/research-resolution.md.
Game resolveResearchPhase(Game game, Orders orders) {
  final turn = game.worldState.turnState.turnNumber;
  final researchByPlayer = orders.researchOrdersByPlayerId;
  _log.i('logic: research phase start turn=$turn');

  if (researchByPlayer.isEmpty) {
    _log.i('logic: research phase end turn=$turn playersWithOrders=0');
    return game;
  }

  final playersWithOrders = researchByPlayer.values.where((o) => o.isNotEmpty).length;
  final updatedPlayers = <Player>[];

  for (final p in game.players) {
    final player = p;
    final playerOrders =
        researchByPlayer[player.id] ?? const <ResearchOrder>[];
    if (playerOrders.isEmpty) {
      updatedPlayers.add(player);
      continue;
    }

    final slots = player.researchSlots ?? defaultResearchSlots;
    if (slots <= 0) {
      _log.i(
        'logic: research apply turn=$turn playerId=${player.id} '
        'orders=${playerOrders.length} skipped=true reason=no_research_slots',
      );
      updatedPlayers.add(player);
      continue;
    }

    final originalUnlocked = Map<String, bool>.from(
      player.techUnlocked ?? const <String, bool>{},
    );
    final workingUnlocked = Map<String, bool>.from(originalUnlocked);
    final progress = Map<String, int>.from(
      player.researchProgressByTechId ?? const <String, int>{},
    );
    final maxDebt = maxDebtForPlayer(player);
    var treasury = player.treasury;

    // One order per slot (SPEC: each slot holds at most one active tech). Duplicate slotIndex
    // in the list: last wins, so only one assignment per slot is applied and no double spend.
    final bySlot = <int, ResearchOrder>{};
    for (final order in playerOrders) {
      bySlot[order.slotIndex] = order;
    }
    final ordersPerSlot = bySlot.values.toList();

    // SPEC/program/research-resolution.md: clearing a slot loses progress for that
    // tech. Progress is keyed by techId only; derive "still researching this turn"
    // from non-empty slot assignments (empty techId = cancel slot).
    final assignedNonEmptyTechIds = <String>{};
    for (final order in ordersPerSlot) {
      if (order.slotIndex < 0 || order.slotIndex >= slots) {
        continue;
      }
      final id = order.techId;
      if (id.isEmpty) {
        continue;
      }
      assignedNonEmptyTechIds.add(id);
    }
    progress.removeWhere(
      (techId, _) => !assignedNonEmptyTechIds.contains(techId),
    );

    // 1–4: validate, deduct treasury, and add progress per slot.
    for (final order in ordersPerSlot) {
      if (order.slotIndex < 0 || order.slotIndex >= slots) {
        continue;
      }
      final techId = order.techId;
      if (techId.isEmpty) {
        continue;
      }

      final tech = techById(techId);
      if (tech == null) {
        continue;
      }
      if (originalUnlocked[techId] == true) {
        continue;
      }

      var prereqsOk = true;
      for (final pre in tech.prerequisiteIds) {
        if (originalUnlocked[pre] != true) {
          prereqsOk = false;
          break;
        }
      }
      if (!prereqsOk) {
        continue;
      }

      // Discovery techs: researchable only if player has revealed (and if prospect-required, prospected) a tile with the resource. SPEC/game/tech-tree.md.
      final discoveryIds = tech.discoveryResourceIds;
      if (discoveryIds != null && discoveryIds.isNotEmpty) {
        var discoveryOk = false;
        for (final r in discoveryIds) {
          if (hasRevealedResourceForPlayer(game, player.id, r)) {
            discoveryOk = true;
            break;
          }
        }
        if (!discoveryOk) continue;
      }

      final spend = treasuryCostForFunding(order.funding);
      if (spend <= 0) {
        continue;
      }
      final nextTreasury = treasury - spend;
      if (nextTreasury < -maxDebt) {
        continue;
      }

      final points = pointsForFunding(order.funding);
      if (points <= 0) {
        continue;
      }

      treasury = nextTreasury;
      progress[techId] = (progress[techId] ?? 0) + points;
    }

    // 5–6: completion and state update.
    final toUnlock = <String>[];
    progress.forEach((techId, pts) {
      final tech = techById(techId);
      if (tech != null && pts >= tech.cost) {
        toUnlock.add(techId);
      }
    });

    for (final techId in toUnlock) {
      workingUnlocked[techId] = true;
      progress.remove(techId);
    }

    Map<String, bool>? nextUnlocked;
    if (workingUnlocked.isNotEmpty) {
      nextUnlocked = workingUnlocked;
    }

    final nextUnlockedForLevel = nextUnlocked ?? workingUnlocked;
    final militaryLevel = militaryLevelForUnlocked(nextUnlockedForLevel);
    final nextResearchSlots =
        researchSlotsForUnlockedTechs(player, nextUnlockedForLevel);

    // `Player.copyWith` treats null map fields as "keep previous"; use an explicit
    // empty map when there is no in-progress research so clears persist (e.g. cancel slot).
    final nextProgress =
        progress.isNotEmpty ? progress : const <String, int>{};

    final treasuryDelta = treasury - player.treasury;
    _log.i(
      'logic: research apply turn=$turn playerId=${player.id} '
      'orders=${playerOrders.length} treasuryDelta=$treasuryDelta '
      'completedTechs=${toUnlock.length} inProgressTechs=${nextProgress.length}',
    );

    updatedPlayers.add(
      player.copyWith(
        treasury: treasury,
        techUnlocked: nextUnlocked,
        researchProgressByTechId: nextProgress,
        militaryLevel: militaryLevel,
        researchSlots: nextResearchSlots,
      ),
    );
  }

  _log.i(
    'logic: research phase end turn=$turn playersWithOrders=$playersWithOrders',
  );
  return game.copyWith(players: updatedPlayers);
}

