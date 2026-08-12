import 'capital_tile.dart';
import 'player_equality.dart';
import 'player_serialization.dart';
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

  Map<String, dynamic> toJson() => encodePlayerToJson(this);

  static Player fromJson(Map<String, dynamic> json) => decodePlayerFromJson(json);

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
  bool operator ==(Object other) => playerEquals(this, other);

  @override
  int get hashCode => playerHashCode(this);
}
