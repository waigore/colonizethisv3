import 'package:flutter/material.dart';

import '../../../providers/observe_session_provider.dart';
import '../../../widgets/ct_gap.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_spacing.dart';

/// Placeholder for P4–P17 chrome when global observe hides player-scoped data.
/// SPEC/ui/observe-mode.md.
class ObserveModeNotDefinedPanel extends StatelessWidget {
  const ObserveModeNotDefinedPanel({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CtSpacing.xxl),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              CtGap.ml,
            ],
            Text(
              kObserveNotDefinedLabel,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
