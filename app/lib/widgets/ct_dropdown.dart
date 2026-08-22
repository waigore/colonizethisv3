import 'package:flutter/material.dart';

import 'ct_dropdown_state.dart';

export 'ct_dropdown_constants.dart';
export 'ct_dropdown_state.dart' show CtDropdownState;

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
  State<CtDropdown<T>> createState() => CtDropdownState<T>();
}
