// Diplomacy panel layout constants. SPEC/ui/diplomacy-panel.md.

part of 'diplomacy_panel.dart';

/// Maximum viewport width (Flutter dp) at which the diplomacy faction-row
/// body switches to its narrow stacked variant (info column above the
/// action-button cluster, left-aligned).
///
/// SPEC/ui/diplomacy-panel.md § Responsive layout — mirrors the
/// `@media (max-width: 500px)` cutoff in
/// [mockups/GAME30001-diplomacy-panel.html](../../../../../SPEC/ui/mockups/GAME30001-diplomacy-panel.html)
/// and the `≤ 500 dp` Diplomacy entry in
/// [mobile-adaptation.md](../../../../../SPEC/ui/mobile-adaptation.md) § 4.
///
/// Exposed at library scope so widget tests can pin the boundary
/// deterministically without re-deriving the constant.
const double kDiplomacyRowNarrowMaxWidth = 500.0;

/// Key prefix attached to a faction-row body widget so tests can resolve
/// the live Row (wide) vs Column (narrow) layout selection driven by
/// [kDiplomacyRowNarrowMaxWidth].
///
/// Each row uses `ValueKey('${kDiplomacyRowBodyKeyPrefix}<factionId>')`.
/// SPEC/ui/diplomacy-panel.md § Responsive layout cites this key so
/// widget tests can pin both variants without touching private types.
const String kDiplomacyRowBodyKeyPrefix = 'diplomacyRowBody:';

/// Spacing and run-spacing (Flutter dp) between diplomacy action buttons in
/// the trailing cluster `Wrap`. Mirrors the mockup `.f-actions { gap: 4px }`.
/// SPEC/ui/diplomacy-panel.md § Action button styling (Refs #3621).
const double kDiplomacyActionWrapSpacing = 4.0;

/// Minimum height (Flutter dp) of a diplomacy **compact** action button —
/// tighter than the default [CtNinePatchButton.minHeight] (48 dp) so the
/// action cluster matches the compact mockup density
/// (`.f-actions button`). SPEC/ui/diplomacy-panel.md § Action button
/// styling (Refs #3621).
const double kDiplomacyActionButtonMinHeight = 24.0;

/// Inner padding for a diplomacy **compact** action button — tighter than
/// [CtNinePatchButton.defaultPadding] (16 × 12 dp) to match the mockup
/// `.f-actions button { padding: 3px 7px }`. SPEC/ui/diplomacy-panel.md
/// § Action button styling (Refs #3621).
const EdgeInsets kDiplomacyActionButtonPadding = EdgeInsets.symmetric(
  horizontal: 7,
  vertical: 3,
);

/// Label font size (Flutter sp) for a diplomacy **compact** action button.
/// The label resolves to the editorial-monocle **display** font stack
/// ([editorialMonocleDisplayFontFamily], Cinzel) at this compact size —
/// materially smaller than the ~12 dp M3 `bodySmall` slot — so the mockup
/// `.f-actions button { font-size: 8px; font-family: var(--font-display) }`
/// density is honoured and more buttons pack onto each trailing-cluster run.
/// Pinned at library scope so widget tests assert the size from one source.
/// SPEC/ui/diplomacy-panel.md § Action button styling (Refs #3621).
const double kDiplomacyActionButtonFontSize = 10.0;

/// Label for the formal-alliance (treaty) badge rendered on the relation line
/// when `DiplomacyRelation.formalAlliance` is `true`. Exposed at library scope
/// so widget tests pin the badge text from a single source.
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const String kDiplomacyAllianceBadgeLabel = 'ALLIANCE';

/// OKLCH token for the translucent accent overlay behind the formal-alliance
/// badge, mirroring the WAR/PEACE relation-state badge derivation but on the
/// accent hue (`oklch(40% 0.06 85)`), tinted at [kDiplomacyAllianceBadgeAlpha].
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const OklchToken kDiplomacyAllianceBadgeBgToken = OklchToken(0.40, 0.06, 85);

/// Alpha applied on top of [kDiplomacyAllianceBadgeBgToken] for the
/// formal-alliance badge background overlay.
/// SPEC/ui/diplomacy-panel.md § Formal alliance indicator (Refs #3625).
const double kDiplomacyAllianceBadgeAlpha = 0.30;

/// Resolves the editorial-monocle color for the one-word relation label
/// derived from the hidden relation [score], per SPEC/ui/diplomacy-panel.md
/// § Relation word styling and SPEC/ui/components/relation-meter.md § Gradient.
///
/// The word color now matches its position on the 10-step relation meter: the
/// score maps to a 1-based meter step via [relationScoreToMeterStep] and that
/// step resolves through [relationMeterStepColor], the red → green OKLCH ladder
/// anchored on the canonical `--danger` (step 1) and `--success` (step 10)
/// tokens (Refs #3753 R13.3). This supersedes the legacy 4-band word-color map
/// so the inline word and the meter indicator always read in the same hue.
Color diplomacyRelationWordColor(num score) =>
    relationMeterStepColor(relationScoreToMeterStep(score));
