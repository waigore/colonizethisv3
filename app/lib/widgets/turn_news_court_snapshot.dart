// Compact last-turn court snapshot for DLG50001. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Qualifying court families, in display priority order (Refs #4532).
enum TurnNewsCourtFamily {
  orderRejected,
  researchComplete,
  combat,
  marketEconomy,
  workFinished,
}

/// One present family in the court snapshot.
class TurnNewsCourtFamilyHit {
  const TurnNewsCourtFamilyHit({
    required this.family,
    required this.count,
    this.techDisplayName,
  });

  final TurnNewsCourtFamily family;
  final int count;
  final String? techDisplayName;
}

/// Session-only court summary passed in `OpenDialogEvent` params.
class TurnNewsCourtSnapshot {
  const TurnNewsCourtSnapshot({
    this.families = const <TurnNewsCourtFamilyHit>[],
    this.overflowFamilyCount = 0,
  });

  static const empty = TurnNewsCourtSnapshot();

  static const int maxClauses = 3;

  final List<TurnNewsCourtFamilyHit> families;
  final int overflowFamilyCount;

  bool get isEmpty => families.isEmpty;
}

/// True when [event] is a human-scoped court family (not gazette, not spies).
bool isTurnNewsCourtSourceEvent(GameToUIEvent event, String humanPlayerId) {
  return switch (event) {
    AppOrderRejectedEvent(:final playerId) => playerId == humanPlayerId,
    AppResearchCompleteEvent(:final playerId) => playerId == humanPlayerId,
    AppCombatResultEvent(:final attackerId, :final defenderId) =>
      attackerId == humanPlayerId || defenderId == humanPlayerId,
    AppNavalCombatResultEvent(:final side1OwnerId, :final side2OwnerId) =>
      side1OwnerId == humanPlayerId || side2OwnerId == humanPlayerId,
    AppWorkOrderCompletedEvent(:final playerId) => playerId == humanPlayerId,
    AppOverseasProfitCreditedEvent(
      :final playerId,
      :final totalTreasuryCredit,
    ) =>
      playerId == humanPlayerId && totalTreasuryCredit > 0,
    AppMarketTurnSummaryEvent(
      :final playerId,
      :final totalSpent,
      :final totalReceived,
      :final carryForwardOrderCount,
    ) =>
      playerId == humanPlayerId &&
          (totalSpent > 0 || totalReceived > 0 || carryForwardOrderCount > 0),
    AppEconomyTurnSummaryEvent(
      :final playerId,
      :final treasuryDelta,
      :final stockpileDeltas,
    ) =>
      playerId == humanPlayerId &&
          (treasuryDelta != 0 || stockpileDeltas.isNotEmpty),
    _ => false,
  };
}

TurnNewsCourtFamily? _familyOf(GameToUIEvent event) {
  return switch (event) {
    AppOrderRejectedEvent() => TurnNewsCourtFamily.orderRejected,
    AppResearchCompleteEvent() => TurnNewsCourtFamily.researchComplete,
    AppCombatResultEvent() ||
    AppNavalCombatResultEvent() => TurnNewsCourtFamily.combat,
    AppOverseasProfitCreditedEvent() ||
    AppMarketTurnSummaryEvent() ||
    AppEconomyTurnSummaryEvent() => TurnNewsCourtFamily.marketEconomy,
    AppWorkOrderCompletedEvent() => TurnNewsCourtFamily.workFinished,
    _ => null,
  };
}

/// Builds at most [TurnNewsCourtSnapshot.maxClauses] priority clauses.
TurnNewsCourtSnapshot buildTurnNewsCourtSnapshot({
  required List<GameToUIEvent> events,
  required String? Function(String techId) catalogTechDisplayName,
}) {
  final counts = <TurnNewsCourtFamily, int>{};
  String? researchName;
  for (final event in events) {
    final family = _familyOf(event);
    if (family == null) continue;
    counts[family] = (counts[family] ?? 0) + 1;
    if (event is AppResearchCompleteEvent && researchName == null) {
      researchName = catalogTechDisplayName(event.techId);
    }
  }
  final hits = <TurnNewsCourtFamilyHit>[];
  for (final family in TurnNewsCourtFamily.values) {
    final count = counts[family];
    if (count == null || count <= 0) continue;
    hits.add(
      TurnNewsCourtFamilyHit(
        family: family,
        count: count,
        techDisplayName: family == TurnNewsCourtFamily.researchComplete
            ? researchName
            : null,
      ),
    );
  }
  if (hits.isEmpty) return TurnNewsCourtSnapshot.empty;
  if (hits.length <= TurnNewsCourtSnapshot.maxClauses) {
    return TurnNewsCourtSnapshot(families: hits);
  }
  return TurnNewsCourtSnapshot(
    families: hits.take(TurnNewsCourtSnapshot.maxClauses).toList(),
    overflowFamilyCount: hits.length - TurnNewsCourtSnapshot.maxClauses,
  );
}

/// Accumulates human court events until turn-complete commit.
class TurnNewsCourtAccumulator {
  final List<GameToUIEvent> _pending = [];

  void consider(GameToUIEvent event, String humanPlayerId) {
    if (!isTurnNewsCourtSourceEvent(event, humanPlayerId)) return;
    _pending.add(event);
  }

  TurnNewsCourtSnapshot commit({
    required String? Function(String techId) catalogTechDisplayName,
  }) {
    final snapshot = buildTurnNewsCourtSnapshot(
      events: List<GameToUIEvent>.unmodifiable(_pending),
      catalogTechDisplayName: catalogTechDisplayName,
    );
    _pending.clear();
    return snapshot;
  }
}
