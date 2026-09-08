/// Default-visible Upgrade town payoff gist. Refs #4747.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kUpgradeTownPayoffGistKey = Key('upgrade_town_payoff_gist');

/// Muted body line; never replaces lumber/cast-iron cost tooltips.
class UpgradeTownPayoffGistLine extends StatelessWidget {
  const UpgradeTownPayoffGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kUpgradeTownPayoffGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
