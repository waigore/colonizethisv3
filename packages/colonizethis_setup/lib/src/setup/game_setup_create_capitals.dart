part of 'game_setup_create.dart';

Game _assignAllCapitals({
  required Game game,
  required List<String> gpIds,
  required List<String> minorIds,
  required List<String> tribeIds,
  required List<Province> oldWorldProvinces,
  required List<Province> newWorldProvinces,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required TileMapResult tileMapOldWorld,
  required TileMapResult tileMapNewWorld,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  var out = assignCapitalsForFactions(
    game: game,
    factionIds: gpIds,
    provinces: oldWorldProvinces,
    regionId: kRegionOldWorld,
    topology: topologyOldWorld,
    tileMap: tileMapOldWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: true,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapital(
          game: g,
          playerId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );
  out = assignCapitalsForFactions(
    game: out,
    factionIds: minorIds,
    provinces: oldWorldProvinces,
    regionId: kRegionOldWorld,
    topology: topologyOldWorld,
    tileMap: tileMapOldWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: false,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapitalForMinorNation(
          game: g,
          minorId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );
  return assignCapitalsForFactions(
    game: out,
    factionIds: tribeIds,
    provinces: newWorldProvinces,
    regionId: kRegionNewWorld,
    topology: topologyNewWorld,
    tileMap: tileMapNewWorld,
    tileMapByRegion: tileMapByRegion,
    requireSeaBound: false,
    setCapitalFn: (g, factionId, provinceId, tile, topo, tmByRegion) =>
        setCapitalForTribe(
          game: g,
          tribeId: factionId,
          provinceId: provinceId,
          tile: tile,
          topology: topo,
          tileMapByRegion: tmByRegion,
        ),
  );
}
