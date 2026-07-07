import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';
import 'ct_panel.dart';
import 'ct_spacing.dart';

part 'ct_transfer_list_side_panel.dart';
part 'ct_transfer_list_mutations.dart';
part 'ct_transfer_list_layout.dart';

/// Side-by-side two-panel layout requires at least this many logical pixels of
/// inner width (the constraint passed to [CtTransferList] by its parent shell,
/// e.g. `CtDialogShell` body). Below this threshold the two panels stack
/// vertically so the per-row label + transfer buttons can render without a
/// `RenderFlex` overflow at the minimum supported viewport
/// (`kMinViewportWidth = 320` dp). Normative narrow stacking behavior is
/// documented in `SPEC/ui/naval-units-fleet-management.md`,
/// `SPEC/ui/military-units-army-management.md`, and
/// `SPEC/ui/transfer-to-home-fleet-dialog.md`.
@visibleForTesting
const double kCtTransferListSideBySideMinWidth = 360;

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
  State<CtTransferList> createState() => _CtTransferListState();
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

class _CtTransferListState extends State<CtTransferList> {
  late Map<String, int> _leftCounts;
  late Map<String, int> _rightCounts;

  int get _leftTotal => _leftCounts.values.fold(0, (sum, count) => sum + count);
  int get _rightTotal =>
      _rightCounts.values.fold(0, (sum, count) => sum + count);

  bool get _canConfirm {
    final validate = widget.canConfirm;
    if (validate == null) {
      return _rightTotal > 0;
    }
    return validate(_leftCounts, _rightCounts);
  }

  @override
  void initState() {
    super.initState();
    _leftCounts = Map<String, int>.from(widget.initialLeftCounts);
    _rightCounts = Map<String, int>.from(widget.initialRightCounts);
  }

  @override
  Widget build(BuildContext context) => buildTransferListLayout(context);
}
