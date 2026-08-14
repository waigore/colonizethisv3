/// Target-side first-order Effect copy for incoming overture rows (OVL30001).
/// Inverse of [buildDiplomacyConfirmPreviewLines] Establish Overture copy.
/// SPEC/ui/overture-dialogue-overlay.md; Refs #4387.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Accept and Reject Effect lines for one incoming [OvertureOffer].
class IncomingOvertureEffectLines {
  const IncomingOvertureEffectLines({
    required this.acceptEffect,
    required this.rejectEffect,
  });

  final String acceptEffect;
  final String rejectEffect;
}

/// Builds muted Cost/Effect-style lines for the human target of [stage].
IncomingOvertureEffectLines buildIncomingOvertureEffectLines({
  required String offererDisplayName,
  required OvertureStage stage,
}) {
  return IncomingOvertureEffectLines(
    acceptEffect: _acceptEffect(offererDisplayName, stage),
    rejectEffect: _rejectEffect(),
  );
}

String _acceptEffect(String offerer, OvertureStage stage) {
  return switch (stage) {
    OvertureStage.tradeConsulate =>
      'Effect: A Trade Consulate with $offerer is established this '
          'Diplomacy phase. You pay nothing; $offerer is charged only if '
          'you accept.',
    OvertureStage.embassy =>
      'Effect: An Embassy with $offerer is established. You pay nothing.',
    OvertureStage.nap =>
      'Effect: A Non-Aggression Pact with $offerer is established. There '
          'is no treasury charge.',
    OvertureStage.joinEmpire =>
      'Effect: Your realm is absorbed and your provinces transfer to '
          '$offerer.',
    OvertureStage.none =>
      'Effect: The next overture stage with $offerer is established if '
          'you accept. You pay nothing.',
  };
}

String _rejectEffect() =>
    'Effect: The offer lapses; the overture stage does not advance. You '
    'pay nothing.';
