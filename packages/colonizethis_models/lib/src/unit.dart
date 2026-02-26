import 'current_work.dart';

/// Military or civilian unit. SPEC/game/world-model.
/// Phase 3: medals (0–4) for military experience per SPEC/game/military-units.md.
class Unit {
  const Unit({
    required this.id,
    required this.type,
    required this.ownerId,
    required this.provinceId,
    this.status = UnitStatus.idle,
    this.movementPoints = 0,
    this.medals = 0,
    this.tileKey,
    this.currentWork,
  });

  final String id;
  final String type;
  final String ownerId;
  final String provinceId;
  final UnitStatus status;
  final int movementPoints;

  /// Experience medals (0–4); multiplies FPN/FPM in combat. SPEC/game/military-units.md.
  final int medals;

  /// Tile-level position for civilians only (format regionId|provinceId|x|y). Null for military/naval.
  final String? tileKey;

  /// Province id parsed from [tileKey]; null if tileKey is null or invalid format.
  /// Use [Unit.provinceIdFromTileKey] for static parsing.
  String? get provinceIdFromTile => provinceIdFromTileKey(tileKey);

  /// Region id parsed from [tileKey]; null if tileKey is null or invalid format.
  String? get regionIdFromTile => regionIdFromTileKey(tileKey);

  /// Parses province id from a tile key (format regionId|localId|x|y).
  /// Returns full id (regionId|localId) when key has 4 parts; otherwise local id (parts[1]) for legacy. Null if invalid.
  static String? provinceIdFromTileKey(String? tileKey) {
    if (tileKey == null || tileKey.isEmpty) return null;
    final parts = tileKey.split('|');
    if (parts.length >= 4) {
      return '${parts[0]}|${parts[1]}';
    }
    return parts.length >= 2 ? parts[1] : null;
  }

  /// Parses region id from a tile key (format regionId|localId|x|y). Returns null if invalid.
  static String? regionIdFromTileKey(String? tileKey) {
    if (tileKey == null || tileKey.isEmpty) return null;
    final parts = tileKey.split('|');
    return parts.isNotEmpty ? parts[0] : null;
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

  /// Effective province id for this unit: from tileKey for civilians, from provinceId for military/naval.
  String get locationProvinceId =>
      (tileKey != null && tileKey!.isNotEmpty)
          ? (provinceIdFromTileKey(tileKey) ?? provinceId)
          : provinceId;

  /// Multi-turn work in progress. SPEC/program/development-resolution.md.
  final CurrentWork? currentWork;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'ownerId': ownerId,
        'provinceId': provinceId,
        'status': status.name,
        'movementPoints': movementPoints,
        if (medals != 0) 'medals': medals,
        if (tileKey != null && tileKey!.isNotEmpty) 'tileKey': tileKey,
        if (currentWork != null) 'currentWork': currentWork!.toJson(),
      };

  static Unit fromJson(Map<String, dynamic> json) {
    final cw = json['currentWork'];
    return Unit(
      id: json['id'] as String,
      type: json['type'] as String,
      ownerId: json['ownerId'] as String,
      provinceId: json['provinceId'] as String,
      status: _statusFromJson(json['status'] as String?),
      movementPoints: (json['movementPoints'] as int?) ?? 0,
      medals: (json['medals'] as int?) ?? 0,
      tileKey: json['tileKey'] as String?,
      currentWork: cw is Map<String, dynamic>
          ? CurrentWork.fromJson(cw)
          : cw is Map
              ? CurrentWork.fromJson(Map<String, dynamic>.from(cw))
              : null,
    );
  }

  /// [clearCurrentWork] when true sets [currentWork] to null (use when cancelling work).
  /// Otherwise [currentWork] is used if provided, else kept.
  Unit copyWith({
    String? id,
    String? type,
    String? ownerId,
    String? provinceId,
    UnitStatus? status,
    int? movementPoints,
    int? medals,
    String? tileKey,
    CurrentWork? currentWork,
    bool clearCurrentWork = false,
  }) {
    return Unit(
      id: id ?? this.id,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      provinceId: provinceId ?? this.provinceId,
      status: status ?? this.status,
      movementPoints: movementPoints ?? this.movementPoints,
      medals: medals ?? this.medals,
      tileKey: tileKey ?? this.tileKey,
      currentWork:
          clearCurrentWork ? null : (currentWork ?? this.currentWork),
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
          provinceId == other.provinceId &&
          status == other.status &&
          movementPoints == other.movementPoints &&
          medals == other.medals &&
          tileKey == other.tileKey &&
          currentWork == other.currentWork;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        ownerId,
        provinceId,
        status,
        movementPoints,
        medals,
        tileKey,
        currentWork,
      );
}

/// Minimal status for Phase 2 work and movement.
enum UnitStatus {
  idle,
  working,
  done,
}

UnitStatus _statusFromJson(String? value) {
  if (value == null) return UnitStatus.idle;
  return UnitStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => UnitStatus.idle,
  );
}
