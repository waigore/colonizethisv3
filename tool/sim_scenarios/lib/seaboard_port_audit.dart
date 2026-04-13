// Seaboard / port data audit for sim_scenarios. GitHub #1766, SPEC/game/capital-and-connectivity.md,
// SPEC/ui/town-port-icons.md. Aligns seaboard detection with init_game_map_view_builder (P–S topology
// edges + sea zone node ids) and validates drawable sea cells for every portsByProvinceSeaboard entry.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// One failure row for machine-readable reporting (JSON) and stderr messages.
class SeaboardPortAuditFailure {
  const SeaboardPortAuditFailure({
    required this.kind,
    required this.message,
    this.region,
    this.provinceId,
    this.seaboardKey,
    this.portTileKey,
    this.townTileKey,
    this.factionId,
    this.seaZoneId,
  });

  /// `drawable_error` | `missing_capital_port` | `malformed_port_entry` |
  /// `overseas_town_not_port_tile`
  final String kind;
  final String message;
  final String? region;
  final String? provinceId;
  final String? seaboardKey;
  final String? portTileKey;

  /// Province town tile when [kind] is `overseas_town_not_port_tile`.
  final String? townTileKey;
  final String? factionId;
  final String? seaZoneId;

  Map<String, Object?> toJsonObject() => {
    'kind': kind,
    'message': message,
    if (region != null) 'region': region,
    if (provinceId != null) 'provinceId': provinceId,
    if (seaboardKey != null) 'seaboardKey': seaboardKey,
    if (portTileKey != null) 'portTileKey': portTileKey,
    if (townTileKey != null) 'townTileKey': townTileKey,
    if (factionId != null) 'factionId': factionId,
    if (seaZoneId != null) 'seaZoneId': seaZoneId,
  };

  @override
  String toString() => message;
}

/// Outcome of [runSeaboardPortAudit].
class SeaboardPortAuditOutcome {
  const SeaboardPortAuditOutcome({
    required this.skipped,
    this.skipReason,
    this.failures = const [],
  });

  final bool skipped;
  final String? skipReason;
  final List<SeaboardPortAuditFailure> failures;

  bool get passed => failures.isEmpty;

  Map<String, Object?> toJsonObject() => {
    'skipped': skipped,
    if (skipReason != null) 'skipReason': skipReason,
    'failureCount': failures.length,
    'failures': [for (final f in failures) f.toJsonObject()],
  };
}

Set<String> _seaZoneNodeIds(MapTopology topology) => {
  for (final n in topology.nodes)
    if (n.type == TopologyNodeType.seaZone) n.id,
};

TopologyNode? _nodeById(MapTopology topology, String id) {
  for (final n in topology.nodes) {
    if (n.id == id) return n;
  }
  return null;
}

/// Same rule as [applyCapitalPortAndRoad]: sea zones sharing a topology edge with [localProvinceId].
Set<String> _seaZonesAdjacentToProvince(
  MapTopology topology,
  String localProvinceId,
) {
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != localProvinceId && edge.id2 != localProvinceId) {
      continue;
    }
    final other = edge.id1 == localProvinceId ? edge.id2 : edge.id1;
    final node = _nodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) {
      out.add(other);
    }
  }
  return out;
}

/// Parses `portsByProvinceSeaboard` keys: `regionId|localProvinceId|seaZoneId` or legacy `province|sea`.
(String? fullProvinceId, String? seaZoneId, String? error) _parseSeaboardKey(
  String key,
) {
  final parts = key.split('|');
  if (parts.length >= 3) {
    return ('${parts[0]}|${parts[1]}', parts[2], null);
  }
  if (parts.length >= 2) {
    return (parts[0], parts[1], null);
  }
  return (null, null, 'seaboard key has fewer than 2 segments: "$key"');
}

/// Validates port registry and capital seaboard completeness per SPEC/game/capital-and-connectivity.md
/// § Capital Setup (shared [applyCapitalPortAndRoad] for GPs, minors, tribes on sea-bound capitals).
SeaboardPortAuditOutcome runSeaboardPortAudit({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  if (tileMapByRegion.isEmpty) {
    return const SeaboardPortAuditOutcome(
      skipped: true,
      skipReason: 'tileMapByRegion is empty',
    );
  }
  if (topologyByRegion.isEmpty) {
    return const SeaboardPortAuditOutcome(
      skipped: true,
      skipReason: 'topologyByRegion is empty',
    );
  }

  final failures = <SeaboardPortAuditFailure>[];
  final ports = game.worldState.portsByProvinceSeaboard;

  for (final e in ports.entries) {
    final key = e.key;
    final portTileKey = e.value;
    final parsed = _parseSeaboardKey(key);
    if (parsed.$3 != null) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'malformed_port_entry',
          message:
              '[seaboard-port-audit] malformed seaboardKey="$key": ${parsed.$3}',
          seaboardKey: key,
          portTileKey: portTileKey,
        ),
      );
      continue;
    }
    final fullProvinceId = parsed.$1!;
    final seaZoneIdFromKey = parsed.$2!;

    final tileParts = portTileKey.split('|');
    if (tileParts.length < 4) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'malformed_port_entry',
          message:
              '[seaboard-port-audit] port tile key must have 4 segments for '
              'seaboardKey="$key" got "$portTileKey"',
          seaboardKey: key,
          portTileKey: portTileKey,
          provinceId: fullProvinceId,
        ),
      );
      continue;
    }
    final regionId = tileParts[0];
    final tileMap = tileMapByRegion[regionId];
    final topology = topologyByRegion[regionId];
    if (tileMap == null || topology == null) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'malformed_port_entry',
          message:
              '[seaboard-port-audit] missing tile map or topology for region '
              '$regionId (seaboardKey="$key" portTileKey="$portTileKey")',
          region: regionId,
          seaboardKey: key,
          portTileKey: portTileKey,
          provinceId: fullProvinceId,
        ),
      );
      continue;
    }

    final seaZoneIds = _seaZoneNodeIds(topology);
    if (!seaZoneIds.contains(seaZoneIdFromKey)) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'malformed_port_entry',
          message:
              '[seaboard-port-audit] seaZoneId "$seaZoneIdFromKey" from seaboardKey '
              '"$key" is not a sea zone node in region $regionId topology',
          region: regionId,
          seaboardKey: key,
          seaZoneId: seaZoneIdFromKey,
          provinceId: fullProvinceId,
        ),
      );
      continue;
    }

    try {
      computePortDrawableSeaCellForMap(
        tileMap: tileMap,
        seaZoneIds: seaZoneIds,
        portTileKey: portTileKey,
        contextLabel: 'audit seaboardKey=$key',
      );
    } on PortDrawableSeaCellException catch (ex) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'drawable_error',
          message:
              '[seaboard-port-audit] drawable_error region=$regionId '
              'province=$fullProvinceId seaboardKey="$key" '
              'portTileKey="$portTileKey" detail=$ex',
          region: regionId,
          provinceId: fullProvinceId,
          seaboardKey: key,
          portTileKey: portTileKey,
        ),
      );
    }
  }

  void checkFaction({
    required String factionId,
    required CapitalTile? capitalTile,
  }) {
    if (capitalTile == null) {
      return;
    }
    final regionId = capitalTile.regionId;
    final topology = topologyByRegion[regionId];
    final tileMap = tileMapByRegion[regionId];
    if (topology == null || tileMap == null) {
      return;
    }
    final fullProvinceId = capitalTile.provinceId;
    final localId = ProvinceId.localIdFrom(fullProvinceId);
    if (!isProvinceSeaBound(topology, localId)) {
      return;
    }
    final adjacentSeas = _seaZonesAdjacentToProvince(topology, localId);
    for (final sea in adjacentSeas) {
      final expectedKey = '$fullProvinceId|$sea';
      if (!ports.containsKey(expectedKey)) {
        failures.add(
          SeaboardPortAuditFailure(
            kind: 'missing_capital_port',
            message:
                '[seaboard-port-audit] missing_capital_port faction=$factionId '
                'region=$regionId province=$fullProvinceId seaZone=$sea '
                '(expected portsByProvinceSeaboard key "$expectedKey")',
            region: regionId,
            provinceId: fullProvinceId,
            factionId: factionId,
            seaZoneId: sea,
          ),
        );
      }
    }
  }

  for (final p in game.players) {
    checkFaction(factionId: p.id, capitalTile: p.capitalTile);
  }
  for (final m in game.minorNations) {
    checkFaction(factionId: m.id, capitalTile: m.capitalTile);
  }
  for (final t in game.tribes) {
    checkFaction(factionId: t.id, capitalTile: t.capitalTile);
  }

  _auditOverseasTownMatchesPortTile(
    game: game,
    ports: ports,
    failures: failures,
  );

  return SeaboardPortAuditOutcome(skipped: false, failures: failures);
}

/// Capital home region per faction id (Great Power, minor nation, tribe).
Map<String, String> _capitalRegionIdByFactionId(Game game) {
  final out = <String, String>{};
  void put(String id, String? capProvinceId) {
    if (capProvinceId == null) return;
    out[id] = ProvinceId.regionIdFrom(capProvinceId);
  }

  for (final p in game.players) {
    put(p.id, p.capitalProvinceId);
  }
  for (final m in game.minorNations) {
    put(m.id, m.capitalProvinceId);
  }
  for (final t in game.tribes) {
    put(t.id, t.capitalProvinceId);
  }
  return out;
}

Set<String> _portTileValuesForProvince(
  Map<String, String> ports,
  String fullProvinceId,
) {
  final prefix = '$fullProvinceId|';
  return {
    for (final e in ports.entries)
      if (e.key.startsWith(prefix)) e.value,
  };
}

/// SPEC/game/capital-and-connectivity.md § Town per province: **overseas** provinces
/// use the **port tile** as town when any port exists in `portsByProvinceSeaboard`.
/// Unowned provinces have no port-registry requirement (same as setup: town = first tile).
void _auditOverseasTownMatchesPortTile({
  required Game game,
  required Map<String, String> ports,
  required List<SeaboardPortAuditFailure> failures,
}) {
  final capRegionByOwner = _capitalRegionIdByFactionId(game);
  final capitalProvinceByOwner = <String, String>{};
  for (final p in game.players) {
    if (p.capitalProvinceId != null) {
      capitalProvinceByOwner[p.id] = p.capitalProvinceId!;
    }
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId != null) {
      capitalProvinceByOwner[m.id] = m.capitalProvinceId!;
    }
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId != null) {
      capitalProvinceByOwner[t.id] = t.capitalProvinceId!;
    }
  }

  void checkProvince(Province p) {
    final ownerId = p.ownerId;
    if (ownerId == null) {
      return;
    }
    final capRegion = capRegionByOwner[ownerId];
    if (capRegion == null) {
      return;
    }
    final capProvince = capitalProvinceByOwner[ownerId];
    if (capProvince != null && p.id == capProvince) {
      return;
    }
    final overseas = p.regionId != capRegion;
    if (!overseas) {
      return;
    }
    final portTiles = _portTileValuesForProvince(ports, p.id);
    if (portTiles.isEmpty) {
      return;
    }
    final town = p.townTileKey;
    if (town == null || !portTiles.contains(town)) {
      failures.add(
        SeaboardPortAuditFailure(
          kind: 'overseas_town_not_port_tile',
          message:
              '[seaboard-port-audit] overseas_town_not_port_tile '
              'faction=$ownerId region=${p.regionId} province=${p.id} '
              'townTileKey=${town ?? "(null)"} expected one of '
              '${portTiles.join(", ")} per SPEC/game/capital-and-connectivity.md '
              '§ Town per province (overseas)',
          region: p.regionId,
          provinceId: p.id,
          factionId: ownerId,
          townTileKey: town,
        ),
      );
    }
  }

  for (final p in game.worldState.oldWorld.provinces) {
    checkProvince(p);
  }
  for (final p in game.worldState.newWorld.provinces) {
    checkProvince(p);
  }
}
