import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kProvinceOverlayTrainNavalKey = Key('province_overlay_train_naval');

/// MAP20001 Naval **Train** plus Home Fleet gist (Refs #4776).
Widget? buildProvinceOverlayTrainNavalControl({
  required AppLocalizations l10n,
  required bool show,
  VoidCallback? onTap,
}) {
  if (!show) return null;
  final label = l10n.provinceOverlay_trainNavalAction;
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CtActionTextButton(
          key: kProvinceOverlayTrainNavalKey,
          label: label,
          tooltip: label,
          enabled: true,
          onPressed: onTap,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.provinceOverlay_trainNavalGist,
            style: TextStyle(color: EditorialMonoclePalette.muted),
          ),
        ),
      ],
    ),
  );
}
