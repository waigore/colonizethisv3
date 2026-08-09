import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show DevelopmentRoadFirstState;
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';

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
    final l10n = appL10n(context);
    final textTheme = Theme.of(context).textTheme;
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.development_disconnectedTitle,
            style: textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          Text(
            l10n.development_disconnectedBody,
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
    final l10n = appL10n(context);
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
      child: Text(l10n.development_roadFirst),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CtNinePatchButton(
          key: const ValueKey<String>(kDevelopmentImproveAnywayButtonKey),
          onPressed: () => Navigator.of(
            context,
          ).pop(DevelopmentDisconnectedAssignChoice.improveAnyway),
          child: Text(l10n.development_improveAnyway),
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
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
