/// Always-rendered slot count on the Slots tab.
///
/// SPEC/ui/technology-panel.md § Slot behaviour: "The Slots tab always
/// renders exactly four slot cards in slot-index order regardless of
/// `player.researchSlots`." Refs #2864 S0/S3.
const int kTechnologyResearchSlotCount = 4;

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
