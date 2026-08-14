// Map display options dialog (in-game empire overview).
// SPEC/ui/empire-overview.md § Map display options button and dialog.

import 'package:colonizethis_models/colonizethis_models.dart' show MapViewState;
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_toggle_switch.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

/// Stable key for the "Show province and sea borders" [CtToggleSwitch].
const ValueKey<String> kGameMapOptionsShowProvinceOverlayToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceOverlay');

/// Stable key for the "Show province ownership" [CtToggleSwitch].
const ValueKey<String> kGameMapOptionsShowProvinceOwnershipToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceOwnership');

/// Stable key for the "Show province names" [CtToggleSwitch].
const ValueKey<String> kGameMapOptionsShowProvinceNamesToggleKey =
    ValueKey<String>('gameMapOptions:showProvinceNames');

/// Stable key for the "Show resources" [CtToggleSwitch] (Refs #4388).
const ValueKey<String> kGameMapOptionsShowMapResourcesToggleKey =
    ValueKey<String>('gameMapOptions:showMapResources');

/// Stable key for the "Show improvements" [CtToggleSwitch] (Refs #4388).
const ValueKey<String> kGameMapOptionsShowMapImprovementsToggleKey =
    ValueKey<String>('gameMapOptions:showMapImprovements');

/// Stable key for the "Show roads and rails" [CtToggleSwitch] (Refs #4388).
const ValueKey<String> kGameMapOptionsShowMapRoadsToggleKey = ValueKey<String>(
  'gameMapOptions:showMapRoads',
);

/// Dark editorial-monocle modal for information-layer and cartographic map
/// toggles. Implements `Refs #2861` S8 / R9 and `Refs #4388`.
class GameMapOptionsDialog extends StatefulWidget {
  const GameMapOptionsDialog({
    super.key,
    required this.initialState,
    required this.onChanged,
  });

  /// Snapshot of [MapViewState] used to seed local toggle values when the
  /// dialog opens.
  final MapViewState initialState;

  /// Called with the new [MapViewState] every time the user toggles a switch.
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
    final headingStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.muted);
    final labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final roadsEnabled = _state.showMapImprovements;

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.map_displayOptions_title, style: titleStyle),
          CtGap.ml,
          Text(l10n.map_displayOptions_mapMarksHeading, style: headingStyle),
          CtGap.m,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowMapResourcesToggleKey,
            label: l10n.map_displayOptions_showMapResources,
            labelStyle: labelStyle,
            value: _state.showMapResources,
            onChanged: (value) =>
                _update(_state.copyWith(showMapResources: value)),
          ),
          CtGap.m,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowMapImprovementsToggleKey,
            label: l10n.map_displayOptions_showMapImprovements,
            labelStyle: labelStyle,
            value: _state.showMapImprovements,
            onChanged: (value) => _update(
              _state.copyWith(
                showMapImprovements: value,
                showMapRoads: value ? _state.showMapRoads : false,
              ),
            ),
          ),
          CtGap.m,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowMapRoadsToggleKey,
            label: l10n.map_displayOptions_showMapRoads,
            labelStyle: labelStyle,
            value: _state.showMapRoads && roadsEnabled,
            onChanged: roadsEnabled
                ? (value) => _update(_state.copyWith(showMapRoads: value))
                : null,
          ),
          CtGap.l,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceOverlayToggleKey,
            label: l10n.map_displayOptions_showProvinceOverlay,
            labelStyle: labelStyle,
            value: _state.showProvinceOverlay,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceOverlay: value)),
          ),
          CtGap.m,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceOwnershipToggleKey,
            label: l10n.map_displayOptions_showProvinceOwnership,
            labelStyle: labelStyle,
            value: _state.showProvinceOwnershipTint,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceOwnershipTint: value)),
          ),
          CtGap.m,
          _GameMapOptionsToggleRow(
            toggleKey: kGameMapOptionsShowProvinceNamesToggleKey,
            label: l10n.map_displayOptions_showProvinceNames,
            labelStyle: labelStyle,
            value: _state.showProvinceNamesLayer,
            onChanged: (value) =>
                _update(_state.copyWith(showProvinceNamesLayer: value)),
          ),
          CtGap.l,
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
  final ValueChanged<bool>? onChanged;

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
