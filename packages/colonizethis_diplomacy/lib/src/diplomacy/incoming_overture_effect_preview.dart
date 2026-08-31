/// Target-side first-order Effect copy for incoming overture rows (OVL30001).
/// Inverse of [buildDiplomacyConfirmPreviewLines] Establish Overture copy.
/// SPEC/ui/overture-dialogue-overlay.md; Refs #4387, #4682.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_resolver.dart';

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
  Game? game,
  String? targetFactionId,
}) {
  final targetIsMinorOrTribe =
      game != null &&
      targetFactionId != null &&
      isMinorOrTribe(game, targetFactionId);
  return IncomingOvertureEffectLines(
    acceptEffect: _acceptEffect(
      offererDisplayName,
      stage,
      targetIsMinorOrTribe: targetIsMinorOrTribe,
    ),
    rejectEffect: _rejectEffect(),
  );
}

String _acceptEffect(
  String offerer,
  OvertureStage stage, {
  required bool targetIsMinorOrTribe,
}) {
  return switch (stage) {
    OvertureStage.tradeConsulate =>
      targetIsMinorOrTribe
          ? 'Effect: If accepted, $offerer may Explore and Prospect on your '
                'land. You pay nothing; $offerer is charged only if you accept.'
          : 'Effect: A Trade Consulate with $offerer is established this '
                'Diplomacy phase. You pay nothing; $offerer is charged only if '
                'you accept.',
    OvertureStage.embassy =>
      targetIsMinorOrTribe
          ? 'Effect: If accepted, $offerer may Grant Aid, Set Subsidy, and '
                'Purchase land toward your court. You pay nothing.'
          : 'Effect: An Embassy with $offerer is established. You pay nothing.',
    OvertureStage.nap =>
      'Effect: A Non-Aggression Pact with $offerer is established. There is '
          'no treasury charge. The pact does not by itself block Declare War.',
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
