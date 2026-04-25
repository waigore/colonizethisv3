/// Helpers for prefixed province ids: "regionId|localId".
/// All game-state province ids must be prefixed so a province cannot be
/// located in the wrong region. SPEC/game/world-model.
///
/// Tile keys remain 4-part: "regionId|localId|x|y" (second part is local id).
class ProvinceId {
  ProvinceId._();

  /// Returns the region id (part before the first "|").
  /// For legacy unprefixed ids, returns the input unchanged.
  static String regionIdFrom(String fullProvinceId) {
    final i = fullProvinceId.indexOf('|');
    if (i < 0) return fullProvinceId;
    return fullProvinceId.substring(0, i);
  }

  /// Returns the local id (part after the first "|").
  /// For legacy unprefixed ids, returns the input unchanged.
  static String localIdFrom(String fullProvinceId) {
    final i = fullProvinceId.indexOf('|');
    if (i < 0) return fullProvinceId;
    return fullProvinceId.substring(i + 1);
  }

  /// Builds full province id from region and local id.
  static String full(String regionId, String localId) => '$regionId|$localId';

  /// True if [id] looks prefixed (contains "|").
  static bool isPrefixed(String id) => id.contains('|');
}
