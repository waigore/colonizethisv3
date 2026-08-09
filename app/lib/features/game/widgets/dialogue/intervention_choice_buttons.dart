import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Stable key for the **Intervene** choice button (#2867 R26b). The
/// intervene button always renders with the default / primary
/// `CtNinePatchButton` chrome (no `dangerVariant`, no `mutedVariant`); the
/// stable key lets widget tests pin the styling contract without relying
/// on localized button labels.
const String kInterventionInterveneButtonKey =
    'interventionOverlayInterveneButton';

/// Stable key for the **Do naught** choice button (#2867 R26b). The
/// do-nothing button renders with `mutedVariant: true` so the affordance
/// reads as secondary against `kInterventionInterveneButtonKey`.
const String kInterventionDoNothingButtonKey =
    'interventionOverlayDoNothingButton';

/// Stable key for the **Diplomatic protest** choice button (#2867 R26b).
/// The protest button renders with `mutedVariant: true` so the affordance
/// reads as secondary against `kInterventionInterveneButtonKey`.
const String kInterventionProtestButtonKey = 'interventionOverlayProtestButton';

/// Stable key for the plain situation strip on the choice picker (#4267).
const String kInterventionChoiceSituationKey =
    'interventionOverlayChoiceSituation';

/// Stable key for the optional muted hold-reason line (#4267).
const String kInterventionHoldReasonKey = 'interventionOverlayHoldReason';

/// Stable keys for per-choice first-order Effect lines (#4267).
const String kInterventionEffectInterveneKey =
    'interventionOverlayEffectIntervene';
const String kInterventionEffectDoNothingKey =
    'interventionOverlayEffectDoNothing';
const String kInterventionEffectProtestKey = 'interventionOverlayEffectProtest';

/// The three differentiated choice buttons rendered by the per-prompt
/// picker phase of [InterventionDialogueOverlay] (#2867 R26b, #4267).
///
/// Extracted as a public, parameter-only widget so widget tests can pin
/// the styling contract for each button without first driving the parent
/// overlay through its async Yarn flow into `_awaitingChoice`. The
/// styling rules — primary chrome on **Intervene** and `mutedVariant`
/// chrome on **Do naught** / **Diplomatic protest** — are the contract,
/// not the concrete colors (which the widget delegates to
/// [CtNinePatchButton] and the editorial-monocle palette).
///
/// SPEC: `SPEC/ui/screens/pending-intervention-overlay.md` § Choice-button
/// styling; `SPEC/ui/pixel-art-ui-catalog.md` § *CtNinePatchButton*
/// (Muted variant).
class InterventionChoiceButtons extends StatelessWidget {
  const InterventionChoiceButtons({
    super.key,
    required this.onPick,
    required this.interveneEffect,
    required this.doNothingEffect,
    required this.protestEffect,
  });

  /// Called with the selected [InterventionChoice] when the player taps
  /// any of the three buttons. The parent typically completes the
  /// per-prompt `_choiceCompleter` so the Yarn flow can resume into the
  /// reaction node for that choice.
  final void Function(InterventionChoice choice) onPick;
  final String interveneEffect;
  final String doNothingEffect;
  final String protestEffect;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final TextStyle effectStyle =
        (Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(color: EditorialMonoclePalette.muted);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceWithEffect(
          buttonKey: kInterventionInterveneButtonKey,
          label: l10n.game_intervention_intervene,
          effectKey: kInterventionEffectInterveneKey,
          effect: interveneEffect,
          effectStyle: effectStyle,
          onPressed: () => onPick(InterventionChoice.intervene),
        ),
        const SizedBox(height: CtSpacing.s),
        _ChoiceWithEffect(
          buttonKey: kInterventionDoNothingButtonKey,
          label: l10n.game_intervention_doNothing,
          effectKey: kInterventionEffectDoNothingKey,
          effect: doNothingEffect,
          effectStyle: effectStyle,
          mutedVariant: true,
          onPressed: () => onPick(InterventionChoice.doNothing),
        ),
        const SizedBox(height: CtSpacing.s),
        _ChoiceWithEffect(
          buttonKey: kInterventionProtestButtonKey,
          label: l10n.game_intervention_protest,
          effectKey: kInterventionEffectProtestKey,
          effect: protestEffect,
          effectStyle: effectStyle,
          mutedVariant: true,
          onPressed: () => onPick(InterventionChoice.protest),
        ),
      ],
    );
  }
}

class _ChoiceWithEffect extends StatelessWidget {
  const _ChoiceWithEffect({
    required this.buttonKey,
    required this.label,
    required this.effectKey,
    required this.effect,
    required this.effectStyle,
    required this.onPressed,
    this.mutedVariant = false,
  });

  final String buttonKey;
  final String label;
  final String effectKey;
  final String effect;
  final TextStyle effectStyle;
  final VoidCallback onPressed;
  final bool mutedVariant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CtNinePatchButton(
          key: ValueKey<String>(buttonKey),
          mutedVariant: mutedVariant,
          onPressed: onPressed,
          child: Text(label),
        ),
        const SizedBox(height: CtSpacing.xs),
        Text(
          effect,
          key: ValueKey<String>(effectKey),
          style: effectStyle,
        ),
      ],
    );
  }
}
