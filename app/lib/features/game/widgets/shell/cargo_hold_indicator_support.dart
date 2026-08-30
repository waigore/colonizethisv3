import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_spacing.dart';
import 'chrome_anchored_popover.dart';

/// Stable key for widget tests that open the cargo details popover.
const Key kCargoHoldDetailsPanelKey = Key('cargo_hold_details_panel');

/// Resolves the numeric `used/capacity` colour tier for the tab-bar cargo
/// indicator per `SPEC/ui/empire-overview.md` § Cargo hold indicator.
Color cargoHoldNumericColor({
  required int used,
  required int capacity,
  required bool cargoNotDefined,
  required bool isCargoUsedReliable,
}) {
  if (cargoNotDefined || capacity <= 0 || !isCargoUsedReliable) {
    return EditorialMonoclePalette.muted;
  }
  if (used >= capacity) {
    return EditorialMonoclePalette.danger;
  }
  final int tightThreshold = (0.8 * capacity).ceil();
  if (used >= tightThreshold) {
    return EditorialMonoclePalette.accent;
  }
  return EditorialMonoclePalette.muted;
}

/// Opens a dismissible floating panel anchored below the cargo indicator.
///
/// The dismiss scrim covers only the map area below shell chrome so the
/// [GameTopBar] Next-turn control stays tappable on narrow viewports.
Future<void> showCargoHoldDetailsPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required AppLocalizations l10n,
  required int cargoUsed,
  required int cargoCapacity,
  required bool isCargoUsedReliable,
}) {
  return showChromeAnchoredPopover(
    context: context,
    anchorKey: anchorKey,
    chromeBottomY: chromeBottomY,
    placement: ChromeAnchoredPopoverPlacement.rightAlignBelow,
    panelBuilder: (VoidCallback dismiss, VoidCallback _) {
      return CargoHoldDetailsPanel(
        l10n: l10n,
        cargoUsed: cargoUsed,
        cargoCapacity: cargoCapacity,
        isCargoUsedReliable: isCargoUsedReliable,
        onClose: dismiss,
      );
    },
  );
}

/// Plain-language cargo breakdown surfaced on player tap.
class CargoHoldDetailsPanel extends StatelessWidget {
  const CargoHoldDetailsPanel({
    super.key,
    required this.l10n,
    required this.cargoUsed,
    required this.cargoCapacity,
    required this.isCargoUsedReliable,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final int cargoUsed;
  final int cargoCapacity;
  final bool isCargoUsedReliable;
  final VoidCallback onClose;

  static const Key closeButtonKey = Key('cargo_hold_details_close');

  @override
  Widget build(BuildContext context) {
    final TextStyle rowStyle = _cargoHoldDetailsRowStyle(context);
    final TextStyle counselStyle = rowStyle.copyWith(
      color: EditorialMonoclePalette.muted,
      fontStyle: FontStyle.italic,
    );

    return DecoratedBox(
      key: kCargoHoldDetailsPanelKey,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border.all(color: EditorialMonoclePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _CargoHoldDetailsRows(
                    l10n: l10n,
                    cargoUsed: cargoUsed,
                    cargoCapacity: cargoCapacity,
                    isCargoUsedReliable: isCargoUsedReliable,
                    rowStyle: rowStyle,
                  ),
                ),
                CtIconAction(
                  key: closeButtonKey,
                  icon: Icons.close,
                  tooltip: l10n.common_close,
                  semanticLabel: l10n.common_close,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: CtSpacing.s),
            Text(
              l10n.mapControls_cargoHold_details_counsel,
              style: counselStyle,
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _cargoHoldDetailsRowStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
    color: EditorialMonoclePalette.fg,
    fontSize: 11,
    height: 1.3,
  );
}

class _CargoHoldDetailsRows extends StatelessWidget {
  const _CargoHoldDetailsRows({
    required this.l10n,
    required this.cargoUsed,
    required this.cargoCapacity,
    required this.isCargoUsedReliable,
    required this.rowStyle,
  });

  final AppLocalizations l10n;
  final int cargoUsed;
  final int cargoCapacity;
  final bool isCargoUsedReliable;
  final TextStyle rowStyle;

  @override
  Widget build(BuildContext context) {
    final String usedLabel = isCargoUsedReliable ? '$cargoUsed' : '—';
    final int freeForTrade = isCargoUsedReliable
        ? (cargoCapacity - cargoUsed).clamp(0, cargoCapacity)
        : 0;
    final String freeLabel = isCargoUsedReliable ? '$freeForTrade' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.mapControls_cargoHold_details_overseas(usedLabel),
          style: rowStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.mapControls_cargoHold_details_capacity('$cargoCapacity'),
          style: rowStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.mapControls_cargoHold_details_free(freeLabel),
          style: rowStyle,
        ),
      ],
    );
  }
}
