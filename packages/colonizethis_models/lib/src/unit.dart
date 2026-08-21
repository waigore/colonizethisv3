import 'current_work.dart';
import 'tile_key_coordinates.dart';
import 'unit_json.dart';

export 'unit_json.dart' show UnitStatus;

/// Normalizes persisted province id: tile-derived wins when [tileKey] is set.
String storedProvinceIdForTileAndLocation(
  String? tileKey,
  String locationHint,
) {
  if (tileKey != null && tileKey.isNotEmpty) {
    final derived = Unit.provinceIdFromTileKey(tileKey);
    if (derived != null) return derived;
  }
  return locationHint;
}

/// Military or civilian unit. SPEC/game/world-model.
/// Phase 3: medals (0–4) for military experience per SPEC/game/military-units.md.
///
/// Canonical placement is [locationProvinceId] (tile-first). JSON key `provinceId`
/// always reads/writes that canonical value.
class Unit {
  Unit({
    required this.id,
    required this.type,
    required this.ownerId,
    required String locationProvinceId,
    this.status = UnitStatus.idle,
    this.medals = 0,
    this.tileKey,
    this.originTileKey,
    this.assignedTileKey,
    this.currentWork,
  }) : _storedProvinceId = storedProvinceIdForTileAndLocation(
         tileKey,
         locationProvinceId,
       );

  final String id;
  final String type;
  final String ownerId;
  final String _storedProvinceId;
  final UnitStatus status;

  /// Experience medals (0–4); multiplies FPN/FPM in combat. SPEC/game/military-units.md.
  final int medals;

  /// Tile-level position for civilians only (format regionId|provinceId|x|y). Null for military/naval.
  final String? tileKey;

  /// Original tile before current assignment started; null when idle or after work resolves.
  final String? originTileKey;

  /// Assigned target tile for current in-progress work; null when idle or after work resolves.
  final String? assignedTileKey;

  /// Province id parsed from [tileKey]; null if tileKey is null or invalid format.
  /// Use [Unit.provinceIdFromTileKey] for static parsing.
  String? get provinceIdFromTile => provinceIdFromTileKey(tileKey);

  /// Region id parsed from [tileKey]; null if tileKey is null or invalid format.
  String? get regionIdFromTile => regionIdFromTileKey(tileKey);

  /// Parses province id from a tile key (format regionId|localId|x|y).
  /// Returns full id `regionId|localId` when [parseTileKeyCoordinates] accepts
  /// the key; otherwise null (short, extra-segment, and non-numeric → null).
  /// SPEC/game/world-model-identity.md; Refs #3427, #4571.
  static String? provinceIdFromTileKey(String? tileKey) {
    if (tileKey == null || tileKey.isEmpty) return null;
    final parsed = parseTileKeyCoordinates(tileKey);
    if (parsed == null) return null;
    return '${parsed.regionId}|${parsed.provinceLocalId}';
  }

  /// Parses region id from a tile key (format regionId|localId|x|y).
  /// Returns null when [parseTileKeyCoordinates] rejects the key.
  static String? regionIdFromTileKey(String? tileKey) {
    if (tileKey == null || tileKey.isEmpty) return null;
    return parseTileKeyCoordinates(tileKey)?.regionId;
  }

  /// Region id from [tileKey]. Throws [StateError] if tileKey is null, empty, or invalid.
  static String requireRegionIdFromTileKey(String? tileKey) {
    final r = regionIdFromTileKey(tileKey);
    if (r == null || r.isEmpty) {
      throw StateError(
        'Cannot determine region from tile key: ${tileKey == null ? "null" : '"$tileKey"'}',
      );
    }
    return r;
  }

  /// Canonical province id: derived from [tileKey] when set, else stored placement (military / no tile).
  String get locationProvinceId => (tileKey != null && tileKey!.isNotEmpty)
      ? (provinceIdFromTileKey(tileKey) ?? _storedProvinceId)
      : _storedProvinceId;

  /// Multi-turn work in progress. SPEC/program/development-resolution.md.
  final CurrentWork? currentWork;

  Map<String, dynamic> toJson() => encodeUnitToJson(this);

  static Unit fromJson(Map<String, dynamic> json) => decodeUnitFromJson(json);

  /// [clearCurrentWork] when true sets [currentWork] to null (use when cancelling work).
  /// Otherwise [currentWork] is used if provided, else kept.
  /// [clearOriginTileKey] / [clearAssignedTileKey] clear their tracking fields.
  Unit copyWith({
    String? id,
    String? type,
    String? ownerId,
    String? locationProvinceId,
    UnitStatus? status,
    int? medals,
    String? tileKey,
    String? originTileKey,
    String? assignedTileKey,
    CurrentWork? currentWork,
    bool clearCurrentWork = false,
    bool clearOriginTileKey = false,
    bool clearAssignedTileKey = false,
  }) {
    final nextTile = tileKey ?? this.tileKey;
    final canonicalHint =
        locationProvinceId ??
        ((nextTile != null && nextTile.isNotEmpty)
            ? (Unit.provinceIdFromTileKey(nextTile) ?? _storedProvinceId)
            : _storedProvinceId);
    return Unit(
      id: id ?? this.id,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      locationProvinceId: canonicalHint,
      status: status ?? this.status,
      medals: medals ?? this.medals,
      tileKey: nextTile,
      originTileKey: clearOriginTileKey
          ? null
          : (originTileKey ?? this.originTileKey),
      assignedTileKey: clearAssignedTileKey
          ? null
          : (assignedTileKey ?? this.assignedTileKey),
      currentWork: clearCurrentWork ? null : (currentWork ?? this.currentWork),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Unit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          ownerId == other.ownerId &&
          _storedProvinceId == other._storedProvinceId &&
          status == other.status &&
          medals == other.medals &&
          tileKey == other.tileKey &&
          originTileKey == other.originTileKey &&
          assignedTileKey == other.assignedTileKey &&
          currentWork == other.currentWork;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    ownerId,
    _storedProvinceId,
    status,
    medals,
    tileKey,
    originTileKey,
    assignedTileKey,
    currentWork,
  );
}
