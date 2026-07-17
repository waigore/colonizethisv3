/// Embassy-kickback accumulation for FRR treasury-credit aggregation
/// (#3753 R8.3; phase-7 split Refs #4049).
///
/// SPEC: [SPEC/game/world-market-first-right-of-refusal.md](
/// ../../../../../../SPEC/game/world-market-first-right-of-refusal.md) and
/// [SPEC/program/world-market-resolution.md § First right of refusal](
/// ../../../../../../SPEC/program/world-market-resolution.md).
///
/// Extracted from `first_right_credits.dart` so the D4 aggregation library
/// keeps one primary concern (tile-owner full-share credits + result
/// rollup) while the kickback path stays a separable pure helper. Like the
/// rest of the FRR family this is deterministic for fixed inputs, silent,
/// and RNG-free.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'first_right_profit.dart';
import 'gp_treasury_credit_accumulator.dart';

/// Credits embassy kickbacks (#3753 R8.3) for a single [deal] to every
/// embassy-holding GP returned by [embassyGpRelationsFor] except the tile
/// [owningGpId]. No-op when [embassyGpRelationsFor] is `null` or the
/// [sourceFactionId] is empty. The callback's iteration order is preserved
/// for determinism.
void accumulateEmbassyKickbacksForDeal({
  required FilledDeal deal,
  required String sourceFactionId,
  required String owningGpId,
  required Map<String, num> Function(String sourceFactionId)?
  embassyGpRelationsFor,
  required GpTreasuryCreditAccumulator<double> kickbackByGp,
}) {
  if (embassyGpRelationsFor == null || sourceFactionId.isEmpty) return;
  final embassyRelations = embassyGpRelationsFor(sourceFactionId);
  for (final entry in embassyRelations.entries) {
    final gpId = entry.key;
    if (gpId.isEmpty || gpId == owningGpId) continue;
    final kickback = computeEmbassyKickback(
      relationScore: entry.value,
      filledQuantity: deal.quantity,
      pricePerUnit: deal.pricePerUnit,
    );
    if (kickback > 0.0) {
      kickbackByGp.add(gpId, kickback);
    }
  }
}
