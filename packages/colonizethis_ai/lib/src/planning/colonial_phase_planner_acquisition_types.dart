/// Method by which a COLONIAL acquisition target should be pursued
/// (issue #2509 § COLONIAL phase planner § planColonialAcquisition).
///
/// Three methods are defined by the spec — Join Empire is the cheapest
/// path and always preferred first when available; `purchase_land`
/// applies when an idle Merchant and a valid purchase tile are present;
/// `declareWar` applies when treasury / regiments support the conquest
/// path and the target is sea-reachable. All three methods are emitted
/// by [planColonialAcquisition]; the structural priority Method 1 → 2 →
/// 3 mirrors the spec's "always preferred first" Join Empire framing
/// and the "deprioritize war behind Join Empire and purchase_land"
/// turn-110 guidance.
enum AcquisitionMethod {
  /// `establishOverture` advancing the chain to `joinEmpire`. The
  /// fastest, cheapest acquisition path (issue #2509 § Acquisition
  /// method 1).
  joinEmpire,

  /// `purchase_land` work order for an idle Merchant unit (issue
  /// #2509 § Acquisition method 2).
  purchaseLand,

  /// `declareWar` + NW army move toward a sea-reachable tribe / minor
  /// (issue #2509 § Acquisition method 3). Emitted by
  /// [planColonialAcquisition] only when Join Empire and
  /// `purchase_land` both yielded no target this turn and the active
  /// player can afford the cheapest regiment build with at least one
  /// standing regiment already in service.
  declareWar,
}

/// Deterministic acquisition target picked by [planColonialAcquisition].
///
/// Pairs the faction id owning the chosen NW province with the
/// [AcquisitionMethod] the orchestrator should use this turn. The pair
/// is stable: identical inputs always yield identical targets (Refs
/// #2509 Must-have #7). The pair is materialized as a small value
/// class (not a record) to keep value-equality semantics explicit for
/// tests and to mirror the shape of other phase-planner return types
/// under construction in this file.
class ColonialAcquisitionTarget {
  const ColonialAcquisitionTarget({
    required this.targetFactionId,
    required this.method,
  });

  /// Faction id of the tribe or minor that currently owns the chosen
  /// NW province. Never a Great Power — Join Empire toward a GP is
  /// gated by Empire Building tech and the "nearly defeated" check in
  /// the join-empire validator (see
  /// `join_empire_validator.dart`), neither of which fits the COLONIAL
  /// phase's "acquire tribe / minor NW" objective. The planner skips
  /// GP-owned NW provinces structurally.
  final String targetFactionId;

  /// Resolution path the orchestrator should use. The planner can
  /// return any of [AcquisitionMethod.joinEmpire] (Acquisition method
  /// 1), [AcquisitionMethod.purchaseLand] (Acquisition method 2), or
  /// [AcquisitionMethod.declareWar] (Acquisition method 3) per the
  /// structural Method 1 → 2 → 3 priority documented on
  /// [planColonialAcquisition].
  final AcquisitionMethod method;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColonialAcquisitionTarget &&
          targetFactionId == other.targetFactionId &&
          method == other.method;

  @override
  int get hashCode => Object.hash(targetFactionId, method);

  @override
  String toString() =>
      'ColonialAcquisitionTarget('
      'targetFactionId: $targetFactionId, method: $method)';
}
