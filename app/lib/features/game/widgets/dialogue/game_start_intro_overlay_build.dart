part of 'game_start_intro_overlay.dart';

extension _GameStartIntroOverlayBuild on _GameStartIntroOverlayState {
  Widget buildIntroOverlay(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    if (_loadError != null) {
      return buildTitledDialogueChrome(
        backdrop: widget.child,
        title: l10n.gameStartIntroOverlay_title,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.game_intro_loadError('$_loadError'),
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
                  setState(() => _loadError = null);
                  widget.onDismissed();
                },
                child: Text(l10n.game_intervention_continue),
              ),
            ),
          ],
        ),
      );
    }

    if (_dialogueFinished) {
      return widget.child;
    }

    if (_view == null || _runner == null) {
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
        view: _view!,
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
