part of 'game_start_intro_overlay.dart';

extension _GameStartIntroOverlayBuild on _GameStartIntroOverlayState {
  Widget buildIntroOverlay(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    if (_loadError != null) {
      return CtFullScreenDialogueShell(
        backdrop: widget.child,
        padding: const EdgeInsets.all(CtSpacing.l),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IntroTitle(text: l10n.gameStartIntroOverlay_title),
            const SizedBox(height: CtSpacing.ml),
            const CtBrassDivider(),
            const SizedBox(height: 14),
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
      return _introChromeBody(
        l10n: l10n,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    return _introChromeBody(
      l10n: l10n,
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

  Widget _introChromeBody({
    required AppLocalizations l10n,
    required Widget body,
  }) {
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntroTitle(text: l10n.gameStartIntroOverlay_title),
          const SizedBox(height: CtSpacing.ml),
          const CtBrassDivider(),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

/// Cinzel display-font title shown above the brass divider in every
/// non-dismissed state of the intro overlay. Color resolves from
/// `EditorialMonoclePalette.accent`; styling matches the editorial-monocle
/// mockup `SPEC/ui/mockups/OVL10001-game-intro-overlay.html`.
class _IntroTitle extends StatelessWidget {
  const _IntroTitle({required this.text});

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
            // 0.05em at Material 3 titleMedium fontSize 16 ≈ 0.8 logical px.
            // Matches `SPEC/ui/mockups/OVL10001-game-intro-overlay.html`
            // `.dialog-title` letter-spacing (mockup uses 0.06em; SPEC/UI
            // restyle table in #2867 R2 pins 0.05em as the dark-theme dialog
            // title contract; both render at the same eye-level on the 16 px
            // Material titleMedium baseline used here).
            letterSpacing: 0.05 * 16,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
