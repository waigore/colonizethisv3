// Map display options dialog (in-game empire overview).
// SPEC/ui/empire-overview.md § Map display options button and dialog.

import 'package:colonizethis_models/colonizethis_models.dart' show MapViewState;
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_toggle_switch.dart';
import 'chrome/ct_nine_patch_button.dart';

/// Stable key for the "Show province overlay" [CtToggleSwitch] inside
/// [GameMapOptionsDialog]. Used by widget tests and E2E lookups.
const ValueKey<String> kGameMapOptionsShowProvinceOverlayToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceOverlay');

/// Stable key for the "Show province ownership" [CtToggleSwitch] inside
/// [GameMapOptionsDialog].
const ValueKey<String> kGameMapOptionsShowProvinceOwnershipToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceOwnership');

/// Stable key for the "Show province names" [CtToggleSwitch] inside
/// [GameMapOptionsDialog].
const ValueKey<String> kGameMapOptionsShowProvinceNamesToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceNames');

/// Dark editorial-monocle modal that lets the player toggle the three global
/// in-game map view layers — province overlay strokes, Great Power ownership
/// tint, and province name labels. Implements `Refs #2861` S8 / R9 (universal
/// dialog pattern from `Refs #2867` R1) by painting a [CtDialogShell] frame
/// containing a title, three [CtToggleSwitch] rows, and a single
/// [CtNinePatchButton] **Close** action. Material `AlertDialog` / `Dialog` and
/// `SwitchListTile` chrome is not used here per
/// `SPEC/ui/pixel-art-ui-catalog.md` § Material design ban.
///
/// The dialog manages local state synchronised with the host map area. Each
/// toggle updates local state immediately so the affordance reflects the new
/// value within the same dialog session and invokes [onChanged] so the host
/// can persist the change in [MapViewState] (savegame map view state per
/// `SPEC/ui/empire-overview.md`).
class GameMapOptionsDialog extends StatefulWidget {
  const GameMapOptionsDialog({
    super.key,
    required this.initialState,
    required this.onChanged,
  });

  /// Snapshot of [MapViewState] used to seed local toggle values when the
  /// dialog opens.
  final MapViewState initialState;

  /// Called with the new [MapViewState] every time the user toggles one of the
  /// three layer switches. The host is expected to persist the value (e.g.
  /// via the in-memory game state's `mapViewState` field).
  final ValueChanged<MapViewState> onChanged;

  @override
  State<GameMapOptionsDialog> createState() => _GameMapOptionsDialogState();
}

class _GameMapOptionsDialogState extends State<GameMapOptionsDialog> {
  late MapViewState _state = widget.initialState;

  void _update(MapViewState next) {
    if (_state == next) return;
    setState(() => _state = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.map_displayOptions_title, style: titleStyle),
          const SizedBox(height: 12),
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceOverlayToggleKey,
            label: l10n.map_displayOptions_showProvinceOverlay,
            labelStyle: labelStyle,
            value: _state.showProvinceOverlay,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceOverlay: value)),
          ),
          const SizedBox(height: 8),
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceOwnershipToggleKey,
            label: l10n.map_displayOptions_showProvinceOwnership,
            labelStyle: labelStyle,
            value: _state.showProvinceOwnershipTint,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceOwnershipTint: value)),
          ),
          const SizedBox(height: 8),
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceNamesToggleKey,
            label: l10n.map_displayOptions_showProvinceNames,
            labelStyle: labelStyle,
            value: _state.showProvinceNamesLayer,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceNamesLayer: value)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.common_close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameMapOptionsToggleRow extends StatelessWidget {
  const _GameMapOptionsToggleRow({
    required this.toggleKey,
    required this.label,
    required this.labelStyle,
    required this.value,
    required this.onChanged,
  });

  final Key toggleKey;
  final String label;
  final TextStyle labelStyle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        const SizedBox(width: 12),
        CtToggleSwitch(key: toggleKey, value: value, onChanged: onChanged),
      ],
    );
  }
}
