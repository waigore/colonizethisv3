import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'ct_dialogue_line_choice_body.dart';
import 'ct_dialogue_view.dart';
import 'game_start_intro_overlay.dart';
import 'titled_dialogue_chrome.dart';
import 'tribe_first_contact_overlay.dart';

mixin TribeFirstContactOverlayBuild on State<TribeFirstContactOverlay> {
  CtDialogueView? get tribeContactView;
  Object? get tribeContactLoadError;
  set tribeContactLoadError(Object? value);
  bool get tribeContactDialogueFinished;
  DialogueRunner? get tribeContactRunner;

  Widget buildTribeFirstContactOverlay(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    if (tribeContactLoadError != null) {
      return buildTitledDialogueChrome(
        backdrop: widget.child,
        title: l10n.tribeFirstContactOverlay_title,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tribeFirstContactOverlay_loadError('$tribeContactLoadError'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.accentDim,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CtSpacing.l),
            Align(
              alignment: Alignment.center,
              child: CtNinePatchButton(
                onPressed: () {
                  setState(() => tribeContactLoadError = null);
                  widget.onDismissed();
                },
                child: Text(l10n.game_intervention_continue),
              ),
            ),
          ],
        ),
      );
    }

    if (tribeContactDialogueFinished) {
      return widget.child;
    }

    if (tribeContactView == null || tribeContactRunner == null) {
      return buildTitledDialogueChrome(
        backdrop: widget.child,
        title: l10n.tribeFirstContactOverlay_title,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    return buildTitledDialogueChrome(
      backdrop: widget.child,
      title: l10n.tribeFirstContactOverlay_title,
      body: CtDialogueLineChoiceBody(
        view: tribeContactView!,
        continueLabel: l10n.game_intervention_continue,
        lineTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        lineTextAlign: TextAlign.center,
        continueAlignment: Alignment.center,
        loading: const GameStartIntroLoadingIndicator(),
      ),
    );
  }
}
