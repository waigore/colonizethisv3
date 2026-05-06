import 'package:flutter/material.dart';
import '../../../../widgets/ct_dialog_shell.dart';

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
              'Processing Turn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
