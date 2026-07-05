/// Compile-time flag for previewing S9b candidate level-1 town map icons.
///
/// Pass `--dart-define=CT_NEW_TOWN_ICONS=true` in local/ctdev runs to load
/// candidate level-1 PNGs from separate asset paths while production defaults
/// stay on the S9a-reverted hamlets. **SPEC:** `SPEC/ui/town-port-icons.md`.
const bool kCtNewTownIconsEnabled = bool.fromEnvironment(
  'CT_NEW_TOWN_ICONS',
  defaultValue: false,
);
