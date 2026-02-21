import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const int _defaultResearchSlots = 3;

/// Research phase resolution. SPEC/program/research-resolution.md.
Game resolveResearchPhase(Game game, Orders orders) {
  final researchByPlayer = orders.researchOrdersByPlayerId;
  if (researchByPlayer.isEmpty) {
    return game;
  }

  final updatedPlayers = <Player>[];

  for (final p in game.players) {
    final player = p;
    final playerOrders =
        researchByPlayer[player.id] ?? const <ResearchOrder>[];
    if (playerOrders.isEmpty) {
      updatedPlayers.add(player);
      continue;
    }

    final slots = player.researchSlots ?? _defaultResearchSlots;
    if (slots <= 0) {
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
    var treasury = player.treasury;

    int _pointsForFunding(ResearchFundingLevel level) {
      switch (level) {
        case ResearchFundingLevel.none:
          return 0;
        case ResearchFundingLevel.low:
          return 100;
        case ResearchFundingLevel.medium:
          return 300;
        case ResearchFundingLevel.high:
          return 800;
        case ResearchFundingLevel.maximum:
          // Maximum funding has 2.5x efficiency bonus
          return 2500;
      }
    }

    int _treasuryForFunding(ResearchFundingLevel level) {
      switch (level) {
        case ResearchFundingLevel.none:
          return 0;
        case ResearchFundingLevel.low:
          return 50;
        case ResearchFundingLevel.medium:
          return 150;
        case ResearchFundingLevel.high:
          return 400;
        case ResearchFundingLevel.maximum:
          return 1000;
      }
    }

    // 1–4: validate, deduct treasury, and add progress per slot.
    for (final order in playerOrders) {
      if (order.slotIndex < 0 || order.slotIndex >= slots) {
        continue;
      }
      final techId = order.techId;
      if (techId.isEmpty) {
        // Cancel slot: Phase 5 spec says cancelling loses progress; with a
        // per-tech progress map we treat this as a no-op here.
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

      final spend = _treasuryForFunding(order.funding);
      if (spend <= 0 || treasury < spend) {
        continue;
      }

      final points = _pointsForFunding(order.funding);
      if (points <= 0) {
        continue;
      }

      treasury -= spend;
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

    Map<String, int>? nextProgress;
    if (progress.isNotEmpty) {
      nextProgress = progress;
    }

    final nextUnlockedForLevel = nextUnlocked ?? workingUnlocked;
    final militaryLevel = militaryLevelForUnlocked(nextUnlockedForLevel);

    updatedPlayers.add(
      player.copyWith(
        treasury: treasury,
        techUnlocked: nextUnlocked,
        researchProgressByTechId: nextProgress,
        militaryLevel: militaryLevel,
      ),
    );
  }

  return game.copyWith(players: updatedPlayers);
}

