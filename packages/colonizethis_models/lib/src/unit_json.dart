/// [Unit] JSON encode/decode and status helpers (Refs #4571).
library;

import 'current_work.dart';
import 'province_id.dart';
import 'unit.dart';

/// Minimal status for Phase 2 work and movement.
enum UnitStatus { idle, working }

UnitStatus unitStatusFromJson(String? value) {
  if (value == null) return UnitStatus.idle;
  return UnitStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => UnitStatus.idle,
  );
}

Map<String, dynamic> encodeUnitToJson(Unit unit) => {
  'id': unit.id,
  'type': unit.type,
  'ownerId': unit.ownerId,
  'provinceId': unit.locationProvinceId,
  'status': unit.status.name,
  if (unit.medals != 0) 'medals': unit.medals,
  if (unit.tileKey != null && unit.tileKey!.isNotEmpty) 'tileKey': unit.tileKey,
  if (unit.originTileKey != null && unit.originTileKey!.isNotEmpty)
    'originTileKey': unit.originTileKey,
  if (unit.assignedTileKey != null && unit.assignedTileKey!.isNotEmpty)
    'assignedTileKey': unit.assignedTileKey,
  if (unit.currentWork != null) 'currentWork': unit.currentWork!.toJson(),
};

Unit decodeUnitFromJson(Map<String, dynamic> json) {
  final cw = json['currentWork'];
  final tileKey = json['tileKey'] as String?;
  final rawProvince = ProvinceId.requirePrefixed(
    json['provinceId'] as String,
    fieldName: 'Unit.provinceId',
  );
  final normalizedStored = storedProvinceIdForTileAndLocation(
    tileKey,
    rawProvince,
  );
  return Unit(
    id: json['id'] as String,
    type: json['type'] as String,
    ownerId: json['ownerId'] as String,
    locationProvinceId: normalizedStored,
    status: unitStatusFromJson(json['status'] as String?),
    medals: (json['medals'] as int?) ?? 0,
    tileKey: tileKey,
    originTileKey: json['originTileKey'] as String?,
    assignedTileKey: json['assignedTileKey'] as String?,
    currentWork: cw is Map<String, dynamic>
        ? CurrentWork.fromJson(cw)
        : cw is Map<Object?, Object?>
        ? CurrentWork.fromJson(Map<String, dynamic>.from(cw))
        : null,
  );
}
