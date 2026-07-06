/// Long-press repeat timing for production allocation **+** / **−** steppers.
/// SPEC/ui/production-panel.md § Allocation row controls (named constants).
const kProductionAllocationRepeatInitialDelay = Duration(milliseconds: 500);

/// Interval between repeat ticks while **+** or **−** is held after the initial delay.
const kProductionAllocationRepeatInterval = Duration(milliseconds: 125);
