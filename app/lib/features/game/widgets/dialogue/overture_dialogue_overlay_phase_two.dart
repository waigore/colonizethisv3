// Phase-2 offer list + Submit chrome for [OvertureDialogueOverlay].
// SPEC/ui/overture-dialogue-overlay.md § Layout / wireframe.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'overture_dialogue_overlay_offer_row.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

Widget buildOverturePhaseTwoBody({
  required BuildContext context,
  required AppLocalizations l10n,
  required List<OvertureOffer> offers,
  required List<bool?> accepted,
  required String Function(String offererGpId) offererDisplayName,
  required String Function(AppLocalizations l10n, OvertureStage stage)
  stageLabel,
  required bool allDecided,
  required VoidCallback onSubmit,
  required void Function(int index, bool? next) onDecisionChanged,
}) {
  final ThemeData theme = Theme.of(context);
  final TextStyle titleStyle = _phaseTwoTitleStyle(theme);
  final TextStyle introStyle = _phaseTwoIntroStyle(theme);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        l10n.game_overture_title,
        key: const ValueKey<String>('overtureTitle'),
        style: titleStyle,
      ),
      const SizedBox(height: _titleToDividerGap),
      const CtBrassDivider(key: ValueKey<String>('overtureBrassDivider')),
      const SizedBox(height: _dividerToIntroGap),
      Text(
        l10n.game_overture_intro,
        key: const ValueKey<String>('overtureIntro'),
        style: introStyle,
      ),
      const SizedBox(height: CtSpacing.l),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: offers.length,
        itemBuilder: (context, i) {
          final offer = offers[i];
          final bool? decision = accepted[i];
          return OvertureOfferRow(
            rowIndex: i,
            offerer: offererDisplayName(offer.offererGpId),
            stageLabel: stageLabel(l10n, offer.stage),
            acceptLabel: l10n.game_overture_accept,
            rejectLabel: l10n.game_overture_reject,
            decision: decision,
            onDecisionChanged: (bool? next) => onDecisionChanged(i, next),
          );
        },
      ),
      const SizedBox(height: CtSpacing.m),
      Align(
        alignment: Alignment.centerRight,
        child: CtNinePatchButton(
          key: const ValueKey<String>('overtureSubmitButton'),
          enabled: allDecided,
          onPressed: allDecided ? onSubmit : null,
          child: Text(l10n.game_callToArms_submit),
        ),
      ),
    ],
  );
}

/// Phase-2 title style per #2867 R2 / R21: `--accent` color and a 0.05em
/// letter-spacing computed from the resolved title `fontSize` so the
/// canonical letter-spacing scales with theme overrides.
TextStyle _phaseTwoTitleStyle(ThemeData theme) {
  final TextStyle base =
      theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
  final double fontSize = base.fontSize ?? 16;
  return base.copyWith(
    color: EditorialMonoclePalette.accent,
    letterSpacing: fontSize * _titleLetterSpacingEm,
  );
}

/// Phase-2 intro style per #2867 R5 / R21: italic body text in `--muted`.
TextStyle _phaseTwoIntroStyle(ThemeData theme) =>
    (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );

/// Canonical title letter-spacing factor per #2867 R2 (0.05em).
const double _titleLetterSpacingEm = 0.05;

/// Vertical gap between phase-2 title and the [CtBrassDivider].
const double _titleToDividerGap = 8;

/// Vertical gap between the [CtBrassDivider] and the intro line.
const double _dividerToIntroGap = 8;
