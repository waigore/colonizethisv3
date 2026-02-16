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
  });

  final String id;
  final String displayName;
  final bool isHuman;
  final Stockpile stockpile;
  final WorkerPool workerPool;

  /// Cash reserves for recruitment, training, and upkeep.
  /// SPEC/game/workers-and-population.md, SPEC/game/stockpiles-and-production.md.
  final int treasury;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isHuman': isHuman,
        'stockpile': stockpile.toJson(),
        'workerPool': workerPool.toJson(),
        'treasury': treasury,
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

    return Player(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isHuman: json['isHuman'] as bool,
      stockpile: _readStockpile(),
      workerPool: _readWorkerPool(),
      treasury: _readTreasury(),
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
          treasury == other.treasury;

  @override
  int get hashCode =>
      Object.hash(id, displayName, isHuman, stockpile, workerPool, treasury);
}
