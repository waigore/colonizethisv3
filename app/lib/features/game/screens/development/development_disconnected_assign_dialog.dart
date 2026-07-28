import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';

/// Player choice from the disconnected improve warn dialog. Refs #4175 Slice C.
enum DevelopmentDisconnectedAssignChoice {
  improveAnyway,
  roadFirst,
  cancel,
}

/// Stable keys for disconnected-assign dialog buttons (widget/golden tests).
const String kDevelopmentImproveAnywayButtonKey =
    'developmentDisconnectedImproveAnywayButton';
const String kDevelopmentRoadFirstButtonKey =
    'developmentDisconnectedRoadFirstButton';
const String kDevelopmentDisconnectedCancelButtonKey =
    'developmentDisconnectedCancelButton';

/// Warn dialog when Assign targets a tile not connected to the capital.
class DevelopmentDisconnectedAssignDialog extends StatelessWidget {
  const DevelopmentDisconnectedAssignDialog({
    super.key,
    required this.roadFirstState,
  });

  final DevelopmentRoadFirstState roadFirstState;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Not connected to capital',
            style: textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          Text(
            'The chosen tile is not linked to your capital. Improve anyway, '
            'build a road step toward the capital first, or cancel.',
            style: textTheme.bodyMedium?.copyWith(
              color: EditorialMonoclePalette.fg,
            ),
          ),
          const SizedBox(height: CtSpacing.l),
          _DisconnectedAssignActions(roadFirstState: roadFirstState),
        ],
      ),
    );
  }
}

class _DisconnectedAssignActions extends StatelessWidget {
  const _DisconnectedAssignActions({required this.roadFirstState});

  final DevelopmentRoadFirstState roadFirstState;

  @override
  Widget build(BuildContext context) {
    final roadFirstTooltip = roadFirstState.enabled
        ? null
        : roadFirstState.disabledReason;
    final roadFirstButton = CtNinePatchButton(
      key: const ValueKey<String>(kDevelopmentRoadFirstButtonKey),
      mutedVariant: true,
      onPressed: roadFirstState.enabled
          ? () => Navigator.of(
              context,
            ).pop(DevelopmentDisconnectedAssignChoice.roadFirst)
          : null,
      child: const Text('Road first'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CtNinePatchButton(
          key: const ValueKey<String>(kDevelopmentImproveAnywayButtonKey),
          onPressed: () => Navigator.of(
            context,
          ).pop(DevelopmentDisconnectedAssignChoice.improveAnyway),
          child: const Text('Improve anyway'),
        ),
        const SizedBox(height: CtSpacing.s),
        if (roadFirstTooltip != null)
          Tooltip(message: roadFirstTooltip, child: roadFirstButton)
        else
          roadFirstButton,
        const SizedBox(height: CtSpacing.s),
        CtNinePatchButton(
          key: const ValueKey<String>(kDevelopmentDisconnectedCancelButtonKey),
          mutedVariant: true,
          onPressed: () => Navigator.of(
            context,
          ).pop(DevelopmentDisconnectedAssignChoice.cancel),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Shows the disconnected improve warn dialog per SPEC/ui/development-panel.md.
Future<DevelopmentDisconnectedAssignChoice> showDevelopmentDisconnectedAssignDialog(
  BuildContext context, {
  required DevelopmentRoadFirstState roadFirstState,
}) async {
  final result = await showDialog<DevelopmentDisconnectedAssignChoice>(
    context: context,
    barrierDismissible: true,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) =>
        DevelopmentDisconnectedAssignDialog(roadFirstState: roadFirstState),
  );
  return result ?? DevelopmentDisconnectedAssignChoice.cancel;
}
