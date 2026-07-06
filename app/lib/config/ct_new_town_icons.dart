/// Compile-time flag for previewing S9b level-1 town icon candidates on the map.
///
/// Pass `--dart-define=CT_NEW_TOWN_ICONS=true` when running the app or ctdev
/// for on-map visual verification before promoting candidates to production paths.
///
/// Default **false** — production builds use S9a-reverted level-1 PNGs.
/// **SPEC:** `SPEC/ui/town-port-icons.md` § S9b preview flag (Refs #3870).
const bool kCtNewTownIconsEnabled = bool.fromEnvironment(
  'CT_NEW_TOWN_ICONS',
  defaultValue: false,
);
