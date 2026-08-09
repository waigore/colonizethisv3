part of 'ct_dropdown.dart';

extension _CtDropdownPicker<T> on _CtDropdownState<T> {
  Future<void> openPicker(BuildContext context) async {
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
                  final label = labelFor(v);
                  final rowLeading = widget.itemLeading?.call(context, v);
                  final bool isSelected =
                      widget.value != null && v == widget.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
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
