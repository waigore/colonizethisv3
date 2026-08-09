import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';

import 'new_game_leader_selection_dialog.dart';
import 'new_game_leader_selection_dialog_layout.dart';
import 'new_game_leader_selection_dialog_state_base.dart';

/// Advanced-start, infinite-mode, and terrain fields for
/// [NewGameLeaderSelectionDialog] (Refs #4117).
mixin NewGameLeaderSelectionDialogSetupFieldsOptions
    on
        State<NewGameLeaderSelectionDialog>,
        NewGameLeaderSelectionDialogStateBase {
  bool get advancedStartEnabled => widget.baseConfig.isLockedFullInitProfile;

  String advancedStartLabel(AppLocalizations l10n, AdvancedStartType type) {
    return switch (type) {
      AdvancedStartType.none => l10n.shell_leaderDialog_advancedStartNone,
      AdvancedStartType.turns50 => l10n.shell_leaderDialog_advancedStart50,
      AdvancedStartType.turns100 => l10n.shell_leaderDialog_advancedStart100,
    };
  }

  Widget buildAdvancedStartField(
    ThemeData theme,
    AppLocalizations l10n,
    NewGameLeaderDialogTextStyles styles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.shell_leaderDialog_advancedStartLabel,
          style: styles.fieldLabel,
        ),
        const SizedBox(height: CtSpacing.m / 2),
        AbsorbPointer(
          absorbing: !advancedStartEnabled,
          child: Opacity(
            opacity: advancedStartEnabled ? 1 : 0.5,
            child: CtDropdown<AdvancedStartType>(
              value: advancedStart,
              items: AdvancedStartType.values,
              itemLabel: (type) => advancedStartLabel(l10n, type),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => advancedStart = value);
              },
            ),
          ),
        ),
        if (!advancedStartEnabled) ...[
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.shell_leaderDialog_advancedStartDisabledHelper,
            style: styles.helper,
          ),
        ],
      ],
    );
  }

  Widget buildInfiniteModeTile(
    ThemeData theme,
    AppLocalizations l10n,
    NewGameLeaderDialogTextStyles styles,
  ) {
    // Mockup `.toggle-row`: CtToggleSwitch beside the label, helper text
    // indented beneath (no Material `CheckboxListTile` chrome per
    // `pixel-art-ui-catalog.md`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: CtToggleSwitch(
                value: infiniteMode,
                onChanged: (value) {
                  setState(() => infiniteMode = value);
                },
              ),
            ),
            const SizedBox(width: kNewGameLeaderSelectionToggleLabelGap),
            Expanded(
              child: Text(
                l10n.shell_leaderDialog_infiniteModeLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: EditorialMonoclePalette.fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CtSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(
            left: CtToggleSwitch.trackWidth + kNewGameLeaderSelectionToggleLabelGap,
          ),
          child: Text(
            l10n.shell_leaderDialog_infiniteModeHelper,
            style: styles.helper,
          ),
        ),
      ],
    );
  }

  Widget buildTerrainVariationField(
    BuildContext context,
    AppLocalizations l10n, {
    required TextStyle fieldLabelStyle,
    required TextStyle helperStyle,
  }) {
    final percent = (terrainVariation * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mockup `.slider-row`: static label on the left, live mono percent
        // value beside it, slider below. The label flexes so it wraps rather
        // than overflowing at the 320 dp minimum viewport.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                l10n.shell_leaderDialog_terrainVariationLabel,
                style: fieldLabelStyle,
              ),
            ),
            const SizedBox(width: CtSpacing.m),
            Text(
              l10n.shell_leaderDialog_terrainVariationValue(percent),
              key: const ValueKey<String>(
                'leaderSelectionDialogTerrainVariationValue',
              ),
              style: fieldLabelStyle.copyWith(
                color: EditorialMonoclePalette.accentDim,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: CtSpacing.s),
        CtSlider(
          value: terrainVariation,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() => terrainVariation = value);
          },
        ),
        const SizedBox(height: CtSpacing.s),
        Text(
          l10n.shell_leaderDialog_terrainVariationHelper,
          style: helperStyle,
        ),
      ],
    );
  }
}
