/// Plain-language copy for turn-event feed rows (Refs #4145).
class CtEventFeedText {
  CtEventFeedText._();

  static const Map<String, String> orderRejectedReasonLabels = {
    'insufficient_treasury': 'insufficient treasury',
    'invalid_destination': 'invalid destination',
    'insufficient_resources': 'insufficient resources',
    'insufficient_materials': 'insufficient materials',
    'invalid_order': 'invalid order',
  };

  static String orderRejectedReasonLabel(String reasonCode) {
    final mapped = orderRejectedReasonLabels[reasonCode];
    if (mapped != null) {
      return mapped;
    }
    if (reasonCode.contains(' ')) {
      return reasonCode;
    }
    return reasonCode.replaceAll('_', ' ');
  }

  static String orderRejectedLine(String reasonCode) =>
      'Order rejected: ${orderRejectedReasonLabel(reasonCode)}.';

  static String overseasProfitCreditedLine(int amount, int count) =>
      'Overseas profit credited: £$amount from $count rival purchase(s). '
      'Tap to open Deal Book.';

  static String marketTurnSummaryLine({
    required int totalSpent,
    required int totalReceived,
    required int carryForwardOrderCount,
  }) {
    final parts = <String>[];
    if (totalSpent > 0) {
      parts.add('bought £$totalSpent');
    }
    if (totalReceived > 0) {
      parts.add('sold £$totalReceived');
    }
    if (carryForwardOrderCount > 0) {
      if (parts.isEmpty) {
        return 'Market: $carryForwardOrderCount orders carried forward';
      }
      parts.add('$carryForwardOrderCount orders carried');
    }
    return 'Market: ${parts.join(' · ')}';
  }

  static String economyTurnSummaryLine({
    required int treasuryDelta,
    required Map<String, int> stockpileDeltas,
    required String Function(String commodityId) commodityDisplayName,
    int maxCommodityMovers = 3,
  }) {
    final parts = <String>[];
    if (treasuryDelta != 0) {
      final sign = treasuryDelta > 0 ? '+' : '';
      parts.add('treasury $sign£$treasuryDelta');
    }
    final sorted = stockpileDeltas.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.abs().compareTo(a.value.abs());
        if (cmp != 0) {
          return cmp;
        }
        return a.key.compareTo(b.key);
      });
    for (final entry in sorted.take(maxCommodityMovers)) {
      final sign = entry.value > 0 ? '+' : '';
      parts.add('${commodityDisplayName(entry.key)} $sign${entry.value}');
    }
    final remaining = sorted.length - maxCommodityMovers;
    if (remaining > 0) {
      parts.add('+$remaining more');
    }
    return 'Realm: ${parts.join(' · ')}';
  }

  static String generalMedalGainedLine(int newMedals) =>
      'General gained a medal (now $newMedals).';

  static String generalMedalGainedAtProvinceLine(
    String provinceLabel,
    int newMedals,
  ) =>
      'Victory at $provinceLabel: a general earned a medal (now $newMedals).';

  static String combatResolvedLine({
    required String provinceLabel,
    required String winnerLabel,
    required String defeatedLabel,
  }) =>
      '$provinceLabel battle resolved! $winnerLabel defeated $defeatedLabel!';

  static String provinceCapturedLine({
    required String provinceLabel,
    required String ownerLabel,
  }) =>
      '$provinceLabel captured! $ownerLabel now controls it!';

  static String navalCombatResolvedLine({
    required String seaZoneLabel,
    required String outcomeName,
  }) =>
      '$seaZoneLabel naval battle resolved! Outcome: $outcomeName!';

  static String provinceDiscoveredLine(String provinceLabel) =>
      '$provinceLabel discovered!';

  static String seaZoneDiscoveredLine(String seaZoneLabel) =>
      '$seaZoneLabel discovered!';

  static String overtureAdvancedLine({
    required String offererLabel,
    required String targetLabel,
    required String stageLabel,
  }) =>
      'Overture advanced! $offererLabel with $targetLabel: $stageLabel!';

  static String spyCaughtLine({
    required String mapPlayerId,
    required String provinceLabel,
    required String spyOwnerLabel,
    required String territoryOwnerLabel,
    required String territoryOwnerId,
  }) =>
      mapPlayerId == territoryOwnerId
          ? '$provinceLabel — enemy spy from $spyOwnerLabel caught and eliminated!'
          : 'Spy caught in $provinceLabel! $territoryOwnerLabel eliminated your agent!';

  static String spyDefectedLine({
    required String mapPlayerId,
    required String provinceLabel,
    required String previousOwnerLabel,
    required String newOwnerLabel,
    required String newOwnerId,
  }) =>
      mapPlayerId == newOwnerId
          ? '$provinceLabel — enemy spy from $previousOwnerLabel defected to your side!'
          : 'Spy defected in $provinceLabel! Agent joined $newOwnerLabel!';

  static String workOrderCompletedLine({
    required String provinceLabel,
    required String workTargetLabel,
  }) =>
      '$provinceLabel work completed! $workTargetLabel finished!';

  static const String eventResolvedFallback = 'Event resolved!';
}
