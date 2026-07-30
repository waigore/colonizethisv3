import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import 'ct_dialog_shell.dart';

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

/// Compact trigger visual min-height (DLG10001 mockup `.dropdown-wrapper
/// select`). Layout contribution stays at this height; hit testing expands
/// to [kMinTouchTargetSize] via an invisible OverflowBox (Refs #4062).
const double kCtDropdownTriggerVisualMinHeight = 34.0;

/// Compact picker-row visual min-height (Refs #4062).
const double kCtDropdownPickerRowVisualMinHeight = 32.0;

/// Trigger / picker label font size (mockup `font-size:12px`).
const double kCtDropdownLabelFontSize = 12.0;

/// Trigger chevron glyph size (mockup `.chevron` `font-size:10px`).
const double kCtDropdownChevronSize = 10.0;

/// Compact flat select + modal list of options.
///
/// Trigger chevron animates between chevron-down (closed) and chevron-up
/// (open) over [kCtDropdownChevronAnimationDuration] using
/// [Curves.easeOut], per the R5d visual contract in
/// SPEC/ui/pixel-art-ui-catalog.md. Trigger / picker chrome follow the
/// DLG10001 compact flat select contract (Refs #4062).
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

  /// Player-visible label for Marionette / accessibility probes (Refs #4199).
  String? get marionetteVisibleLabel {
    final T? selected = value;
    if (selected != null) {
      return itemLabel != null ? itemLabel!(selected) : selected.toString();
    }
    return hint;
  }

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

  /// Test hook: the [Key] of the trigger's painted visual surface
  /// ([DecoratedBox]) so widget tests can pin the 34 dp visual height
  /// independently of the invisible ≥44 dp hit-area expansion.
  static const Key kCtDropdownTriggerVisualKey = Key(
    'ct_dropdown_trigger_visual',
  );

  /// Test hook: the [Key] of the trigger's opaque hit target so widget
  /// tests can assert ≥ [kMinTouchTargetSize] without depending on tree
  /// order.
  static const Key kCtDropdownTriggerHitTargetKey = Key(
    'ct_dropdown_trigger_hit_target',
  );

  @override
  State<CtDropdown<T>> createState() => _CtDropdownState<T>();
}

class _CtDropdownState<T> extends State<CtDropdown<T>> {
  bool _isOpen = false;
  bool _hovered = false;

  String labelFor(T v) =>
      widget.itemLabel != null ? widget.itemLabel!(v) : v.toString();

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  bool get _accentBorder => _hovered || _isOpen;

  @override
  Widget build(BuildContext context) {
    return buildTrigger(context);
  }
}
