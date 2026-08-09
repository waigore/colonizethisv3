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

mixin GameStartIntroOverlayBuild on State<GameStartIntroOverlay> {
  CtDialogueView? get introView;
  Object? get introLoadError;
  set introLoadError(Object? value);
  bool get introDialogueFinished;
  DialogueRunner? get introRunner;

  Widget buildIntroOverlay(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    if (introLoadError != null) {
      return buildTitledDialogueChrome(
        backdrop: widget.child,
        title: l10n.gameStartIntroOverlay_title,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.game_intro_loadError('$introLoadError'),
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
                  setState(() => introLoadError = null);
                  widget.onDismissed();
                },
                child: Text(l10n.game_intervention_continue),
              ),
            ),
          ],
        ),
      );
    }

    if (introDialogueFinished) {
      return widget.child;
    }

    if (introView == null || introRunner == null) {
      return buildTitledDialogueChrome(
        backdrop: widget.child,
        title: l10n.gameStartIntroOverlay_title,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    return buildTitledDialogueChrome(
      backdrop: widget.child,
      title: l10n.gameStartIntroOverlay_title,
      body: CtDialogueLineChoiceBody(
        view: introView!,
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
