/// Default-visible spy research-insight gist for UNIT10001 (Refs #4679).
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kSpyResearchInsightGistKey = Key('spy_research_insight_gist');

class SpyResearchInsightGistLine extends StatelessWidget {
  const SpyResearchInsightGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kSpyResearchInsightGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
