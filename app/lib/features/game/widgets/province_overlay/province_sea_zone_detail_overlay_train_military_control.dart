import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

const Key kProvinceOverlayTrainMilitaryKey = Key(
  'province_overlay_train_military',
);

/// MAP20001 Military **Train** plus Home Army gist (Refs #4769).
Widget? buildProvinceOverlayTrainMilitaryControl({
  required AppLocalizations l10n,
  required bool show,
  VoidCallback? onTap,
}) {
  if (!show) return null;
  final label = l10n.provinceOverlay_trainMilitaryAction;
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CtActionTextButton(
          key: kProvinceOverlayTrainMilitaryKey,
          label: label,
          tooltip: label,
          enabled: true,
          onPressed: onTap,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.provinceOverlay_trainMilitaryGist,
            style: TextStyle(color: EditorialMonoclePalette.muted),
          ),
        ),
      ],
    ),
  );
}
