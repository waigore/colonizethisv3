/// Default-visible Build fort payoff gist. Refs #4668.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kBuildFortPayoffGistKey = Key('build_fort_payoff_gist');

/// Muted body line; never replaces lumber/bronze/steel cost tooltips.
class BuildFortPayoffGistLine extends StatelessWidget {
  const BuildFortPayoffGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kBuildFortPayoffGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
