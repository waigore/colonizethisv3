import 'model_validation_exception.dart';

/// Helpers for prefixed province ids: "regionId|localId".
/// All game-state province ids must be prefixed so a province cannot be
/// located in the wrong region. SPEC/game/world-model.
///
/// Tile keys remain 4-part: "regionId|localId|x|y" (second part is local id).
class ProvinceId {
  ProvinceId._();

  /// Returns the region id (part before the first "|").
  /// Throws [StateError] if [fullProvinceId] does not contain "|".
  static String regionIdFrom(String fullProvinceId) {
    final i = fullProvinceId.indexOf('|');
    if (i < 0) {
      throw StateError(
        'Province id must be prefixed with regionId (regionId|localId): "$fullProvinceId"',
      );
    }
    return fullProvinceId.substring(0, i);
  }

  /// Returns the local id (part after the first "|").
  /// Throws [StateError] if [fullProvinceId] does not contain "|".
  static String localIdFrom(String fullProvinceId) {
    final i = fullProvinceId.indexOf('|');
    if (i < 0) {
      throw StateError(
        'Province id must be prefixed with regionId (regionId|localId): "$fullProvinceId"',
      );
    }
    return fullProvinceId.substring(i + 1);
  }

  /// Builds full province id from region and local id.
  static String full(String regionId, String localId) => '$regionId|$localId';

  /// True if [id] looks prefixed (contains "|").
  static bool isPrefixed(String id) => id.contains('|');

  /// Returns [provinceId] when it is prefixed; otherwise throws [ModelValidationException].
  static String requirePrefixed(
    String provinceId, {
    String fieldName = 'provinceId',
  }) {
    if (isPrefixed(provinceId)) return provinceId;
    throw ModelValidationException(
      '$fieldName must be prefixed (regionId|localId): "$provinceId"',
    );
  }

  /// Returns null when [provinceId] is null; otherwise enforces prefixed format.
  static String? requirePrefixedOrNull(
    String? provinceId, {
    String fieldName = 'provinceId',
  }) {
    if (provinceId == null) return null;
    return requirePrefixed(provinceId, fieldName: fieldName);
  }

  /// Local province id segment when normalizing persisted or capital data that
  /// may still use bare local ids. Prefixed values use [localIdFrom]; bare
  /// values are returned unchanged. **Save/load and legacy topology alignment
  /// only** — runtime game-state paths must hold canonical prefixed ids.
  static String localSegmentFromStoredGameState(String storedProvinceId) {
    if (isPrefixed(storedProvinceId)) {
      return localIdFrom(storedProvinceId);
    }
    return storedProvinceId;
  }
}
