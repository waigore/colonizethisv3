import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'faction_setup_helpers.dart';
import 'game_setup_context.dart';
import 'game_setup_create.dart';
import 'game_setup_helpers_towns.dart';
import 'province_name_fallback.dart';

export 'game_setup_helpers_towns.dart';

part 'game_setup_helpers_naming.dart';
part 'game_setup_helpers_bootstrap.dart';

Map<String, String> buildPoliticalGlyphByPlayerId({
  required Game game,
  required List<String> greatPowerIds,
  required List<String> minorNationIds,
  required List<String> tribeIds,
}) {
  final glyphs = <String, String>{};
  assignGreatPowerGlyphs(
    game: game,
    greatPowerIds: greatPowerIds,
    glyphs: glyphs,
  );
  assignNonGreatPowerGlyphs(
    minorNationIds: minorNationIds,
    tribeIds: tribeIds,
    glyphs: glyphs,
  );
  return glyphs;
}

Set<String> assignGreatPowerGlyphs({
  required Game game,
  required List<String> greatPowerIds,
  required Map<String, String> glyphs,
}) {
  final usedUpper = <String>{};
  for (final gpId in greatPowerIds) {
    final player = game.players.firstWhere(
      (p) => p.id == gpId,
      orElse: () => game.players.first,
    );
    final glyph = pickUpperGlyphForGreatPower(player.displayName, usedUpper);
    glyphs[gpId] = glyph;
    usedUpper.add(glyph);
  }
  return usedUpper;
}

void assignNonGreatPowerGlyphs({
  required List<String> minorNationIds,
  required List<String> tribeIds,
  required Map<String, String> glyphs,
}) {
  final nonGpIds = <String>[...minorNationIds, ...tribeIds]..sort();
  for (var i = 0; i < nonGpIds.length; i++) {
    glyphs[nonGpIds[i]] = glyphForNonGreatPowerIndex(i);
  }
}

String pickUpperGlyphForGreatPower(String name, Set<String> used) {
  final upper = name.toUpperCase();
  for (var i = 0; i < upper.length; i++) {
    final ch = upper[i];
    if (isAsciiUpper(ch) && !used.contains(ch)) {
      return ch;
    }
  }
  for (var code = 'A'.codeUnitAt(0); code <= 'Z'.codeUnitAt(0); code++) {
    final ch = String.fromCharCode(code);
    if (!used.contains(ch)) return ch;
  }
  return 'X';
}

bool isAsciiUpper(String char) {
  final code = char.codeUnitAt(0);
  return code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0);
}

String glyphForNonGreatPowerIndex(int index) {
  const digitGlyphs = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
  if (index < digitGlyphs.length) {
    return digitGlyphs[index];
  }
  final letterIndex = index - digitGlyphs.length;
  final baseCode = 'a'.codeUnitAt(0);
  return String.fromCharCode(baseCode + letterIndex);
}

/// Builds a single topology with prefixed node ids (regionId|localId) and warp edges.
/// SPEC/game/map-topology.md: OW and NW are separate; connectivity across regions only via warp zones.
MapTopology buildCombinedTopology({
  required Map<String, MapTopology> topologyByRegion,
  List<WarpLink> warpLinks = const [],
}) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final entry in topologyByRegion.entries) {
    final regionId = entry.key;
    final topo = entry.value;
    for (final n in topo.nodes) {
      nodes.add(
        TopologyNode(id: '$regionId|${n.id}', regionId: regionId, type: n.type),
      );
    }
    for (final e in topo.edges) {
      edges.add(
        TopologyEdge(id1: '$regionId|${e.id1}', id2: '$regionId|${e.id2}'),
      );
    }
  }
  for (final link in warpLinks) {
    edges.add(TopologyEdge(id1: link.prefixedKey, id2: link.otherPrefixedKey));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

List<String> provinceIdsFromTopology(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toList();
}

/// Re-runs §7d province town assignment after the caller mutates provinces or maps.
///
/// For integration tests that need fixtures (e.g. overseas ownership) that
/// [createGameFromGeneratedMaps] does not produce by default.
Game assignProvinceTownsForTesting({
  required Game game,
  required Map<String, MapTopology> topologyByRegion,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  return assignProvinceTowns(
    game: game,
    topologyByRegion: topologyByRegion,
    tileMapByRegion: tileMapByRegion,
  );
}
