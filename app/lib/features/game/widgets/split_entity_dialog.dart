// Shared scaffold + confirm rule for the in-game split dialogs.
//
// Consumed by SPEC/ui/military-units-army-management.md (`SplitArmyDialog`)
// and SPEC/ui/naval-units-fleet-management.md (`SplitFleetDialog`): both
// render the same `CtDialogShell(520 x 500)` body of [title, CtGap, a
// `CtTransferList` configured with a per-side location subtitle] and gate
// Confirm behind the same "keep one on the source / new side non-empty"
// rule (with the home-entity relaxation). The base eliminates the
// duplicated scaffold (#3594 target state #2) so the two split dialogs
// cannot drift.

import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/ct_transfer_list.dart';

/// Abstract base for the in-game split dialogs (`SplitArmyDialog`,
/// `SplitFleetDialog`).
///
/// Subclasses resolve their localized labels and domain data inside
/// `build`, then return [buildSplitDialogScaffold]; the base owns the
/// shared `CtDialogShell` frame, the title + transfer-list layout, the
/// Cancel/Confirm wiring, and the [canConfirmSplit] gate so the two
/// dialogs share one structural and behavioral contract.
abstract class SplitEntityDialog extends StatelessWidget {
  const SplitEntityDialog({super.key});

  /// Outer dialog frame width shared by every split dialog.
  static const double dialogMaxWidth = 520;

  /// Outer dialog frame height shared by every split dialog.
  static const double dialogMaxHeight = 500;

  /// Transfer-list viewport height shared by every split dialog.
  static const double transferListHeight = 220;

  /// Shared Confirm-enablement rule for split dialogs (#3594 target
  /// state #2).
  ///
  /// A home entity (the player's `home_army` / `home_fleet`) may move
  /// everything out, so it only requires the new side to be non-empty.
  /// Any other source must retain at least one item on the left and put
  /// at least one item on the new (right) side.
  @visibleForTesting
  static bool canConfirmSplit({
    required Map<String, int> left,
    required Map<String, int> right,
    required bool isHomeEntity,
  }) {
    final leftTotal = left.values.fold<int>(0, (sum, count) => sum + count);
    final rightTotal = right.values.fold<int>(0, (sum, count) => sum + count);
    if (isHomeEntity) {
      return rightTotal > 0;
    }
    return leftTotal >= 1 && rightTotal > 0;
  }

  /// Composes the shared split-dialog scaffold. Subclasses resolve their
  /// l10n / domain data, then return this from `build`.
  ///
  /// [locationLabel] is rendered as both the source and the new-side
  /// subtitle (a split keeps the entity in place). [onConfirm] receives
  /// the new-side counts; the base pops the dialog on Cancel, while the
  /// subclass is responsible for popping after emitting its split event.
  @protected
  Widget buildSplitDialogScaffold({
    required BuildContext context,
    required String title,
    required String leftTitle,
    required String rightTitle,
    required String locationLabel,
    required Map<String, int> initialLeftCounts,
    required String Function(String itemId) itemLabelBuilder,
    required String leftEmptyLabel,
    required String rightEmptyLabel,
    required String confirmLabel,
    required String Function(int total) totalLabelBuilder,
    required bool isHomeEntity,
    required void Function(Map<String, int> right) onConfirm,
  }) {
    return CtDialogShell(
      maxWidth: dialogMaxWidth,
      maxHeight: dialogMaxHeight,
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            CtGap.l,
            CtTransferList(
              listHeight: transferListHeight,
              leftTitle: leftTitle,
              rightTitle: rightTitle,
              leftSubtitle: locationLabel,
              rightSubtitle: locationLabel,
              initialLeftCounts: initialLeftCounts,
              itemLabelBuilder: itemLabelBuilder,
              leftEmptyLabel: leftEmptyLabel,
              rightEmptyLabel: rightEmptyLabel,
              confirmLabel: confirmLabel,
              totalLabelBuilder: totalLabelBuilder,
              canConfirm: (left, right) => canConfirmSplit(
                left: left,
                right: right,
                isHomeEntity: isHomeEntity,
              ),
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: (_, right) => onConfirm(right),
            ),
          ],
        ),
      ),
    );
  }
}
