/// Per-action combat modifiers for Quick Battle resolution.
///
/// SPEC/program/quick-battle-resolution.md.
///
/// Action effects (offense, casualties dealt, casualties taken) are expressed as
/// data ([_actionEffects]) rather than inline switch logic so the modifier table
/// is discoverable and amenable to future data-driven configuration. The
/// aggregation semantics (additive deltas from a neutral `1.0` baseline, then a
/// per-field clamp) are unchanged from the previous inline implementation.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Aggregated combat modifiers contributed by a round's chosen actions.
class ActionModifiers {
  const ActionModifiers({
    required this.offenseModifier,
    required this.casualtiesDealtModifier,
    required this.casualtiesTakenModifier,
  });

  final double offenseModifier;
  final double casualtiesDealtModifier;
  final double casualtiesTakenModifier;
}

/// Additive deltas a single [QuickBattleAction] contributes to the running
/// (offense, casualties-dealt, casualties-taken) totals before clamping.
class _ActionEffect {
  const _ActionEffect({
    this.offenseDelta = 0.0,
    this.dealtDelta = 0.0,
    this.takenDelta = 0.0,
  });

  final double offenseDelta;
  final double dealtDelta;
  final double takenDelta;
}

const double _actionModifierBaseline = 1.0;
const double _actionModifierClampMin = 0.5;
const double _actionModifierClampMax = 1.5;

/// Canonical per-action effect table. Each entry lists only the non-zero deltas;
/// omitted fields default to `0.0` (a no-op against the baseline).
const Map<QuickBattleAction, _ActionEffect> _actionEffects = {
  QuickBattleAction.volleyFire: _ActionEffect(dealtDelta: 0.15),
  QuickBattleAction.defendEntrench: _ActionEffect(takenDelta: -0.15),
  QuickBattleAction.maneuver: _ActionEffect(offenseDelta: 0.05),
  QuickBattleAction.fallBackRefuseFlank: _ActionEffect(
    offenseDelta: -0.2,
    takenDelta: -0.25,
  ),
  QuickBattleAction.assaultCharge: _ActionEffect(
    offenseDelta: 0.25,
    takenDelta: 0.1,
  ),
};

/// Sums the [_actionEffects] deltas for [actions] from the neutral baseline and
/// clamps each aggregate field to `[0.5, 1.5]`.
///
/// Deltas are applied in [actions] order; adding the `0.0` defaults is an
/// IEEE-754 identity, so the result is bit-identical to the prior switch.
ActionModifiers aggregateActionModifiers(List<QuickBattleAction> actions) {
  var offense = _actionModifierBaseline;
  var dealt = _actionModifierBaseline;
  var taken = _actionModifierBaseline;

  for (final a in actions) {
    final effect = _actionEffects[a];
    if (effect == null) continue;
    offense += effect.offenseDelta;
    dealt += effect.dealtDelta;
    taken += effect.takenDelta;
  }

  return ActionModifiers(
    offenseModifier: offense.clamp(
      _actionModifierClampMin,
      _actionModifierClampMax,
    ),
    casualtiesDealtModifier: dealt.clamp(
      _actionModifierClampMin,
      _actionModifierClampMax,
    ),
    casualtiesTakenModifier: taken.clamp(
      _actionModifierClampMin,
      _actionModifierClampMax,
    ),
  );
}
