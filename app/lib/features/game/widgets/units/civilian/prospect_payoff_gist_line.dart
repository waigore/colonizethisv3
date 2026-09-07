/// Default-visible Prospect payoff gist. Refs #4741.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kProspectPayoffGistKey = Key('prospect_payoff_gist');

/// Muted body line; never replaces Prospect tooltip naming.
class ProspectPayoffGistLine extends StatelessWidget {
  const ProspectPayoffGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kProspectPayoffGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
