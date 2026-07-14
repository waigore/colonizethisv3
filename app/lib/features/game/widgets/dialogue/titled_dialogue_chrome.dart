// Shared titled dialogue chrome (title + brass divider + body) for intro and
// tribe-first-contact overlays. Refs #4018.
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_full_screen_dialogue_shell.dart';
import '../../../../widgets/ct_spacing.dart';

/// Cinzel-style display title above the brass divider in titled dialogue
/// overlays. Color resolves from `EditorialMonoclePalette.accent`; letter
/// spacing matches dark-theme dialog title contract (`0.05em` at 16 px).
class TitledDialogueChromeTitle extends StatelessWidget {
  const TitledDialogueChromeTitle({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(
            color: EditorialMonoclePalette.accent,
            letterSpacing: 0.05 * 16,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Full-screen scrim shell with canonical title → brass divider → [body]
/// chrome used by intro and tribe-first-contact dialogue overlays.
Widget buildTitledDialogueChrome({
  required Widget backdrop,
  required String title,
  required Widget body,
  EdgeInsetsGeometry padding = CtFullScreenDialogueShell.defaultPadding,
}) {
  return CtFullScreenDialogueShell(
    backdrop: backdrop,
    padding: padding,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitledDialogueChromeTitle(text: title),
        const SizedBox(height: CtSpacing.ml),
        const CtBrassDivider(),
        const SizedBox(height: 14),
        body,
      ],
    ),
  );
}
