part of 'ct_dropdown.dart';

extension _CtDropdownTrigger<T> on _CtDropdownState<T> {
  Widget buttonChild(BuildContext context) {
    final selected = widget.value != null && widget.items.contains(widget.value)
        ? labelFor(widget.value as T)
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
          buildChevron(),
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
  Widget buildChevron() {
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
}
