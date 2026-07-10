import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'ct_dialog_shell.dart';
import 'ct_nine_patch_button.dart';

part 'ct_dropdown_trigger.dart';
part 'ct_dropdown_picker.dart';

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

  String labelFor(T v) =>
      widget.itemLabel != null ? widget.itemLabel!(v) : v.toString();

  @override
  Widget build(BuildContext context) {
    return CtNinePatchButton(
      onPressed: () => openPicker(context),
      child: buttonChild(context),
    );
  }
}
