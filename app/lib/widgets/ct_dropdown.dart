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
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool isExpanded;
  final String Function(T value)? itemLabel;

  String _labelFor(T v) => itemLabel != null ? itemLabel!(v) : v.toString();

  @override
  Widget build(BuildContext context) {
    final selected = value != null && items.contains(value)
        ? _labelFor(value as T)
        : (hint ?? 'Select');

    Widget buttonChild = Text(
      selected,
      overflow: TextOverflow.ellipsis,
    );

    if (isExpanded) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              selected,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 16),
        ],
      );
    }

    return CtNinePatchButton(
      onPressed: () async {
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
                  Text(
                    hint!,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final v = items[index];
                      final label = _labelFor(v);
                      final selected = v == value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: CtNinePatchButton(
                          onPressed: () {
                            Navigator.of(ctx).pop(v);
                          },
                          enabled: true,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        if (chosen != null) {
          onChanged(chosen);
        }
      },
      child: buttonChild,
    );
  }
}

