/// Default-visible transport-step payoff gist. Refs #4663.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kTransportStepYieldGistKey = Key('transport_step_yield_gist');

/// Muted body line beside Build road / port / railroad controls.
class TransportStepYieldGistLine extends StatelessWidget {
  const TransportStepYieldGistLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: kTransportStepYieldGistKey,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: EditorialMonoclePalette.muted),
      ),
    );
  }
}
