/// Default-visible Build improvement next-yield gist. Refs #4627.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kBuildImprovementNextYieldGistKey = Key(
  'build_improvement_next_yield_gist',
);

/// Muted body line; never replaces lumber/cast-iron cost.
class BuildImprovementYieldGistLine extends StatelessWidget {
  const BuildImprovementYieldGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kBuildImprovementNextYieldGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
