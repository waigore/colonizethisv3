/// Layout and animation constants for [CtDropdown].
library;

/// Animation timing for the trigger chevron rotation between
/// closed (chevron-down) and open (chevron-up) states per
/// SPEC/ui/pixel-art-ui-catalog.md (CtDropdown / Refs #2859 R5d).
const Duration kCtDropdownChevronAnimationDuration = Duration(milliseconds: 120);

/// Final turn fraction the chevron rotates through when the picker opens.
/// `0.5` turns equals 180°, taking the glyph from chevron-down to chevron-up.
const double kCtDropdownChevronOpenTurns = 0.5;
const double kCtDropdownChevronClosedTurns = 0.0;

/// Width of the picker row's accent left-edge indicator. Pinned to 1 dp so
/// selected and unselected rows occupy identical horizontal space — the
/// unselected variant paints a fully transparent border at the same width,
/// keeping the layout stable across selection changes (Refs #2859 R5c).
const double kCtDropdownPickerSelectedLeftEdgeWidth = 1.0;

/// Compact trigger visual min-height (DLG10001 mockup `.dropdown-wrapper
/// select`). Layout contribution stays at this height; hit testing expands
/// to [kMinTouchTargetSize] via an invisible OverflowBox (Refs #4062).
const double kCtDropdownTriggerVisualMinHeight = 34.0;

/// Compact picker-row visual min-height (Refs #4062).
const double kCtDropdownPickerRowVisualMinHeight = 32.0;

/// Trigger / picker label font size (mockup `font-size:12px`).
const double kCtDropdownLabelFontSize = 12.0;

/// Trigger chevron glyph size (mockup `.chevron` `font-size:10px`).
const double kCtDropdownChevronSize = 10.0;
