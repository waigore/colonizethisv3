/// Compile-time flag for loading retired S9a level-1 hamlet town icons.
///
/// Pass `--dart-define=CT_LEGACY_TOWN_ICONS=true` when running the app or ctdev
/// to roll back to pre-promotion level-1 art for debug comparison.
///
/// Default **false** — production builds use PO-approved promoted level-1 PNGs.
/// **SPEC:** `SPEC/ui/town-port-icons.md` § S9c legacy fallback (Refs #3870).
const bool kCtLegacyTownIconsEnabled = bool.fromEnvironment(
  'CT_LEGACY_TOWN_ICONS',
  defaultValue: false,
);
