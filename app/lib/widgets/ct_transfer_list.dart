import 'package:flutter/material.dart';

import 'ct_transfer_list_state.dart';

/// Generic dual-list transfer widget for moving counted items between two sides.
///
/// Use this component when a feature needs transferable quantities with:
/// - per-row single-item and move-all controls (no selection step)
/// - configurable validation before confirm
/// - customizable labels and item rendering
///
/// Below [kCtTransferListSideBySideMinWidth] the two side panels stack
/// vertically (panel → 16 dp gap → panel → action row) so the host shell can
/// honour the `kMinViewportWidth = 320` dp pin without overflow.
class CtTransferList extends StatefulWidget {
  const CtTransferList({
    super.key,
    required this.leftTitle,
    required this.rightTitle,
    required this.initialLeftCounts,
    required this.onConfirm,
    this.leftSubtitle,
    this.rightSubtitle,
    this.initialRightCounts = const {},
    this.itemLabelBuilder,
    this.canConfirm,
    this.onChanged,
    this.onCancel,
    this.leftEmptyLabel = 'No items',
    this.rightEmptyLabel = 'No items',
    this.moveAllToLeftLabel = '<<',
    this.moveOneToLeftLabel = '<',
    this.moveOneToRightLabel = '>',
    this.moveAllToRightLabel = '>>',
    this.cancelLabel = 'Cancel',
    this.confirmLabel = 'Confirm',
    this.listHeight = 150,
    this.totalLabelBuilder,
  });

  final String leftTitle;
  final String rightTitle;
  final String? leftSubtitle;
  final String? rightSubtitle;
  final Map<String, int> initialLeftCounts;
  final Map<String, int> initialRightCounts;
  final String Function(String itemId)? itemLabelBuilder;
  final bool Function(Map<String, int> left, Map<String, int> right)?
  canConfirm;
  final void Function(Map<String, int> left, Map<String, int> right)? onChanged;
  final void Function(Map<String, int> left, Map<String, int> right) onConfirm;
  final VoidCallback? onCancel;
  final String leftEmptyLabel;
  final String rightEmptyLabel;
  final String moveAllToLeftLabel;
  final String moveOneToLeftLabel;
  final String moveOneToRightLabel;
  final String moveAllToRightLabel;
  final String cancelLabel;
  final String confirmLabel;
  final double listHeight;
  final String Function(int total)? totalLabelBuilder;

  @override
  State<CtTransferList> createState() => CtTransferListState();
}

/// Keys for widget tests: one control per ship type and side/direction.
abstract final class CtTransferListKeys {
  static Key leftMoveOne(String itemId) =>
      ValueKey<String>('ctTransfer.left.>$itemId');

  static Key leftMoveAll(String itemId) =>
      ValueKey<String>('ctTransfer.left.>>$itemId');

  static Key rightMoveOne(String itemId) =>
      ValueKey<String>('ctTransfer.right.<$itemId');

  static Key rightMoveAll(String itemId) =>
      ValueKey<String>('ctTransfer.right.<<$itemId');
}

/// Side-by-side two-panel layout requires at least this many logical pixels of
/// inner width (the constraint passed to [CtTransferList] by its parent shell,
/// e.g. `CtDialogShell` body). Below this threshold the two panels stack
/// vertically so the per-row label + transfer buttons can render without a
/// `RenderFlex` overflow at the minimum supported viewport
/// (`kMinViewportWidth = 320` dp). Normative narrow stacking behavior is
/// documented in `SPEC/ui/naval-units-fleet-management.md`,
/// `SPEC/ui/military-units-army-management.md`, and
/// `SPEC/ui/transfer-to-home-fleet-dialog.md`.
const double kCtTransferListSideBySideMinWidth = 360;
