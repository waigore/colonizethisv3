import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../turn_event_sink.dart';

/// Emits [OverseasProfitCreditedEvent] for GPs with positive combined
/// overseas-profit credits (Refs #4226).
void emitOverseasProfitCreditedEvents({
  required Map<String, List<OverseasProfitCreditRecord>> recordsByGpId,
  required int turn,
  required TurnEventSink sink,
}) {
  final totals = overseasProfitTreasuryTotalByGpId(recordsByGpId);
  final sortedGpIds = totals.keys.toList()..sort();
  for (final gpId in sortedGpIds) {
    final total = totals[gpId]!;
    if (total <= 0) continue;
    final records = recordsByGpId[gpId] ?? const <OverseasProfitCreditRecord>[];
    sink.emit(
      OverseasProfitCreditedEvent(
        playerId: gpId,
        totalTreasuryCredit: total,
        creditCount: records.length,
        turnNumber: turn,
      ),
    );
  }
}
