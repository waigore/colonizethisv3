// Title + muted composition lines for DLG20002 / DLG31003 picker rows (Refs #4385).

import 'package:flutter/material.dart';

import '../../../../widgets/ct_spacing.dart';
import 'move_units_dialog_base_styles.dart';

/// Picker-row `content`: unit title plus muted `bodySmall` composition lines.
class UnitPickerCompositionContent extends StatelessWidget {
  const UnitPickerCompositionContent({
    super.key,
    required this.title,
    required this.compositionLines,
    required this.selected,
  });

  final String title;
  final List<String> compositionLines;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: moveDialogRowLabelStyle(theme, selected: selected),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        for (final line in compositionLines) ...[
          const SizedBox(height: CtSpacing.xs),
          Text(
            line,
            style: moveDialogCompositionTextStyle(theme),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
