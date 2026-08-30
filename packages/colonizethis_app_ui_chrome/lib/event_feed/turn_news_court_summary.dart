// Compact "Your court" snapshot for DLG50001 (Refs #4532).
//
// SPEC: SPEC/ui/turn-news-dialog.md § Your court block.

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

/// Qualifying court-outcome families for the turn-news footer block.
enum TurnNewsCourtFamily {
  rejected,
  research,
  combat,
  marketEconomy,
  work,
}

/// Session-only court snapshot passed into [OpenDialogEvent] for turn news.
class TurnNewsCourtSummary {
  const TurnNewsCourtSummary({
    required this.clauses,
    this.overflowFamilyCount = 0,
  });

  const TurnNewsCourtSummary.empty()
      : clauses = const [],
        overflowFamilyCount = 0;

  /// Up to three short clauses in priority order (joined by middle dot in UI).
  final List<String> clauses;

  /// Families beyond the first three shown clauses.
  final int overflowFamilyCount;

  bool get isEmpty => clauses.isEmpty && overflowFamilyCount == 0;
}

/// Labels used to render court-family clauses (typically from l10n).
class TurnNewsCourtSummaryLabels {
  const TurnNewsCourtSummaryLabels({
    required this.researchFinished,
    required this.researchFinishedMany,
    required this.researchFinishedUnknown,
    required this.decreeRefused,
    required this.decreesRefused,
    required this.battleFought,
    required this.battlesFought,
    required this.marketEconomy,
    required this.workFinished,
    required this.worksFinished,
  });

  final String Function(String techDisplayName) researchFinished;
  final String Function(int count) researchFinishedMany;
  final String Function() researchFinishedUnknown;
  final String Function() decreeRefused;
  final String Function(int count) decreesRefused;
  final String Function() battleFought;
  final String Function(int count) battlesFought;
  final String Function() marketEconomy;
  final String Function() workFinished;
  final String Function(int count) worksFinished;
}

/// Returns true when [event] belongs in the human player's turn batch.
bool acceptHumanPlayerTurnEvent(
  ct_models.GameToUIEvent event,
  String humanPlayerId,
) {
  return switch (event) {
    ct_models.AppCombatResultEvent(:final attackerId, :final defenderId) =>
      attackerId == humanPlayerId || defenderId == humanPlayerId,
    ct_models.AppNavalCombatResultEvent(
      :final side1OwnerId,
      :final side2OwnerId,
    ) =>
      side1OwnerId == humanPlayerId || side2OwnerId == humanPlayerId,
    ct_models.AppProvinceCapturedEvent(
      :final previousOwnerId,
      :final newOwnerId,
    ) =>
      previousOwnerId == humanPlayerId || newOwnerId == humanPlayerId,
    ct_models.AppDiplomacyChangeEvent(:final actorId, :final targetId) =>
      actorId == humanPlayerId || targetId == humanPlayerId,
    ct_models.AppResearchCompleteEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppOrderRejectedEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppWorkOrderCompletedEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppOverseasProfitCreditedEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppMarketTurnSummaryEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppEconomyTurnSummaryEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppPlayerProvinceDiscoveredEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppPlayerSeaZoneDiscoveredEvent(:final playerId) =>
      playerId == humanPlayerId,
    ct_models.AppOvertureAdvancedEvent(
      :final offererGpId,
      :final targetFactionId,
    ) =>
      offererGpId == humanPlayerId || targetFactionId == humanPlayerId,
    ct_models.AppSpyCaughtEvent(:final spyOwnerId, :final territoryOwnerId) =>
      spyOwnerId == humanPlayerId || territoryOwnerId == humanPlayerId,
    ct_models.AppSpyDefectedEvent(:final previousOwnerId, :final newOwnerId) =>
      previousOwnerId == humanPlayerId || newOwnerId == humanPlayerId,
    ct_models.AppGeneralMedalGainedEvent(:final playerId) =>
      playerId == humanPlayerId,
    _ => false,
  };
}

/// True when [event] should contribute to the turn-news **Your court** block.
bool isTurnNewsCourtQualifyingEvent(
  ct_models.GameToUIEvent event,
  String humanPlayerId,
) {
  if (!acceptHumanPlayerTurnEvent(event, humanPlayerId)) {
    return false;
  }
  return switch (event) {
    ct_models.AppOrderRejectedEvent() => true,
    ct_models.AppResearchCompleteEvent() => true,
    ct_models.AppCombatResultEvent() => true,
    ct_models.AppNavalCombatResultEvent() => true,
    ct_models.AppWorkOrderCompletedEvent() => true,
    ct_models.AppOverseasProfitCreditedEvent(:final totalTreasuryCredit) =>
      totalTreasuryCredit > 0,
    ct_models.AppMarketTurnSummaryEvent(
      :final totalSpent,
      :final totalReceived,
      :final carryForwardOrderCount,
    ) =>
      totalSpent > 0 ||
          totalReceived > 0 ||
          carryForwardOrderCount > 0,
    ct_models.AppEconomyTurnSummaryEvent(
      :final treasuryDelta,
      :final stockpileDeltas,
    ) =>
      treasuryDelta != 0 || stockpileDeltas.isNotEmpty,
    _ => false,
  };
}

TurnNewsCourtFamily? _courtFamilyForEvent(ct_models.GameToUIEvent event) {
  return switch (event) {
    ct_models.AppOrderRejectedEvent() => TurnNewsCourtFamily.rejected,
    ct_models.AppResearchCompleteEvent() => TurnNewsCourtFamily.research,
    ct_models.AppCombatResultEvent() => TurnNewsCourtFamily.combat,
    ct_models.AppNavalCombatResultEvent() => TurnNewsCourtFamily.combat,
    ct_models.AppWorkOrderCompletedEvent() => TurnNewsCourtFamily.work,
    ct_models.AppOverseasProfitCreditedEvent() =>
      TurnNewsCourtFamily.marketEconomy,
    ct_models.AppMarketTurnSummaryEvent() => TurnNewsCourtFamily.marketEconomy,
    ct_models.AppEconomyTurnSummaryEvent() => TurnNewsCourtFamily.marketEconomy,
    _ => null,
  };
}

const List<TurnNewsCourtFamily> _courtFamilyPriority = [
  TurnNewsCourtFamily.rejected,
  TurnNewsCourtFamily.research,
  TurnNewsCourtFamily.combat,
  TurnNewsCourtFamily.marketEconomy,
  TurnNewsCourtFamily.work,
];

/// Builds a compact court snapshot from the human-filtered turn batch.
TurnNewsCourtSummary buildTurnNewsCourtSummary({
  required List<ct_models.GameToUIEvent> events,
  required String humanPlayerId,
  required TurnNewsCourtSummaryLabels labels,
  required String Function(String techId) techDisplayName,
  required bool Function(String techId) isCatalogTech,
}) {
  final counts = <TurnNewsCourtFamily, int>{};
  final researchTechIds = <String>[];

  for (final event in events) {
    if (!isTurnNewsCourtQualifyingEvent(event, humanPlayerId)) {
      continue;
    }
    final family = _courtFamilyForEvent(event);
    if (family == null) {
      continue;
    }
    counts[family] = (counts[family] ?? 0) + 1;
    if (event is ct_models.AppResearchCompleteEvent) {
      researchTechIds.add(event.techId);
    }
  }

  if (counts.isEmpty) {
    return const TurnNewsCourtSummary.empty();
  }

  final presentFamilies = _courtFamilyPriority
      .where((family) => (counts[family] ?? 0) > 0)
      .toList(growable: false);

  String clauseForFamily(TurnNewsCourtFamily family) {
    final count = counts[family] ?? 0;
    return switch (family) {
      TurnNewsCourtFamily.rejected => count == 1
          ? labels.decreeRefused()
          : labels.decreesRefused(count),
      TurnNewsCourtFamily.research => () {
          if (count == 1 && researchTechIds.isNotEmpty) {
            final techId = researchTechIds.first;
            if (isCatalogTech(techId)) {
              return labels.researchFinished(techDisplayName(techId));
            }
            return labels.researchFinishedUnknown();
          }
          return labels.researchFinishedMany(count);
        }(),
      TurnNewsCourtFamily.combat => count == 1
          ? labels.battleFought()
          : labels.battlesFought(count),
      TurnNewsCourtFamily.marketEconomy => labels.marketEconomy(),
      TurnNewsCourtFamily.work => count == 1
          ? labels.workFinished()
          : labels.worksFinished(count),
    };
  }

  const maxClauses = 3;
  final clauses = presentFamilies
      .take(maxClauses)
      .map(clauseForFamily)
      .toList(growable: false);
  final overflowFamilyCount =
      presentFamilies.length > maxClauses ? presentFamilies.length - maxClauses : 0;

  return TurnNewsCourtSummary(
    clauses: clauses,
    overflowFamilyCount: overflowFamilyCount,
  );
}
