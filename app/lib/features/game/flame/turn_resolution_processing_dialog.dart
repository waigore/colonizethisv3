import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_loading_indicator.dart';

class TurnResolutionProcessingDialog extends StatelessWidget {
  const TurnResolutionProcessingDialog({required this.phaseText, super.key});

  final String phaseText;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: CtDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appL10n(context).game_turnResolutionProcessingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
            const CtLoadingIndicator(
              size: 16,
              strokeWidth: 2,
              center: false,
            ),
                const SizedBox(width: 10),
                Expanded(child: Text(phaseText)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
