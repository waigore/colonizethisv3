/// Compile-time flag for S9b candidate level-1 town icon preview (Refs #3870).
///
/// Pass `--dart-define=CT_NEW_TOWN_ICONS=true` to load candidate level-1 PNGs
/// on the map while production defaults remain the S9a-reverted hamlets.
///
/// **SPEC:** `SPEC/ui/town-port-icons.md` § `CT_NEW_TOWN_ICONS` preview gate.
const bool kCtNewTownIconsEnabled = bool.fromEnvironment(
  'CT_NEW_TOWN_ICONS',
  defaultValue: false,
);
