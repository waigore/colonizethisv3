import 'model_validation_exception.dart';

/// Industrial worker tiers.
///
/// SPEC/game/workers-and-population.md § Worker Tiers,
/// § Recruiting, Training, and Disbanding.
///
/// Canonical string ids match the `WorkerPool` plural field names already in
/// use throughout the codebase (`peasants`, `apprentices`, `journeymen`,
/// `masters`) so debug-console, save files, and order JSON share one
/// vocabulary.
enum WorkerTier {
  peasant('peasants'),
  apprentice('apprentices'),
  journeyman('journeymen'),
  master('masters');

  const WorkerTier(this.id);

  /// Canonical string id used in JSON, debug console, and order payloads.
  final String id;

  /// True when this tier requires a tech gate per SPEC § Tech gates.
  bool get isTrained => this != WorkerTier.peasant;

  /// Parse a [WorkerTier] from its canonical [id]; throws
  /// [ModelValidationException] when the value is unknown.
  static WorkerTier fromId(String id) {
    for (final tier in WorkerTier.values) {
      if (tier.id == id) return tier;
    }
    throw ModelValidationException.value(id, 'id', 'Unknown WorkerTier id');
  }

  /// Parse a [WorkerTier] from its canonical [id]; returns `null` when
  /// the value is unknown.
  static WorkerTier? tryFromId(String id) {
    for (final tier in WorkerTier.values) {
      if (tier.id == id) return tier;
    }
    return null;
  }
}
