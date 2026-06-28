// Main-menu footer widgets, split out from `main_menu.dart` to keep the host
// file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`.
//
// All classes here are library-private (`_MainMenuFooter`,
// `_PixelArtFooterVersion`, `_FooterQuitButton`) and consumed only by the
// main-menu body inside the parent library.

part of 'main_menu.dart';

/// Footer region for both variants. Renders the version text above a Quit
/// control; in the `pixelArt` variant the Quit control is the smaller,
/// `--muted`, border-only chip per `SPEC/ui/main-menu.md` § Variant
/// rendering (AC 9), while the `plain` variant continues to use a regular
/// [CtNinePatchButton] for backward compatibility.
class _MainMenuFooter extends StatelessWidget {
  const _MainMenuFooter({
    required this.variant,
    required this.version,
    required this.quitLabel,
    required this.onQuit,
  });

  final MainMenuVariant variant;
  final String version;
  final String quitLabel;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    if (variant == MainMenuVariant.pixelArt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PixelArtFooterVersion(version: version),
          const SizedBox(height: 12),
          _FooterQuitButton(label: quitLabel, onPressed: onQuit),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(version, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: CtNinePatchButton(
            onPressed: onQuit,
            child: Text(quitLabel),
          ),
        ),
      ],
    );
  }
}

/// Monospace `--muted` version line for the `pixelArt` variant footer.
/// Mirrors mockup `.version { font-family: var(--font-mono); color:
/// var(--muted); letter-spacing: 0.08em; text-transform: uppercase; }` and
/// realises the `SPEC/ui/main-menu.md` § Variant rendering row "Footer
/// version text — Monospace (`--font-mono`), `--muted` token from #2858".
class _PixelArtFooterVersion extends StatelessWidget {
  const _PixelArtFooterVersion({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final TextStyle? baseStyle = Theme.of(context).textTheme.bodySmall;
    return Text(
      version.toUpperCase(),
      style: (baseStyle ?? const TextStyle()).copyWith(
        color: EditorialMonoclePalette.muted,
        fontFamily: 'monospace',
        fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
        // Mirrors mockup `.version { letter-spacing: 0.08em }` at the 12 px
        // text size (~0.96 px). Kept distinct from the wood-panel button
        // label letter-spacing constants so screen tests can assert button
        // letter-spacing without picking up the version line.
        letterSpacing: 0.96,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Secondary footer Quit chip for the `pixelArt` variant. Implements
/// `SPEC/ui/main-menu.md` § Variant rendering — Quit button row and AC 9
/// from issue #2860: smaller than the primary wood-panel buttons, `--muted`
/// foreground, border-only chrome (`--border` top/bottom and 1px left/right
/// edges), and no brass corner brackets. Mirrors the mockup `.quit-btn`
/// element in `SPEC/ui/mockups/SHEL10002-main-menu.html`.
class _FooterQuitButton extends StatefulWidget {
  const _FooterQuitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_FooterQuitButton> createState() => _FooterQuitButtonState();
}

class _FooterQuitButtonState extends State<_FooterQuitButton> {
  bool _hovered = false;

  void _setHover(bool entered) {
    if (_hovered == entered) return;
    setState(() => _hovered = entered);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.labelLarge ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final Color foreground = _hovered
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    final LinearGradient gradient = _hovered
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              EditorialMonoclePalette.surfaceLite,
              EditorialMonoclePalette.surface,
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              EditorialMonoclePalette.surface,
              EditorialMonoclePalette.bgDeep,
            ],
          );

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: ConstrainedBox(
            key: const Key(kMainMenuFooterQuitKey),
            constraints: const BoxConstraints(
              minHeight: kMainMenuFooterQuitMinHeight,
              minWidth: 120,
              maxWidth: kMainMenuFooterQuitMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                border: Border(
                  top: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  left: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                  right: BorderSide(
                    color: EditorialMonoclePalette.border,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CtSpacing.xl,
                  vertical: CtSpacing.m,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: baseStyle.copyWith(
                      color: foreground,
                      fontFamily: editorialMonocleDisplayFontFamily,
                      fontSize: kMainMenuFooterQuitFontSize,
                      // Kept at 1.4 (distinct from the wood-panel button
                      // letter-spacing constants) so the narrow/wide button
                      // letter-spacing ACs do not pick up the Quit chip
                      // label; ≈0.1em at the 12 dp chip font per mockup
                      // `.quit-btn { letter-spacing: 0.1em }`.
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
