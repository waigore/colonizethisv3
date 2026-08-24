import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'move_units_dialog_base.dart';

/// Capital in-port marker choice: Sail/Move vs Transfer (Refs #4625).
enum InPortFleetMarkerAction { sailMove, transferHome }

/// DLG31004 — keeps Sail/Move while offering Transfer at the capital harbor.
class InPortFleetMarkerActionsDialog extends StatelessWidget {
  const InPortFleetMarkerActionsDialog({super.key});

  static const screenId = UiScreenIds.inPortFleetMarkerActionsDialog;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.inPortFleetMarker_chooseActionTitle,
            style: moveDialogTitleTextStyle(theme),
          ),
          const SizedBox(height: CtSpacing.ml),
          CtNinePatchButton(
            onPressed: () =>
                Navigator.pop(context, InPortFleetMarkerAction.sailMove),
            child: Text(l10n.naval_mission_sail),
          ),
          const SizedBox(height: CtSpacing.m),
          CtNinePatchButton(
            onPressed: () =>
                Navigator.pop(context, InPortFleetMarkerAction.transferHome),
            child: Text(l10n.provinceOverlay_transferToHomeFleetAction),
          ),
          const SizedBox(height: CtSpacing.l),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              mutedVariant: true,
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
          ),
        ],
      ),
    );
  }
}
