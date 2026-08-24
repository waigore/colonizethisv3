/// Compact selection-prompt banner tokens for MAP10001.
///
/// SPEC: `SPEC/ui/map-widget.md` § Dark-theme selection prompt overlay tokens.
library;

/// Compact minimum tap-target height applied to the selection-prompt
/// banner's `cancel` [CtNinePatchButton]. Pinned to keep the inline
/// affordance vertically proportional to the surrounding banner row
/// (banner padding is 8 logical px vertical) without inflating the prompt
/// to the catalog default 48 dp button.
const double kMapSelectionPromptCancelMinHeight = 34;

/// Canonical alpha applied to [EditorialMonoclePalette.bgDeep] for the
/// work-target selection prompt overlay banner background. Pinned at
/// `0.85` so the banner reads as a framed dark surface against the lit
/// map while still allowing terrain to glimmer through.
const double kMapSelectionPromptBackgroundAlpha = 0.85;
