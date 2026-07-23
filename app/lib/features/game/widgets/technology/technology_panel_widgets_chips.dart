// Researched-tech chip and section heading widgets for the technology panel.
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/themes.dart';
import 'tech_ui_helpers.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'technology_panel_widgets_constants.dart';

/// Read-only researched-tech chip rendered in the Slots tab grid.
///
/// SPEC/ui/technology-panel.md § Layout / wireframe + mockup
/// `.tech-chip`: vertical `--bg-deep` → `--surface` gradient, 1 px
/// `--border` outline, 14 px tech-category icon, body-font tech name in
/// `--fg`. Refs #2864 S2.
class ResearchedTechChip extends StatelessWidget {
  const ResearchedTechChip({super.key, required this.techId});

  final String techId;

  @visibleForTesting
  static const double iconSize = 14;

  @override
  Widget build(BuildContext context) {
    final tech = techById(techId);
    final iconPath = techCategoryIconAssetPath(tech?.category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: technologyDarkSurfaceGradient(),
        border: Border.all(
          color: EditorialMonoclePalette.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) ...[
              StrictAssetIcon(assetPath: iconPath, width: iconSize, height: iconSize),
              const SizedBox(width: 5),
            ],
            Text(
              techDisplayName(techId),
              style: TextStyle(
                color: EditorialMonoclePalette.fg,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mockup-faithful section heading for the Slots-tab canonical sections
/// (`Researched Techs`, `Research Slots`).
///
/// Mirrors the mockup `.researched-heading` / `.slots-heading` style
/// (`SPEC/ui/mockups/GAME40001-technology-panel.html`): the Cinzel display
/// family at [fontSize] / [fontWeight], `--accent` colour, `0.04em`
/// letter-spacing, and the literal heading text (NOT the small-caps
/// upper-cased treatment used by `CtSectionLabel`). Per the issue
/// source-of-truth precedence the mockup is canonical for this purely visual
/// heading detail, so these two headings diverge from the app-wide
/// `CtSectionLabel` chrome. SPEC/ui/technology-panel.md § Slots tab — section
/// ordering. Refs #3510.
class TechSectionHeading extends StatelessWidget {
  const TechSectionHeading(this.text, {super.key});

  final String text;

  /// Heading font size in logical px (mockup `.researched-heading`
  /// `font-size: clamp(11px,1.5vw,13px)` upper bound).
  @visibleForTesting
  static const double fontSize = 13;

  /// Heading weight (mockup `font-weight:600`).
  @visibleForTesting
  static const FontWeight fontWeight = FontWeight.w600;

  /// Letter spacing in logical px (`0.04em` of [fontSize]).
  @visibleForTesting
  static const double letterSpacing = fontSize * 0.04;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: editorialMonocleDisplayFontFamily,
        color: EditorialMonoclePalette.accent,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
