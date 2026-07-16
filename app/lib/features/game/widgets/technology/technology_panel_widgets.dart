library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/themes.dart';
import 'research_slot_preview.dart';
import 'tech_ui_helpers.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_progress_bar.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'research_slot_turn_preview_view.dart';
import 'technology_slot_funding_toggles.dart';

part 'technology_panel_widgets_slot_cards.dart';
part 'technology_panel_widgets_slot_cards_header.dart';
part 'technology_panel_widgets_slot_cards_body.dart';
part 'technology_panel_widgets_slot_cards_locked.dart';

/// Opacity applied to the locked fourth-slot card body when
/// `player.researchSlots < 4`.
///
/// SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4
/// (University). Refs #2864 S0/S3.
const double kTechnologyLockedSlotOpacity = 0.45;

/// Viewport width (logical px) below which the compact slot action controls
/// (`CtActionTextButton` / `CtDangerTextButton`) guarantee a
/// [kMinTouchTargetSize] (44 dp) tap target in both dimensions.
///
/// Mirrors the in-game shell narrow breakpoint (`< 600 dp`) in
/// `SPEC/ui/mobile-adaptation.md` § 4. At or above this width the slot action
/// controls render at their compact mockup size
/// (`SPEC/ui/mockups/GAME40001-technology-panel.html` `.slot-actions button`);
/// below it the controls expand so they satisfy the mobile minimum
/// touch-target rule (§ 1). SPEC/ui/technology-panel.md § Slot behaviour.
/// Refs #3510.
const double kTechnologySlotActionTouchTargetBreakpoint = 600;

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
        gradient: _technologyDarkSurfaceGradient(),
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

// Vertical `--bg-deep` → `--surface` gradient shared by the researched
// tech chip body and the slot card chrome. Mirrors the mockup
// `linear-gradient(180deg,var(--bg-deep),var(--surface))` and is the
// single source so future palette tweaks stay aligned across both
// surfaces (SPEC/ui/technology-panel.md § Layout / wireframe + mockup
// `.tech-chip` and `.slot-card`). Refs #2864 S2/S3.
LinearGradient _technologyDarkSurfaceGradient() {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );
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
