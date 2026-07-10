const String _suffixTileMapByRegion = '_tileMapByRegion';
const String _suffixTopologyByRegion = '_topologyByRegion';
const String _suffixCombinedTopology = '_combinedTopology';
const String _suffixWarpLinks = '_warpLinks';

const List<String> _mapDataKeySuffixes = <String>[
  _suffixTileMapByRegion,
  _suffixTopologyByRegion,
  _suffixCombinedTopology,
  _suffixWarpLinks,
];

/// Derives a Hive `gameId` from a user-typed save name.
///
/// Trims, replaces runs of whitespace with `_`, strips characters that would
/// make the key end with a map-data suffix, and returns null when the result
/// is empty. SPEC/program/save-load.md § Hive gameId vs display name.
String? sanitizeGameId(String typedName) {
  var result = typedName.trim().replaceAll(RegExp(r'\s+'), '_');
  if (result.isEmpty) {
    return null;
  }
  for (final suffix in _mapDataKeySuffixes) {
    while (result.endsWith(suffix)) {
      result = result.substring(0, result.length - suffix.length);
    }
  }
  result = result.replaceAll(RegExp(r'_+'), '_');
  if (result.startsWith('_')) {
    result = result.substring(1);
  }
  if (result.endsWith('_')) {
    result = result.substring(0, result.length - 1);
  }
  return result.isEmpty ? null : result;
}
