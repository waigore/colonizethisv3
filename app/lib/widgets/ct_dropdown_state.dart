import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import 'ct_dropdown.dart';
import 'ct_dropdown_constants.dart';
import 'ct_dropdown_picker.dart';

class CtDropdownState<T> extends State<CtDropdown<T>> {
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
    return _buildTrigger(context);
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isOpen = true);
    try {
      final chosen = await showCtDropdownPickerDialog<T>(
        context: context,
        items: widget.items,
        value: widget.value,
        hint: widget.hint,
        labelFor: labelFor,
        itemLeading: widget.itemLeading,
        selectedRowKey: CtDropdown.kCtDropdownPickerSelectedRowKey,
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

  Widget _buildTrigger(BuildContext context) {
    // Layout height stays at the compact visual size; OverflowBox expands
    // hit-testing to ≥ kMinTouchTargetSize without disturbing parent Row /
    // Column slot layouts (Refs #4062 / mobile-adaptation § 1).
    final Widget hitExpanded = SizedBox(
      height: kCtDropdownTriggerVisualMinHeight,
      width: widget.isExpanded ? double.infinity : null,
      child: OverflowBox(
        minHeight: kMinTouchTargetSize,
        maxHeight: kMinTouchTargetSize,
        alignment: Alignment.center,
        child: MouseRegion(
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: GestureDetector(
            key: CtDropdown.kCtDropdownTriggerHitTargetKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => _openPicker(context),
            child: SizedBox(
              height: kMinTouchTargetSize,
              width: widget.isExpanded ? double.infinity : null,
              child: Center(child: _buildTriggerVisual(context)),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      child: widget.isExpanded
          ? hitExpanded
          : IntrinsicWidth(child: hitExpanded),
    );
  }

  Widget _buildTriggerVisual(BuildContext context) {
    return DecoratedBox(
      key: CtDropdown.kCtDropdownTriggerVisualKey,
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.bgDeep,
        border: Border.all(
          color: _accentBorder
              ? EditorialMonoclePalette.accent
              : EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kCtDropdownTriggerVisualMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: _buttonChild(context),
        ),
      ),
    );
  }

  Widget _buttonChild(BuildContext context) {
    final selected = widget.value != null && widget.items.contains(widget.value)
        ? labelFor(widget.value as T)
        : (widget.hint ?? 'Select');

    final TextStyle labelStyle = TextStyle(
      fontSize: kCtDropdownLabelFontSize,
      color: EditorialMonoclePalette.fg,
      height: 1.2,
    );
    final Widget labelWidget = Text(
      selected,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );

    Widget? leading;
    if (widget.value != null &&
        widget.items.contains(widget.value) &&
        widget.itemLeading != null) {
      leading = widget.itemLeading!(context, widget.value as T);
    }

    // Right inset leaves room for the 10 px chevron (mockup padding
    // `6px 26px 6px 8px` — 8 left + ~10 chevron + ~8 gap ≈ 26 right).
    if (widget.isExpanded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Expanded(child: labelWidget),
          const SizedBox(width: 8),
          _buildChevron(),
        ],
      );
    }

    if (leading != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Flexible(child: labelWidget),
          const SizedBox(width: 8),
          _buildChevron(),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: labelWidget),
        const SizedBox(width: 8),
        _buildChevron(),
      ],
    );
  }

  /// Trigger chevron-down glyph that rotates 180° to chevron-up when the
  /// picker opens, per #2859 R5d. The chevron colour resolves to
  /// `--accent-dim` from the editorial-monocle palette; no hex literals.
  Widget _buildChevron() {
    return AnimatedRotation(
      key: CtDropdown.kChevronAnimatedRotationKey,
      turns: _isOpen
          ? kCtDropdownChevronOpenTurns
          : kCtDropdownChevronClosedTurns,
      duration: kCtDropdownChevronAnimationDuration,
      curve: Curves.easeOut,
      child: Icon(
        Icons.expand_more,
        size: kCtDropdownChevronSize,
        color: EditorialMonoclePalette.accentDim,
      ),
    );
  }
}
