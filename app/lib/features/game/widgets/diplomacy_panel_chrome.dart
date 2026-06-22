// Section heading + faction kind badge + relation state badge chrome for
// DiplomacyPanel. SPEC/ui/diplomacy-panel.md § Section headings,
// § Per-faction row → Type badge colors, and § Relation state badge.

part of 'diplomacy_panel.dart';

/// Translucent overlay used as the WAR-state badge background, derived
/// from the `--danger` hue at lightness 0.40, chroma 0.06, hue 20, alpha
/// 0.40. SPEC/ui/diplomacy-panel.md § Relation state badge cites the
/// mockup token `oklch(40% 0.06 20 / 0.4)` directly; this constant
/// computes the same OKLCH sRGB approximation through [oklchToColor].
final Color _kWarBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 20),
).withValues(alpha: 0.4);

/// Translucent overlay used as the PEACE-state badge background, derived
/// from the `--success` hue at lightness 0.40, chroma 0.06, hue 150,
/// alpha 0.20. SPEC/ui/diplomacy-panel.md § Relation state badge cites
/// the mockup token `oklch(40% 0.06 150 / 0.2)`.
final Color _kPeaceBadgeBackground = oklchToColor(
  const OklchToken(0.40, 0.06, 150),
).withValues(alpha: 0.2);

/// Section heading for a diplomacy faction group (Great Powers / Minor
/// Nations / Tribes).
///
/// SPEC/ui/diplomacy-panel.md § Section headings: display font, `--accent`
/// text color, 2 px `--accent-dim` bottom border per
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.section-head`.
class _DiplomacySectionHeader extends StatelessWidget {
  const _DiplomacySectionHeader({required this.title, this.isFirst = false});

  final String title;

  /// Whether this is the first section heading rendered in the list under the
  /// active mode-bar filter. SPEC/ui/diplomacy-panel.md § Section headings
  /// (first-heading top rhythm, Refs #3621): the first heading drops its top
  /// gap to `0` (mockup `.section-head:first-child { margin-top: 0 }`) while
  /// every subsequent heading keeps the `CtSpacing.l` leading gap.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final TextStyle headingStyle = baseStyle.copyWith(
      color: EditorialMonoclePalette.accent,
      fontFamily: editorialMonocleDisplayFontFamily,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : CtSpacing.l,
        bottom: CtSpacing.m,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: EditorialMonoclePalette.accentDim,
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: CtSpacing.s),
          child: Text(title, style: headingStyle),
        ),
      ),
    );
  }
}

/// Faction type badge (GP / Minor / Tribe) for diplomacy rows.
///
/// SPEC/ui/diplomacy-panel.md § Per-faction row → Type badge colors:
/// - GP: `--accent-dim` background, `--bg-deep` foreground.
/// - Minor: `--muted` background, `--bg-deep` foreground.
/// - Tribe: outlined — transparent background, `--muted` border + foreground.
///
/// Matches [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.f-badge` chrome (mono font, tight letter-spacing, square `1px`
/// border-radius). All colors resolve from the canonical editorial-monocle
/// palette — no hardcoded Material chrome.
class _FactionKindBadge extends StatelessWidget {
  const _FactionKindBadge({required this.kind});

  final FactionKind kind;

  @override
  Widget build(BuildContext context) {
    final ({String label, Color? background, Color? border, Color foreground})
    spec = switch (kind) {
      FactionKind.greatPower => (
        label: 'GP',
        background: EditorialMonoclePalette.accentDim,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.minor => (
        label: 'Minor',
        background: EditorialMonoclePalette.muted,
        border: null,
        foreground: EditorialMonoclePalette.bgDeep,
      ),
      FactionKind.tribe => (
        label: 'Tribe',
        background: null,
        border: EditorialMonoclePalette.muted,
        foreground: EditorialMonoclePalette.muted,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CtSpacing.s,
        vertical: CtSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: spec.background,
        border: spec.border == null
            ? null
            : Border.all(color: spec.border!, width: 1),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.foreground,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 10,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Relation state chip rendered before the one-word relation label per
/// SPEC/ui/diplomacy-panel.md § Relation state badge. War rows show a
/// `WAR` chip with a translucent warm-red background and `--danger`
/// foreground; peace rows show a `PEACE` chip with a translucent
/// cool-green background and `--success` foreground. Mirrors
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// `.f-relation .state`.
class _RelationStateBadge extends StatelessWidget {
  const _RelationStateBadge({required this.atWar});

  final bool atWar;

  @override
  Widget build(BuildContext context) {
    final ({Color background, Color foreground, String label}) spec = atWar
        ? (
            background: _kWarBadgeBackground,
            foreground: EditorialMonoclePalette.danger,
            label: 'WAR',
          )
        : (
            background: _kPeaceBadgeBackground,
            foreground: EditorialMonoclePalette.success,
            label: 'PEACE',
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        spec.label,
        style: TextStyle(
          color: spec.foreground,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 9,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Translucent overlay used as the formal-alliance badge background, derived
/// from the accent hue at lightness 0.40, chroma 0.06, hue 85, alpha 0.30.
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625) cites
/// the mockup-aligned token `oklch(40% 0.06 85 / 0.30)`; this constant
/// computes the same OKLCH sRGB approximation through [oklchToColor].
final Color _kAllianceBadgeBackground = oklchToColor(
  kDiplomacyAllianceBadgeBgToken,
).withValues(alpha: kDiplomacyAllianceBadgeAlpha);

/// Formal-alliance (treaty) chip rendered on the relation line after the
/// WAR/PEACE relation state badge per SPEC/ui/diplomacy-panel.md § Formal
/// alliance indicator (Refs #3625). Rendered only when the row's
/// `DiplomacyRelation.formalAlliance` is `true`, so a merely-Friendly
/// (informal `RelationLevel.allied`) relation never shows it. The chip carries
/// the [kDiplomacyAllianceBadgeLabel] text in `--accent` over a translucent
/// accent overlay, mirroring the relation state badge chrome so it reads as a
/// distinct gold treaty marker rather than reusing the relation-band word.
class _AllianceBadge extends StatelessWidget {
  const _AllianceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _kAllianceBadgeBackground,
        borderRadius: BorderRadius.circular(1),
      ),
      child: Text(
        kDiplomacyAllianceBadgeLabel,
        style: TextStyle(
          color: EditorialMonoclePalette.accent,
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier'],
          fontSize: 9,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Hover-aware faction row chrome per SPEC/ui/diplomacy-panel.md
/// § Per-faction row → Row chrome. Paints a vertical
/// `linear-gradient(180deg, --bg-deep, --surface)` background, a 1 px
/// `--border` outline, and animates the outline to `--accent-dim` while
/// pointer-hovered. The 4 px outer bottom margin matches `.faction-row`
/// in [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html).
class _DiplomacyRowChrome extends StatefulWidget {
  const _DiplomacyRowChrome({required this.child});

  final Widget child;

  /// Outer bottom gap between consecutive faction rows.
  static const double rowGap = 4;

  /// Token-resolved 180° gradient used by the row body.
  static LinearGradient get rowGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );

  @override
  State<_DiplomacyRowChrome> createState() => _DiplomacyRowChromeState();
}

class _DiplomacyRowChromeState extends State<_DiplomacyRowChrome> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _hovered
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    return Padding(
      padding: const EdgeInsets.only(bottom: _DiplomacyRowChrome.rowGap),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            gradient: _DiplomacyRowChrome.rowGradient,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
