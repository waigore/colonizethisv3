// Negotiation mood state machine. SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.
// Given current mood, offerQualityDelta (-1..1), and stallCounter, compute next mood; deterministic given seed.

import 'package:colonizethis_data/colonizethis_data.dart' show kPortraitMoodValues;

/// Default mood when no negotiation context (e.g. opening diplomacy).
const String kDefaultMood = 'considering';

/// Computes the next negotiation mood from current mood, offer quality delta, and stall count.
/// Deterministic: same (currentMood, offerQualityDelta, stallCounter, seed) → same result.
///
/// - [currentMood]: current mood (use [kDefaultMood] if unknown).
/// - [offerQualityDelta]: -1..1; positive = offer improved, negative = offer worsened.
/// - [stallCounter]: number of negotiation stalls (no progress).
/// - [seed]: for deterministic tie-breaking.
///
/// Returns one of [kPortraitMoodValues]. Caller should emit [PortraitMoodEvent] when
/// result != currentMood.
String computeNextNegotiationMood(
  String currentMood,
  double offerQualityDelta,
  int stallCounter,
  int seed,
) {
  final delta = offerQualityDelta.clamp(-1.0, 1.0);
  final stall = stallCounter.clamp(0, 99);

  // High stall count → impatient or skeptical
  if (stall >= 4) {
    return (seed & 1) == 0 ? 'impatient' : 'skeptical';
  }
  if (stall >= 2) {
    return 'calculating';
  }

  // Offer quality drives positive vs negative mood
  if (delta >= 0.5) {
    return (seed & 1) == 0 ? 'pleased' : 'gracious';
  }
  if (delta <= -0.5) {
    return (seed & 1) == 0 ? 'irritated' : 'dismissive';
  }
  if (delta <= -0.2) {
    return 'skeptical';
  }
  if (delta >= 0.2) {
    return 'considering';
  }

  // Near zero: stay considering or move to calculating
  if (currentMood == 'calculating' || (seed % 3) == 0) {
    return 'calculating';
  }
  return 'considering';
}
