/// [Player] JSON encode/decode helpers extracted so [Player] stays under the
/// models physical-line cap (Refs #4334 wave 3). Public API remains
/// [Player.toJson] / [Player.fromJson] on the aggregate.
library;

import 'capital_tile.dart';
import 'player.dart';
import 'province_id.dart';
import 'research_slot_assignment.dart';
import 'stockpile.dart';
import 'worker_pool.dart';

Map<String, dynamic> encodePlayerToJson(Player player) => {
  'id': player.id,
  'displayName': player.displayName,
  'isHuman': player.isHuman,
  'stockpile': player.stockpile.toJson(),
  'workerPool': player.workerPool.toJson(),
  'treasury': player.treasury,
  if (player.capitalProvinceId != null)
    'capitalProvinceId': player.capitalProvinceId,
  if (player.capitalTile != null) 'capitalTile': player.capitalTile!.toJson(),
  if (player.techUnlocked != null && player.techUnlocked!.isNotEmpty)
    'techUnlocked': player.techUnlocked,
  if (player.militaryLevel != null) 'militaryLevel': player.militaryLevel,
  if (player.leaderKey != null && player.leaderKey!.isNotEmpty)
    'leaderKey': player.leaderKey,
  if (player.personalityId != null && player.personalityId!.isNotEmpty)
    'personalityId': player.personalityId,
  if (player.researchProgressByTechId != null &&
      player.researchProgressByTechId!.isNotEmpty)
    'researchProgressByTechId': player.researchProgressByTechId,
  if (player.researchSlots != null) 'researchSlots': player.researchSlots,
  if (player.researchSlotAssignments != null &&
      player.researchSlotAssignments!.isNotEmpty)
    'researchSlotAssignments': {
      for (final e in player.researchSlotAssignments!.entries)
        e.key.toString(): e.value.toJson(),
    },
  if (player.generalCap != null) 'generalCap': player.generalCap,
};

Player decodePlayerFromJson(Map<String, dynamic> json) {
  Stockpile readStockpile() {
    final raw = json['stockpile'];
    if (raw is Map<String, dynamic>) {
      return Stockpile.fromJson(raw);
    }
    if (raw is Map<Object?, Object?>) {
      return Stockpile.fromJson(Map<String, dynamic>.from(raw));
    }
    return Stockpile.empty;
  }

  WorkerPool readWorkerPool() {
    final raw = json['workerPool'];
    if (raw is Map<String, dynamic>) {
      return WorkerPool.fromJson(raw);
    }
    if (raw is Map<Object?, Object?>) {
      return WorkerPool.fromJson(Map<String, dynamic>.from(raw));
    }
    return WorkerPool.empty;
  }

  int readTreasury() {
    final value = json['treasury'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  CapitalTile? readCapitalTile() {
    final raw = json['capitalTile'];
    if (raw is Map<String, dynamic>) return CapitalTile.fromJson(raw);
    if (raw is Map<Object?, Object?>) {
      return CapitalTile.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Map<String, bool>? readTechUnlocked() {
    final raw = json['techUnlocked'];
    if (raw is! Map<Object?, Object?>) return null;
    return Map<String, bool>.from(
      raw.map((k, v) => MapEntry(k.toString(), v == true)),
    );
  }

  Map<String, int>? readResearchProgress() {
    final raw = json['researchProgressByTechId'];
    if (raw is! Map<Object?, Object?>) return null;
    return Map<String, int>.from(
      raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
    );
  }

  Map<int, ResearchSlotAssignment>? readResearchSlotAssignments() {
    final raw = json['researchSlotAssignments'];
    if (raw is! Map<Object?, Object?>) return null;
    final out = <int, ResearchSlotAssignment>{};
    raw.forEach((key, value) {
      final slotIndex = int.tryParse(key.toString());
      if (slotIndex == null || slotIndex < 0) return;
      if (value is! Map<Object?, Object?>) return;
      final assignment = ResearchSlotAssignment.fromJson(
        Map<String, dynamic>.from(value),
      );
      if (assignment.techId.isEmpty) return;
      out[slotIndex] = assignment;
    });
    return out;
  }

  final slotAssignments = readResearchSlotAssignments();

  return Player(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    isHuman: json['isHuman'] as bool,
    stockpile: readStockpile(),
    workerPool: readWorkerPool(),
    treasury: readTreasury(),
    capitalProvinceId: ProvinceId.requirePrefixedOrNull(
      json['capitalProvinceId'] as String?,
      fieldName: 'Player.capitalProvinceId',
    ),
    capitalTile: readCapitalTile(),
    techUnlocked: readTechUnlocked(),
    militaryLevel: (json['militaryLevel'] as int?),
    leaderKey: json['leaderKey'] as String?,
    personalityId: json['personalityId'] as String?,
    researchProgressByTechId: pruneOrphanedPlayerResearchProgress(
      readResearchProgress(),
      slotAssignments,
    ),
    researchSlots: (json['researchSlots'] as num?)?.toInt(),
    researchSlotAssignments: slotAssignments,
    generalCap: (json['generalCap'] as num?)?.toInt(),
  );
}

/// Drops `researchProgressByTechId` entries whose tech is not bound to any
/// persisted slot in [assignments]. Legacy saves predate
/// `researchSlotAssignments` and may carry in-progress research that no
/// longer occupies a slot; per SPEC/game/research-state.md § Slot Occupancy
/// Persistence such orphaned progress is forfeited on load so every retained
/// in-progress tech is guaranteed to occupy a slot. Entries bound to a slot
/// are preserved verbatim. SPEC/game/research-state.md (load discard, d3-8).
Map<String, int>? pruneOrphanedPlayerResearchProgress(
  Map<String, int>? progress,
  Map<int, ResearchSlotAssignment>? assignments,
) {
  if (progress == null || progress.isEmpty) return progress;
  final boundTechIds = <String>{
    if (assignments != null)
      for (final assignment in assignments.values) assignment.techId,
  };
  return <String, int>{
    for (final entry in progress.entries)
      if (boundTechIds.contains(entry.key)) entry.key: entry.value,
  };
}
