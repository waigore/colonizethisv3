// Turn-start news modal. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'turn_news_dialog_sections.dart';
import 'turn_news_line_format.dart';

export 'turn_news_line_format.dart';

/// Prior-turn summary dialog; [newTurnNumber] is current turn after resolution.
class TurnNewsDialog extends StatelessWidget {
  const TurnNewsDialog({
    super.key,
    required this.game,
    required this.digest,
    required this.newTurnNumber,
    this.courtSummary = const TurnNewsCourtSummary.empty(),
    this.spyReportCount = 0,
    this.onOpenIntelligence,
    this.onOpenEvents,
  });

  static const screenId = UiScreenIds.turnNewsDialog;

  static Key courtBlockKey() => const ValueKey<String>('turn_news_court_block');

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;
  final TurnNewsCourtSummary courtSummary;
  final int spyReportCount;
  final VoidCallback? onOpenIntelligence;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: _TurnNewsDialogContent(
        game: game,
        digest: digest,
        newTurnNumber: newTurnNumber,
        courtSummary: courtSummary,
        spyReportCount: spyReportCount,
        onOpenIntelligence: onOpenIntelligence,
        onOpenEvents: onOpenEvents,
      ),
    );
  }
}

class _TurnNewsDialogContent extends StatelessWidget {
  const _TurnNewsDialogContent({
    required this.game,
    required this.digest,
    required this.newTurnNumber,
    required this.courtSummary,
    required this.spyReportCount,
    this.onOpenIntelligence,
    this.onOpenEvents,
  });

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;
  final TurnNewsCourtSummary courtSummary;
  final int spyReportCount;
  final VoidCallback? onOpenIntelligence;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleLarge ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final mutedStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.muted);
    final isEmpty = digest.lines.isEmpty;
    final hasCourt = !courtSummary.isEmpty;
    final lines = isEmpty
        ? const <String>[]
        : digest.lines.map((e) => formatTurnNewsLine(l10n, game, e)).toList();

    final courtParts = <String>[...courtSummary.clauses];
    if (courtSummary.overflowFamilyCount > 0) {
      courtParts.add(l10n.turnNews_courtMore(courtSummary.overflowFamilyCount));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.turnNews_title(newTurnNumber), style: titleStyle),
        const SizedBox(height: CtSpacing.ml),
        TurnNewsGazetteSection(
          isEmpty: isEmpty,
          hasCourt: hasCourt,
          lines: lines,
          emptyLabel: l10n.turnNews_empty,
          mutedStyle: mutedStyle,
          bodyStyle: bodyStyle,
        ),
        if (hasCourt) ...[
          if (!isEmpty) const SizedBox(height: CtSpacing.m),
          TurnNewsCourtBlock(
            key: TurnNewsDialog.courtBlockKey(),
            body: l10n.turnNews_courtBlock(courtParts.join(' · ')),
            openEventsLabel: l10n.turnNews_openEvents,
            mutedStyle: mutedStyle,
            onOpenEvents: onOpenEvents,
          ),
        ],
        const SizedBox(height: CtSpacing.l),
        if (spyReportCount > 0 && onOpenIntelligence != null)
          TurnNewsSpyFooter(
            label: l10n.turnNews_spiesFooter(spyReportCount),
            mutedStyle: mutedStyle,
            onOpenIntelligence: onOpenIntelligence!,
          ),
        Align(
          alignment: Alignment.centerRight,
          child: CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.turnNews_close),
          ),
        ),
      ],
    );
  }
}
