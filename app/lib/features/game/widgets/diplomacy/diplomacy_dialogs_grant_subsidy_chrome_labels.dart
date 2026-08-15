import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Dialog title — display font, `--accent` color, `letterSpacing = fontSize * 0.05`.
class GrantSubsidyDialogTitle extends StatelessWidget {
  const GrantSubsidyDialogTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final double fontSize = base.fontSize ?? 16;
    final style = base.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: fontSize * 0.05,
    );
    return Text(
      title,
      key: const Key('grantOrSubsidyDialogTitle'),
      style: style,
    );
  }
}

/// Treasury info line — body slot, `--muted` color.
class GrantSubsidyTreasuryRow extends StatelessWidget {
  const GrantSubsidyTreasuryRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    final style = base.copyWith(color: EditorialMonoclePalette.muted);
    return Text(
      label,
      key: const Key('grantOrSubsidyDialogTreasury'),
      style: style,
    );
  }
}

/// 1 dp solid divider in `--border` between treasury row and stepper. Matches
/// `.divider-thin` in `SPEC/ui/mockups/DIPL20001-grant-or-subsidy-dialog.html`.
class GrantSubsidyThinDivider extends StatelessWidget {
  const GrantSubsidyThinDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('grantOrSubsidyDialogThinDivider'),
      height: 1,
      decoration: BoxDecoration(color: EditorialMonoclePalette.border),
    );
  }
}

/// Amount label — display font (headlineSmall slot), `--fg` color,
/// `letterSpacing = fontSize * 0.04`, min 80 dp content width.
class GrantSubsidyAmountLabel extends StatelessWidget {
  const GrantSubsidyAmountLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.headlineSmall ?? const TextStyle(fontSize: 24);
    final double fontSize = base.fontSize ?? 24;
    final style = base.copyWith(
      color: EditorialMonoclePalette.fg,
      letterSpacing: fontSize * 0.04,
      fontWeight: FontWeight.w700,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 80),
      child: Text(
        text,
        key: const Key('grantOrSubsidyDialogAmount'),
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

/// Below-minimum warning — italic body slot, `--danger` color.
class GrantSubsidyBelowMinimumWarning extends StatelessWidget {
  const GrantSubsidyBelowMinimumWarning({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    final style = base.copyWith(
      color: EditorialMonoclePalette.danger,
      fontStyle: FontStyle.italic,
    );
    return Text(
      text,
      key: const Key('grantOrSubsidyDialogWarning'),
      style: style,
    );
  }
}

/// Live Cost / Effect lines from [buildDiplomacyConfirmPreviewLines] (Refs #4415).
class GrantSubsidyConfirmPreview extends StatelessWidget {
  const GrantSubsidyConfirmPreview({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall ?? const TextStyle();
    final style = base.copyWith(color: EditorialMonoclePalette.muted);
    return Column(
      key: const Key('grantOrSubsidyDialogPreview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) Text(line, style: style, softWrap: true),
      ],
    );
  }
}
