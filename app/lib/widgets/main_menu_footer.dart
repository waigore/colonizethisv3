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
