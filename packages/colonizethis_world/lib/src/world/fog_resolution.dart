/// End-of-turn fog-of-war resolution for player visibility.
///
/// Behaviour is split by concern across standalone libraries; all top-level
/// entry points remain importable from `fog_resolution.dart`:
///
/// - `fog_resolution_explorer_spy_decay.dart` — Explorer/Spy land fog decay and
///   Spy reveal-timer maintenance ([applySpyRevealTimerDecay], [applyFogDecay],
///   [clearSpyRevealTimersForProvince],
///   [clearSpyRevealTimersForProvinceOwnershipTransfer]).
/// - `fog_resolution_province_ownership.dart` — immediate visibility on province
///   ownership transfer ([applyProvinceOwnershipChangeVisibility]).
/// - `fog_resolution_coastal_sea_zone.dart` — coastal sea-zone full visibility
///   ([applyCoastalSeaZoneFullVisibility],
///   [applyCoastalSeaZoneFullVisibilityForProvinceTargets]).
/// - `fog_resolution_distant_sea_zone.dart` — distant sea-zone fog revert
///   ([applyDistantSeaZoneFogRevert]).
///
/// SPEC source of truth: SPEC/program/fog-and-exploration-resolution.md.
library;

export 'fog_resolution_coastal_sea_zone.dart';
export 'fog_resolution_distant_sea_zone.dart';
export 'fog_resolution_explorer_spy_decay.dart';
export 'fog_resolution_province_ownership.dart';
