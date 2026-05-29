import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';
import 'ct_dialog_shell.dart';
import 'ct_nine_patch_button.dart';

/// Animation timing for the trigger chevron rotation between
/// closed (chevron-down) and open (chevron-up) states per
/// SPEC/ui/pixel-art-ui-catalog.md (CtDropdown / Refs #2859 R5d).
const Duration kCtDropdownChevronAnimationDuration = Duration(milliseconds: 120);

/// Final turn fraction the chevron rotates through when the picker opens.
/// `0.5` turns equals 180°, taking the glyph from chevron-down to chevron-up.
const double _kChevronOpenTurns = 0.5;
const double _kChevronClosedTurns = 0.0;

/// Width of the picker row's accent left-edge indicator. Pinned to 1 dp so
/// selected and unselected rows occupy identical horizontal space — the
/// unselected variant paints a fully transparent border at the same width,
/// keeping the layout stable across selection changes (Refs #2859 R5c).
const double kCtDropdownPickerSelectedLeftEdgeWidth = 1.0;

/// Pixel-art dropdown: nine-patch button + modal list of options.
///
/// Trigger chevron animates between chevron-down (closed) and chevron-up
/// (open) over [kCtDropdownChevronAnimationDuration] using
/// [Curves.easeOut], per the R5d visual contract in
/// SPEC/ui/pixel-art-ui-catalog.md.
class CtDropdown<T> extends StatefulWidget {
  const CtDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.isExpanded = true,
    this.itemLabel,
    this.itemLeading,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool isExpanded;
  final String Function(T value)? itemLabel;

  /// Optional leading widget per value (e.g. GP map colour). Shown when the
  /// value is selected and in each picker row when non-null.
  final Widget? Function(BuildContext context, T value)? itemLeading;

  /// Test hook (debug-only): the [Key] of the [AnimatedRotation] driving the
  /// trigger chevron animation. Tests can locate the chevron via this key to
  /// assert turn counts and durations without depending on widget tree order.
  static const Key kChevronAnimatedRotationKey = Key(
    'ct_dropdown_chevron_animated_rotation',
  );

  /// Test hook: the [Key] of the outer [DecoratedBox] wrapping the picker
  /// row whose value matches the current trigger [value]. Tests can locate
  /// the selected row via this key to assert the R5c selected-state visual
  /// (1 px `--accent` left-edge border + `--accent-dim` background tint)
  /// without depending on tree order. Only the selected row exposes this
  /// key; non-selected rows render without it.
  static const Key kCtDropdownPickerSelectedRowKey = Key(
    'ct_dropdown_picker_selected_row',
  );

  @override
  State<CtDropdown<T>> createState() => _CtDropdownState<T>();
}

class _CtDropdownState<T> extends State<CtDropdown<T>> {
  bool _isOpen = false;

  String _labelFor(T v) =>
      widget.itemLabel != null ? widget.itemLabel!(v) : v.toString();

  @override
  Widget build(BuildContext context) {
    return CtNinePatchButton(
      onPressed: () => _openPicker(context),
      child: _buttonChild(context),
    );
  }

  Widget _buttonChild(BuildContext context) {
    final selected = widget.value != null && widget.items.contains(widget.value)
        ? _labelFor(widget.value as T)
        : (widget.hint ?? 'Select');

    final Widget labelWidget = Text(selected, overflow: TextOverflow.ellipsis);

    Widget? leading;
    if (widget.value != null &&
        widget.items.contains(widget.value) &&
        widget.itemLeading != null) {
      leading = widget.itemLeading!(context, widget.value as T);
    }

    Widget buttonChild = labelWidget;

    if (widget.isExpanded) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(child: labelWidget),
          const SizedBox(width: 8),
          _buildChevron(),
        ],
      );
    } else if (leading != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 8),
          Flexible(child: labelWidget),
        ],
      );
    }

    return buttonChild;
  }

  /// Trigger chevron-down glyph that rotates 180° to chevron-up when the
  /// picker opens, per #2859 R5d. The chevron colour resolves to
  /// `--accent-dim` from the editorial-monocle palette; no hex literals.
  Widget _buildChevron() {
    return AnimatedRotation(
      key: CtDropdown.kChevronAnimatedRotationKey,
      turns: _isOpen ? _kChevronOpenTurns : _kChevronClosedTurns,
      duration: kCtDropdownChevronAnimationDuration,
      curve: Curves.easeOut,
      child: Icon(
        Icons.expand_more,
        size: 16,
        color: EditorialMonoclePalette.accentDim,
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isOpen = true);
    try {
      final chosen = await showDialog<T>(
        context: context,
        builder: (ctx) => CtDialogShell(
          maxWidth: 320,
          maxHeight: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.hint != null) ...[
                Text(widget.hint!, style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
              ],
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final v = widget.items[index];
                  final label = _labelFor(v);
                  final rowLeading = widget.itemLeading?.call(context, v);
                  final bool isSelected =
                      widget.value != null && v == widget.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: DecoratedBox(
                      key: isSelected
                          ? CtDropdown.kCtDropdownPickerSelectedRowKey
                          : null,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? EditorialMonoclePalette.accentDim
                            : null,
                        border: Border(
                          left: BorderSide(
                            color: isSelected
                                ? EditorialMonoclePalette.accent
                                : Colors.transparent,
                            width: kCtDropdownPickerSelectedLeftEdgeWidth,
                          ),
                        ),
                      ),
                      child: CtNinePatchButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(v);
                        },
                        enabled: true,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              if (rowLeading != null) ...[
                                rowLeading,
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
      if (chosen != null) {
        widget.onChanged(chosen);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpen = false);
      }
    }
  }
}
