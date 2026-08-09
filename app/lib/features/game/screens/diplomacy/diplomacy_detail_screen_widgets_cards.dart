import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Inner heading inside a [DiplomacyDetailCard]. Matches the GAME30002 mockup
/// `.card h3` rule (display font, 13 px, `--muted`, uppercase, letter-spacing
/// 0.06 em). Separate from `CtSectionLabel` because card titles do not paint
/// a bottom border on the mockup.
class DiplomacyDetailCardTitle extends StatelessWidget {
  const DiplomacyDetailCardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseDisplay =
        theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: baseDisplay.copyWith(
          color: EditorialMonoclePalette.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.06 * 13,
        ),
      ),
    );
  }
}

/// Framed card with gradient background (`--surface-lite → --surface →
/// --bg-deep`) and a 1 px `--border` outline. Mirrors mockup `.card`.
class DiplomacyDetailCard extends StatelessWidget {
  const DiplomacyDetailCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const <double>[0.0, 0.3, 1.0],
          colors: <Color>[
            EditorialMonoclePalette.surfaceLite,
            EditorialMonoclePalette.surface,
            EditorialMonoclePalette.bgDeep,
          ],
        ),
        border: Border.all(color: EditorialMonoclePalette.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DiplomacyDetailCardTitle(title),
            child,
          ],
        ),
      ),
    );
  }
}
