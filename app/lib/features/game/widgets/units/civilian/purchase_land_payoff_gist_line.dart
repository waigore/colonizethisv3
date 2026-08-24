/// Default-visible Purchase land payoff gist. Refs #4630.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kPurchaseLandPayoffGistKey = Key('purchase_land_payoff_gist');

/// Muted body line; never replaces the £ cost.
class PurchaseLandPayoffGistLine extends StatelessWidget {
  const PurchaseLandPayoffGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kPurchaseLandPayoffGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
