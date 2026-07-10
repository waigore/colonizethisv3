// Relation-state and formal-alliance badge chrome for DiplomacyPanel.
// SPEC/ui/diplomacy-panel.md § Relation state badge and § Formal alliance
// indicator (Refs #3625).

part of 'diplomacy_panel.dart';

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
///
/// Public so the diplomacy **detail** screen (GAME30002) can surface the same
/// treaty marker in its CURRENT RELATION card per
/// SPEC/ui/diplomacy-detail-screen.md § Formal alliance indicator (Refs #3625),
/// reusing one badge widget across both diplomacy surfaces.
class DiplomacyAllianceBadge extends StatelessWidget {
  const DiplomacyAllianceBadge({super.key});

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
