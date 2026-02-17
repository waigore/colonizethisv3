import 'capital_tile.dart';
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
      };

  static Player fromJson(Map<String, dynamic> json) {
    Stockpile _readStockpile() {
      final raw = json['stockpile'];
      if (raw is Map<String, dynamic>) {
        return Stockpile.fromJson(raw);
      }
      if (raw is Map) {
        return Stockpile.fromJson(Map<String, dynamic>.from(raw));
      }
      return Stockpile.empty;
    }

    WorkerPool _readWorkerPool() {
      final raw = json['workerPool'];
      if (raw is Map<String, dynamic>) {
        return WorkerPool.fromJson(raw);
      }
      if (raw is Map) {
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
      if (raw is Map) return CapitalTile.fromJson(Map<String, dynamic>.from(raw));
      return null;
    }

    Map<String, bool>? _readTechUnlocked() {
      final raw = json['techUnlocked'];
      if (raw is! Map) return null;
      return Map<String, bool>.from(
        raw.map((k, v) => MapEntry(k.toString(), v == true)),
      );
    }

    return Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isHuman: json['isHuman'] as bool,
      stockpile: _readStockpile(),
      workerPool: _readWorkerPool(),
      treasury: _readTreasury(),
      capitalProvinceId: json['capitalProvinceId'] as String?,
      capitalTile: _readCapitalTile(),
      techUnlocked: _readTechUnlocked(),
      militaryLevel: (json['militaryLevel'] as int?),
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
          militaryLevel == other.militaryLevel;

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
      );

  static bool _mapEquals(Map<String, bool>? a, Map<String, bool>? b) {
    if (a == b) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
