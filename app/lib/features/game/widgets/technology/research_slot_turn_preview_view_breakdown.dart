import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view_breakdown_rows.dart';

export 'research_slot_turn_preview_view_breakdown_rows.dart'
    show spyInsightBreakdownLabel, joinCourtDisplayNames;

/// Opens the research-funding breakdown dialog (Refs #4117 de-part).
void showResearchFundingBreakdownDialog({
  required BuildContext context,
  required ResearchSlotTurnPreview preview,
}) {
  showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => ResearchFundingBreakdownDialog(preview: preview),
  );
}

/// Read-only research-funding breakdown modal. SPEC/ui/technology-panel.md
/// § Slot turn preview.
@visibleForTesting
class ResearchFundingBreakdownDialog extends StatelessWidget {
  const ResearchFundingBreakdownDialog({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyPanel_rpBreakdownTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          ResearchFundingBreakdownMetrics(preview: preview, l10n: l10n),
          ResearchFundingBreakdownBlockedNotice(
            preview: preview,
            l10n: l10n,
            theme: theme,
          ),
          const SizedBox(height: CtSpacing.ml),
          CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}
