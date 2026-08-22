// Treasury details teaching popover for the map gold HUD (Refs #4560).
//
// SPEC: SPEC/ui/empire-overview.md § Treasury teaching surface.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'chrome_anchored_popover.dart';
import 'treasury_committed_spend.dart';
import 'treasury_details_panel.dart';

export 'treasury_details_format.dart';
export 'treasury_details_panel.dart';

/// Opens a dismissible floating panel anchored below the treasury indicator.
Future<void> showTreasuryDetailsPopover({
  required BuildContext context,
  required GlobalKey anchorKey,
  required double chromeBottomY,
  required AppLocalizations l10n,
  required int treasury,
  required int? projectedDelta,
  required List<TreasuryCommittedSpendLine> committedLines,
  required bool showExact,
  required ValueChanged<bool> onShowExactChanged,
}) {
  var exact = showExact;
  return showChromeAnchoredPopover(
    context: context,
    anchorKey: anchorKey,
    chromeBottomY: chromeBottomY,
    placement: ChromeAnchoredPopoverPlacement.rightAlignBelow,
    panelBuilder: (VoidCallback dismiss, VoidCallback rebuild) {
      return TreasuryDetailsPanel(
        l10n: l10n,
        treasury: treasury,
        projectedDelta: projectedDelta,
        committedLines: committedLines,
        showExact: exact,
        onShowExactChanged: (bool next) {
          exact = next;
          onShowExactChanged(next);
          rebuild();
        },
        onClose: dismiss,
      );
    },
  );
}
