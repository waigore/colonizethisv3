/// [Player] equality and hash helpers extracted so [Player] stays under the
/// models physical-line cap (Refs #4334 wave 3).
library;

import 'model_collection_equality.dart';
import 'player.dart';

bool playerEquals(Player player, Object other) =>
    identical(player, other) ||
    other is Player &&
        player.runtimeType == other.runtimeType &&
        player.id == other.id &&
        player.displayName == other.displayName &&
        player.isHuman == other.isHuman &&
        player.stockpile == other.stockpile &&
        player.workerPool == other.workerPool &&
        player.treasury == other.treasury &&
        player.capitalProvinceId == other.capitalProvinceId &&
        player.capitalTile == other.capitalTile &&
        modelNullableMapEquals(player.techUnlocked, other.techUnlocked) &&
        player.militaryLevel == other.militaryLevel &&
        player.leaderKey == other.leaderKey &&
        player.personalityId == other.personalityId &&
        modelNullableMapEquals(
          player.researchProgressByTechId,
          other.researchProgressByTechId,
        ) &&
        player.researchSlots == other.researchSlots &&
        modelNullableMapEquals(
          player.researchSlotAssignments,
          other.researchSlotAssignments,
        ) &&
        player.generalCap == other.generalCap;

int playerHashCode(Player player) => Object.hash(
  player.id,
  player.displayName,
  player.isHuman,
  player.stockpile,
  player.workerPool,
  player.treasury,
  player.capitalProvinceId,
  player.capitalTile,
  player.techUnlocked == null
      ? null
      : Object.hashAll(player.techUnlocked!.entries),
  player.militaryLevel,
  player.leaderKey,
  player.personalityId,
  player.researchProgressByTechId == null
      ? null
      : Object.hashAll(player.researchProgressByTechId!.entries),
  player.researchSlots,
  player.researchSlotAssignments == null
      ? null
      : Object.hashAll([
          for (final key in player.researchSlotAssignments!.keys.toList()..sort())
            Object.hash(key, player.researchSlotAssignments![key]),
        ]),
  player.generalCap,
);
