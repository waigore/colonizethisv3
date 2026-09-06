/// Default-visible Explore payoff gist. Refs #4733.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kExplorePayoffGistKey = Key('explore_payoff_gist');

/// Muted body line; never replaces Explore tooltip naming.
class ExplorePayoffGistLine extends StatelessWidget {
  const ExplorePayoffGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kExplorePayoffGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
