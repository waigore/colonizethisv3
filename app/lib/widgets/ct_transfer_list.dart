import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'ct_nine_patch_button.dart';
import 'ct_panel.dart';

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

  String _itemLabel(String itemId) {
    final builder = widget.itemLabelBuilder;
    if (builder == null) return itemId;
    return builder(itemId);
  }

  void _notifyChanged() {
    widget.onChanged?.call(_leftCounts, _rightCounts);
  }

  void _cleanupZeros() {
    _leftCounts.removeWhere((_, v) => v <= 0);
    _rightCounts.removeWhere((_, v) => v <= 0);
  }

  void _moveOneToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = from - 1;
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + 1;
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveOneToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = from - 1;
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + 1;
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveAllToRight(String itemId) {
    final from = _leftCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _rightCounts[itemId] = (_rightCounts[itemId] ?? 0) + from;
      _leftCounts.remove(itemId);
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _moveAllToLeft(String itemId) {
    final from = _rightCounts[itemId] ?? 0;
    if (from <= 0) return;
    setState(() {
      _leftCounts[itemId] = (_leftCounts[itemId] ?? 0) + from;
      _rightCounts.remove(itemId);
      _cleanupZeros();
    });
    _notifyChanged();
  }

  void _handleConfirm() {
    if (!_canConfirm) return;
    widget.onConfirm(
      Map<String, int>.from(_leftCounts),
      Map<String, int>.from(_rightCounts),
    );
  }

  Widget _leftPanel() {
    return _TransferSidePanel(
      title: widget.leftTitle,
      subtitle: widget.leftSubtitle,
      counts: _leftCounts,
      total: _leftTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.leftEmptyLabel,
      itemLabelBuilder: _itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: true,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: _moveOneToRight,
      onMoveAllToRight: _moveAllToRight,
      onMoveOneToLeft: _moveOneToLeft,
      onMoveAllToLeft: _moveAllToLeft,
    );
  }

  Widget _rightPanel() {
    return _TransferSidePanel(
      title: widget.rightTitle,
      subtitle: widget.rightSubtitle,
      counts: _rightCounts,
      total: _rightTotal,
      listHeight: widget.listHeight,
      emptyLabel: widget.rightEmptyLabel,
      itemLabelBuilder: _itemLabel,
      totalLabelBuilder: widget.totalLabelBuilder,
      placeActionsAfterLabel: false,
      moveAllToLeftLabel: widget.moveAllToLeftLabel,
      moveOneToLeftLabel: widget.moveOneToLeftLabel,
      moveOneToRightLabel: widget.moveOneToRightLabel,
      moveAllToRightLabel: widget.moveAllToRightLabel,
      onMoveOneToRight: _moveOneToRight,
      onMoveAllToRight: _moveAllToRight,
      onMoveOneToLeft: _moveOneToLeft,
      onMoveAllToLeft: _moveAllToLeft,
    );
  }

  Widget _actionRow(BuildContext context, {required bool useWrap}) {
    // At the minimum supported viewport (`kMinViewportWidth = 320` dp) the
    // Cinzel engraved-label text in `CtNinePatchButton` overflows a single
    // right-aligned `Row` for `Cancel` + a long `confirmLabel` (e.g.
    // "Confirm Split", "Transfer"). The narrow stack therefore uses `Wrap`
    // so Cancel + Confirm can flow onto a second run when needed. Wider
    // viewports keep the canonical single-row right-aligned layout so
    // existing dialog tests (and SPEC mockups) see the unchanged chrome.
    final cancel = widget.onCancel == null
        ? null
        : CtNinePatchButton(
            onPressed: widget.onCancel,
            child: Text(widget.cancelLabel),
          );
    final confirm = CtNinePatchButton(
      onPressed: _handleConfirm,
      enabled: _canConfirm,
      child: Text(widget.confirmLabel),
    );
    if (useWrap) {
      return Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          ?cancel,
          confirm,
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (cancel != null) ...[cancel, const SizedBox(width: 8)],
        confirm,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stackVertically =
            constraints.maxWidth.isFinite &&
            constraints.maxWidth < kCtTransferListSideBySideMinWidth;
        if (stackVertically) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _leftPanel(),
              const SizedBox(height: 16),
              _rightPanel(),
              const SizedBox(height: 16),
              _actionRow(context, useWrap: true),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _leftPanel()),
                const SizedBox(width: 16),
                Expanded(child: _rightPanel()),
              ],
            ),
            const SizedBox(height: 16),
            _actionRow(context, useWrap: false),
          ],
        );
      },
    );
  }
}

class _TransferSidePanel extends StatelessWidget {
  const _TransferSidePanel({
    required this.title,
    required this.counts,
    required this.total,
    required this.listHeight,
    required this.emptyLabel,
    required this.itemLabelBuilder,
    required this.totalLabelBuilder,
    required this.placeActionsAfterLabel,
    required this.moveAllToLeftLabel,
    required this.moveOneToLeftLabel,
    required this.moveOneToRightLabel,
    required this.moveAllToRightLabel,
    required this.onMoveOneToRight,
    required this.onMoveAllToRight,
    required this.onMoveOneToLeft,
    required this.onMoveAllToLeft,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Map<String, int> counts;
  final int total;
  final double listHeight;
  final String emptyLabel;
  final String Function(String itemId) itemLabelBuilder;
  final String Function(int total)? totalLabelBuilder;

  /// True: original-fleet panel — label then [>] [>>]. False: new-fleet panel — [<<] [<] then label.
  final bool placeActionsAfterLabel;
  final String moveAllToLeftLabel;
  final String moveOneToLeftLabel;
  final String moveOneToRightLabel;
  final String moveAllToRightLabel;
  final void Function(String itemId) onMoveOneToRight;
  final void Function(String itemId) onMoveAllToRight;
  final void Function(String itemId) onMoveOneToLeft;
  final void Function(String itemId) onMoveAllToLeft;

  static const double _rowButtonMinHeight = 40;
  static const EdgeInsets _rowButtonPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 6,
  );

  @override
  Widget build(BuildContext context) {
    return CtPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _buildListArea(context),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 4),
          Text(
            totalLabelBuilder?.call(total) ?? 'Total: $total items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildListArea(BuildContext context) {
    final sortedTypes = counts.keys.toList()..sort();
    return SizedBox(
      height: listHeight,
      child: sortedTypes.isEmpty
          ? _buildEmptyListBody(context)
          : ListView.builder(
              itemCount: sortedTypes.length,
              itemBuilder: (context, index) =>
                  _buildTypeRow(context, sortedTypes[index]),
            ),
    );
  }

  Widget _buildEmptyListBody(BuildContext context) {
    return Center(
      child: Text(
        emptyLabel,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTypeRow(BuildContext context, String typeId) {
    final count = counts[typeId] ?? 0;
    final label = Text(
      appL10n(context).transferList_rowCount(itemLabelBuilder(typeId), count),
      style: Theme.of(context).textTheme.bodyMedium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: _rowChildrenFor(typeId: typeId, count: count, label: label),
          ),
        ),
      ),
    );
  }

  List<Widget> _rowChildrenFor({
    required String typeId,
    required int count,
    required Widget label,
  }) {
    final canMove = count > 0;
    if (placeActionsAfterLabel) {
      return [
        Expanded(child: label),
        const SizedBox(width: 6),
        _transferActionButton(
          key: CtTransferListKeys.leftMoveOne(typeId),
          enabled: canMove,
          onPressed: canMove ? () => onMoveOneToRight(typeId) : null,
          label: moveOneToRightLabel,
        ),
        const SizedBox(width: 4),
        _transferActionButton(
          key: CtTransferListKeys.leftMoveAll(typeId),
          enabled: canMove,
          onPressed: canMove ? () => onMoveAllToRight(typeId) : null,
          label: moveAllToRightLabel,
        ),
      ];
    }
    return [
      _transferActionButton(
        key: CtTransferListKeys.rightMoveAll(typeId),
        enabled: canMove,
        onPressed: canMove ? () => onMoveAllToLeft(typeId) : null,
        label: moveAllToLeftLabel,
      ),
      const SizedBox(width: 4),
      _transferActionButton(
        key: CtTransferListKeys.rightMoveOne(typeId),
        enabled: canMove,
        onPressed: canMove ? () => onMoveOneToLeft(typeId) : null,
        label: moveOneToLeftLabel,
      ),
      const SizedBox(width: 6),
      Expanded(child: label),
    ];
  }

  CtNinePatchButton _transferActionButton({
    required Key key,
    required bool enabled,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return CtNinePatchButton(
      key: key,
      minHeight: _rowButtonMinHeight,
      padding: _rowButtonPadding,
      enabled: enabled,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
