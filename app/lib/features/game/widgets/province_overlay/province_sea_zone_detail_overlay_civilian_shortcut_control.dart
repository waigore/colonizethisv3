import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

/// Station spy / Counter-espionage control for MAP20001 Civilian (Refs #4528).
Widget? buildProvinceOverlayCivilianShortcutControl({
  required bool showControl,
  required String label,
  required String tooltip,
  required bool enabled,
  required VoidCallback? onTap,
  String gist = '',
}) {
  if (!showControl) return null;
  final button = CtActionTextButton(
    label: label,
    tooltip: tooltip,
    enabled: enabled,
    onPressed: enabled ? onTap : null,
  );
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: gist.isEmpty
        ? button
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              button,
              Text(
                gist,
                style: TextStyle(
                  color: EditorialMonoclePalette.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
  );
}
