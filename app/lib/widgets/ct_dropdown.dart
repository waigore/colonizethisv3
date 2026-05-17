import 'package:flutter/material.dart';

import 'ct_dialog_shell.dart';
import 'ct_nine_patch_button.dart';

/// Pixel-art dropdown: nine-patch button + modal list of options.
class CtDropdown<T> extends StatelessWidget {
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

  String _labelFor(T v) => itemLabel != null ? itemLabel!(v) : v.toString();

  @override
  Widget build(BuildContext context) {
    return CtNinePatchButton(
      onPressed: () => _openPicker(context),
      child: _buttonChild(context),
    );
  }

  Widget _buttonChild(BuildContext context) {
    final selected = value != null && items.contains(value)
        ? _labelFor(value as T)
        : (hint ?? 'Select');

    final Widget labelWidget = Text(selected, overflow: TextOverflow.ellipsis);

    Widget? leading;
    if (value != null && items.contains(value) && itemLeading != null) {
      leading = itemLeading!(context, value as T);
    }

    Widget buttonChild = labelWidget;

    if (isExpanded) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(child: labelWidget),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 16),
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

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showDialog<T>(
      context: context,
      builder: (ctx) => CtDialogShell(
        maxWidth: 320,
        maxHeight: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hint != null) ...[
              Text(hint!, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final v = items[index];
                final label = _labelFor(v);
                final rowLeading = itemLeading?.call(context, v);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
                            child: Text(label, overflow: TextOverflow.ellipsis),
                          ),
                        ],
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
      onChanged(chosen);
    }
  }
}
