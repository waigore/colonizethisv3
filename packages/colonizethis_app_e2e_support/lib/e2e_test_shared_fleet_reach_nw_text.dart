/// True when [data] reads like the naval-panel location row for a fleet in
/// the New World (for example `New World — Outer Sea`).
///
/// `naval_tree_builder.dart` joins region and location with an **em dash**
/// (`—`), but earlier CI dumps and Material text scaling can normalize the
/// glyph to an **en dash** (`–`) or a plain **hyphen-minus** (`-`). The
/// helper accepts all three so fleet-reach detection
/// ([e2eNavalPanelShowsNonHomeFleetInNewWorld]) is not coupled
/// to one specific Unicode glyph.
///
/// Lives in a dedicated file (alongside the snapshot-driven fleet-reach
/// predicates that consume it) so the parent `e2e_test_shared.dart` stays
/// within the repo-lint `dart_file_non_comment_line_size` budget
/// (`SPEC/program/repo-lint.md`, ≤ 1000 non-comment lines). The barrel
/// re-exports this entrypoint so consumers depend on `e2e_test_shared.dart`
/// (or the AC1 `e2e_helpers.dart` barrel) only. Refs GitHub #2336 AC1 /
/// AC2 / Bottleneck 6.
///
/// Contract (Refs GitHub #2336):
/// - `null` and empty string -> `false` (nothing to inspect).
/// - String must begin with `"New World"` after trimming leading whitespace
///   (`trimLeft`); trailing whitespace is preserved so callers can spot
///   suspicious tail content in their own assertions.
/// - The character(s) immediately after `"New World"` must reduce, via a
///   second `trimLeft`, to one of `'—'`, `'–'`, or `'-'`. Anything else
///   (alphanumerics, a colon, or no separator at all) -> `false`.
bool e2eTextLooksLikeNewWorldLocationLine(String? data) {
  if (data == null) {
    return false;
  }
  final trimmed = data.trimLeft();
  const prefix = 'New World';
  if (!trimmed.startsWith(prefix)) {
    return false;
  }
  final after = trimmed.substring(prefix.length);
  if (after.isEmpty) {
    return false;
  }
  final rest = after.trimLeft();
  return rest.startsWith('—') || rest.startsWith('–') || rest.startsWith('-');
}
