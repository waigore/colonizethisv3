/// Compile-time flag for S9b candidate level-1 town icon preview (Refs #3870).
///
/// Pass `--dart-define=CT_NEW_TOWN_ICONS=true` when running the app or ctdev to
/// load candidate level-1 PNGs on the map. Default **false** keeps S9a-reverted
/// production `ui_icon_com_town_{style}_1_64.png` assets.
///
/// **SPEC:** `SPEC/ui/town-port-icons.md` § S9b preview gate.
const bool kCtNewTownIconsEnabled = bool.fromEnvironment(
  'CT_NEW_TOWN_ICONS',
  defaultValue: false,
);
