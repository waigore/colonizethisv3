/// Modal picker dialog body for [CtDropdown].
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'ct_dialog_shell.dart';
import 'ct_dropdown_constants.dart';

Future<T?> showCtDropdownPickerDialog<T>({
  required BuildContext context,
  required List<T> items,
  required T? value,
  required String? hint,
  required String Function(T value) labelFor,
  Widget? Function(BuildContext context, T value)? itemLeading,
  Key? selectedRowKey,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => CtDialogShell(
      maxWidth: 320,
      maxHeight: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Text(hint, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final v = items[index];
              final label = labelFor(v);
              final rowLeading = itemLeading?.call(context, v);
              final bool isSelected = value != null && v == value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: DecoratedBox(
                  key: isSelected ? selectedRowKey : null,
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop(v);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: kCtDropdownPickerRowVisualMinHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
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
                                    style: TextStyle(
                                      fontSize: kCtDropdownLabelFontSize,
                                      color: EditorialMonoclePalette.fg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
