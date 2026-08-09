import 'package:flutter/material.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

/// Pickers body that switches between a side-by-side `Row` and a vertically
/// stacked `Column` at the [kLeaderSelectionNarrowBreakpoint] (540 dp) viewport
/// width — the DLG10001-dedicated breakpoint matching the mockup
/// `@media (min-width: 540px)` rule.
///
/// SPEC: `SPEC/ui/new-game-leader-selection-dialog.md` § Layout / wireframe
/// + Acceptance Criteria narrow-viewport stacking AC;
/// `SPEC/ui/mobile-adaptation.md` § 4 New game leader selection.
class NewGameLeaderSelectionDialogSlotPickersBody extends StatelessWidget {
  const NewGameLeaderSelectionDialogSlotPickersBody({
    required this.nationDropdown,
    required this.leaderDropdown,
    this.profileLine,
    super.key,
  });

  final Widget nationDropdown;
  final Widget leaderDropdown;

  /// Pre-built AI Profile line (inline label + dropdown) for AI slots; `null`
  /// for the human slot (0).
  final Widget? profileLine;

  /// Vertical gap between the nation dropdown and the leader dropdown when
  /// the slot body is stacked (matches the slot label ↔ pickers gap of
  /// `CtSpacing.m / 2` = 4 dp).
  static const double stackedGap = CtSpacing.m / 2;

  /// Key applied to the vertically stacked `Column` body (narrow viewport).
  /// Tests pin the narrow-stacking AC by asserting one such column per slot.
  static const Key stackedColumnKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersColumn',
  );

  /// Key applied to the side-by-side `Row` body (wide viewport).
  /// Tests pin the wide-row AC by asserting one such row per slot.
  static const Key sideBySideRowKey = ValueKey<String>(
    'newGameLeaderDialogSlotPickersRow',
  );

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).width < kLeaderSelectionNarrowBreakpoint;
    if (narrow) {
      return Column(
        key: stackedColumnKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          nationDropdown,
          const SizedBox(height: stackedGap),
          leaderDropdown,
          if (profileLine != null) ...[
            const SizedBox(height: stackedGap),
            profileLine!,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          key: sideBySideRowKey,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: nationDropdown),
            const SizedBox(width: CtSpacing.s),
            Expanded(child: leaderDropdown),
          ],
        ),
        if (profileLine != null) ...[
          const SizedBox(height: stackedGap),
          profileLine!,
        ],
      ],
    );
  }
}
