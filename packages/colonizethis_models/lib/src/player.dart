import 'capital_tile.dart';
import 'province_id.dart';
import 'research_slot_assignment.dart';
import 'stockpile.dart';
import 'worker_pool.dart';

/// Great Power. SPEC/game/world-model.
class Player {
  const Player({
    required this.id,
    required this.displayName,
    required this.isHuman,
    this.stockpile = Stockpile.empty,
    this.workerPool = WorkerPool.empty,
    this.treasury = 0,
    this.capitalProvinceId,
    this.capitalTile,
    this.techUnlocked,
    this.militaryLevel,
    this.leaderKey,
    this.personalityId,
    this.researchProgressByTechId,
    this.researchSlots,
    this.researchSlotAssignments,
    this.generalCap,
  });

  final String id;
  final String displayName;
  final bool isHuman;
  final Stockpile stockpile;
  final WorkerPool workerPool;

  /// Cash reserves for recruitment, training, and upkeep.
  /// SPEC/game/workers-and-population.md, SPEC/game/stockpiles-and-production.md.
  final int treasury;

  /// Capital province id. Set in capital-choice phase. SPEC/game/capital-and-connectivity.
  final String? capitalProvinceId;

  /// Capital tile within the capital province. Null = legacy / not set.
  final CapitalTile? capitalTile;

  /// Tech id -> unlocked. Optional; Phase 2 may use constant extraction cap.
  final Map<String, bool>? techUnlocked;

  /// Military level (1–4) from tech; highest regiment era available. Used for minor parity.
  final int? militaryLevel;

  /// Leader variant key for bonus lookups (combat, economy). Set during game setup. GDD 09.
  final String? leaderKey;

  /// Optional archetype id for AI personality weights; when null, lookups use [leaderKey].
  final String? personalityId;

  /// Accumulated research progress per tech id (research points).
  /// Phase 5: used by research resolution. Null/empty = no progress tracked yet.
  final Map<String, int>? researchProgressByTechId;

  /// Number of concurrent research slots available to this player.
  /// Default is 3; University tech can raise this to 4. When null, treat as 3.
  final int? researchSlots;

  /// Persisted slot index (`0..researchSlots-1`) → `{techId, funding}` occupancy.
  /// Durable record of which tech occupies each slot, surviving turn resolution
  /// and save/load; distinct from the per-turn `Orders.researchOrdersByPlayerId`
  /// UI mutation surface. Null/empty on legacy saves = no slot assignments.
  /// SPEC/game/research-state.md § Slot Occupancy Persistence.
  final Map<int, ResearchSlotAssignment>? researchSlotAssignments;

  /// Tech-gated general cap for this Great Power (min/max generals in the pool).
  /// 1 at game start; grows with military/diplomacy techs. Null in legacy saves
  /// (treated as derive-from-tech or 1 on load). SPEC/game/military-generals.md.
  final int? generalCap;

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'isHuman': isHuman,
    'stockpile': stockpile.toJson(),
    'workerPool': workerPool.toJson(),
    'treasury': treasury,
    if (capitalProvinceId != null) 'capitalProvinceId': capitalProvinceId,
    if (capitalTile != null) 'capitalTile': capitalTile!.toJson(),
    if (techUnlocked != null && techUnlocked!.isNotEmpty)
      'techUnlocked': techUnlocked,
    if (militaryLevel != null) 'militaryLevel': militaryLevel,
    if (leaderKey != null && leaderKey!.isNotEmpty) 'leaderKey': leaderKey,
    if (personalityId != null && personalityId!.isNotEmpty)
      'personalityId': personalityId,
    if (researchProgressByTechId != null &&
        researchProgressByTechId!.isNotEmpty)
      'researchProgressByTechId': researchProgressByTechId,
    if (researchSlots != null) 'researchSlots': researchSlots,
    if (researchSlotAssignments != null && researchSlotAssignments!.isNotEmpty)
      'researchSlotAssignments': {
        for (final e in researchSlotAssignments!.entries)
          e.key.toString(): e.value.toJson(),
      },
    if (generalCap != null) 'generalCap': generalCap,
  };

  static Player fromJson(Map<String, dynamic> json) {
    Stockpile _readStockpile() {
      final raw = json['stockpile'];
      if (raw is Map<String, dynamic>) {
        return Stockpile.fromJson(raw);
      }
      if (raw is Map<Object?, Object?>) {
        return Stockpile.fromJson(Map<String, dynamic>.from(raw));
      }
      return Stockpile.empty;
    }

    WorkerPool _readWorkerPool() {
      final raw = json['workerPool'];
      if (raw is Map<String, dynamic>) {
        return WorkerPool.fromJson(raw);
      }
      if (raw is Map<Object?, Object?>) {
        return WorkerPool.fromJson(Map<String, dynamic>.from(raw));
      }
      return WorkerPool.empty;
    }

    int _readTreasury() {
      final value = json['treasury'];
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    CapitalTile? _readCapitalTile() {
      final raw = json['capitalTile'];
      if (raw is Map<String, dynamic>) return CapitalTile.fromJson(raw);
      if (raw is Map<Object?, Object?>)
        return CapitalTile.fromJson(Map<String, dynamic>.from(raw));
      return null;
    }

    Map<String, bool>? _readTechUnlocked() {
      final raw = json['techUnlocked'];
      if (raw is! Map<Object?, Object?>) return null;
      return Map<String, bool>.from(
        raw.map((k, v) => MapEntry(k.toString(), v == true)),
      );
    }

    Map<String, int>? _readResearchProgress() {
      final raw = json['researchProgressByTechId'];
      if (raw is! Map<Object?, Object?>) return null;
      return Map<String, int>.from(
        raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
      );
    }

    Map<int, ResearchSlotAssignment>? _readResearchSlotAssignments() {
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

    return Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isHuman: json['isHuman'] as bool,
      stockpile: _readStockpile(),
      workerPool: _readWorkerPool(),
      treasury: _readTreasury(),
      capitalProvinceId: ProvinceId.requirePrefixedOrNull(
        json['capitalProvinceId'] as String?,
        fieldName: 'Player.capitalProvinceId',
      ),
      capitalTile: _readCapitalTile(),
      techUnlocked: _readTechUnlocked(),
      militaryLevel: (json['militaryLevel'] as int?),
      leaderKey: json['leaderKey'] as String?,
      personalityId: json['personalityId'] as String?,
      researchProgressByTechId: _readResearchProgress(),
      researchSlots: (json['researchSlots'] as num?)?.toInt(),
      researchSlotAssignments: _readResearchSlotAssignments(),
      generalCap: (json['generalCap'] as num?)?.toInt(),
    );
  }

  Player copyWith({
    String? id,
    String? displayName,
    bool? isHuman,
    Stockpile? stockpile,
    WorkerPool? workerPool,
    int? treasury,
    String? capitalProvinceId,
    CapitalTile? capitalTile,
    Map<String, bool>? techUnlocked,
    int? militaryLevel,
    String? leaderKey,
    String? personalityId,
    Map<String, int>? researchProgressByTechId,
    int? researchSlots,
    Map<int, ResearchSlotAssignment>? researchSlotAssignments,
    int? generalCap,
  }) {
    return Player(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isHuman: isHuman ?? this.isHuman,
      stockpile: stockpile ?? this.stockpile,
      workerPool: workerPool ?? this.workerPool,
      treasury: treasury ?? this.treasury,
      capitalProvinceId: capitalProvinceId ?? this.capitalProvinceId,
      capitalTile: capitalTile ?? this.capitalTile,
      techUnlocked: techUnlocked ?? this.techUnlocked,
      militaryLevel: militaryLevel ?? this.militaryLevel,
      leaderKey: leaderKey ?? this.leaderKey,
      personalityId: personalityId ?? this.personalityId,
      researchProgressByTechId:
          researchProgressByTechId ?? this.researchProgressByTechId,
      researchSlots: researchSlots ?? this.researchSlots,
      researchSlotAssignments:
          researchSlotAssignments ?? this.researchSlotAssignments,
      generalCap: generalCap ?? this.generalCap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          isHuman == other.isHuman &&
          stockpile == other.stockpile &&
          workerPool == other.workerPool &&
          treasury == other.treasury &&
          capitalProvinceId == other.capitalProvinceId &&
          capitalTile == other.capitalTile &&
          _mapEquals(techUnlocked, other.techUnlocked) &&
          militaryLevel == other.militaryLevel &&
          leaderKey == other.leaderKey &&
          personalityId == other.personalityId &&
          _intMapEquals(
            researchProgressByTechId,
            other.researchProgressByTechId,
          ) &&
          researchSlots == other.researchSlots &&
          _slotAssignmentsEqual(
            researchSlotAssignments,
            other.researchSlotAssignments,
          ) &&
          generalCap == other.generalCap;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    isHuman,
    stockpile,
    workerPool,
    treasury,
    capitalProvinceId,
    capitalTile,
    techUnlocked == null ? null : Object.hashAll(techUnlocked!.entries),
    militaryLevel,
    leaderKey,
    personalityId,
    researchProgressByTechId == null
        ? null
        : Object.hashAll(researchProgressByTechId!.entries),
    researchSlots,
    researchSlotAssignments == null
        ? null
        : Object.hashAll([
            for (final key in researchSlotAssignments!.keys.toList()..sort())
              Object.hash(key, researchSlotAssignments![key]),
          ]),
    generalCap,
  );

  static bool _mapEquals(Map<String, bool>? a, Map<String, bool>? b) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _intMapEquals(Map<String, int>? a, Map<String, int>? b) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _slotAssignmentsEqual(
    Map<int, ResearchSlotAssignment>? a,
    Map<int, ResearchSlotAssignment>? b,
  ) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
