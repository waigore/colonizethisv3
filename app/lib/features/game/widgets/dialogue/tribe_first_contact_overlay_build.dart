part of 'tribe_first_contact_overlay.dart';

extension _TribeFirstContactOverlayBuild on _TribeFirstContactOverlayState {
  Widget buildTribeFirstContactOverlay(BuildContext context) {
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
            _TribeFirstContactTitle(text: l10n.tribeFirstContactOverlay_title),
            const SizedBox(height: CtSpacing.ml),
            const CtBrassDivider(),
            const SizedBox(height: 14),
            Text(
              l10n.tribeFirstContactOverlay_loadError('$_loadError'),
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
      return _chromeBody(
        l10n: l10n,
        body: const GameStartIntroLoadingIndicator(),
      );
    }

    return _chromeBody(
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

  Widget _chromeBody({required AppLocalizations l10n, required Widget body}) {
    return CtFullScreenDialogueShell(
      backdrop: widget.child,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TribeFirstContactTitle(text: l10n.tribeFirstContactOverlay_title),
          const SizedBox(height: CtSpacing.ml),
          const CtBrassDivider(),
          const SizedBox(height: 14),
          body,
        ],
      ),
    );
  }
}

class _TribeFirstContactTitle extends StatelessWidget {
  const _TribeFirstContactTitle({required this.text});

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
