import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view_core.dart';

typedef SpyRevealTimerDecayCase = ({
  String description,
  String spyPlayerId,
  String targetOwnerId,
  String provinceLocalId,
  String tileKey,
  String visibilityBefore,
  String visibilityAfter,
});

final List<SpyRevealTimerDecayCase> spyRevealTimerDecayCases = [
  (
    description:
        'decrements timers for other-faction provinces when timer expires',
    spyPlayerId: 'p1',
    targetOwnerId: 'p2',
    provinceLocalId: 'P2',
    tileKey: 'oldWorld|P2|0|0',
    visibilityBefore: 'fullyVisible',
    visibilityAfter: VisibilityLevel.fogged.name,
  ),
  (
    description: 'never applies timers to own provinces',
    spyPlayerId: 'p1',
    targetOwnerId: 'p1',
    provinceLocalId: 'P1',
    tileKey: 'oldWorld|P1|0|0',
    visibilityBefore: 'fullyVisible',
    visibilityAfter: VisibilityLevel.fullyVisible.name,
  ),
  (
    description: 'leaves unknown tiles unchanged when timer expires',
    spyPlayerId: 'p1',
    targetOwnerId: 'p2',
    provinceLocalId: 'P2',
    tileKey: 'oldWorld|P2|0|0',
    visibilityBefore: 'unknown',
    visibilityAfter: VisibilityLevel.unknown.name,
  ),
];

typedef FogDecayCase = ({
  String description,
  List<Province> oldWorldProvinces,
  List<Province> newWorldProvinces,
  List<Unit> oldWorldUnits,
  Map<String, Map<String, String>> playerVisibilityByTile,
  String tileKey,
  String expectedVisibility,
});

const _owP2 = Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'p2');
const _nwP2 = Province(id: 'newWorld|P2', regionId: 'newWorld', ownerId: 'p2');

final List<FogDecayCase> fogDecayCases = [
  (
    description:
        'fogs tiles in other-faction provinces when no Explorer or Spy timer',
    oldWorldProvinces: const [_owP2],
    newWorldProvinces: const [],
    oldWorldUnits: const [],
    playerVisibilityByTile: const {
      'p1': {'oldWorld|P2|0|0': 'fullyVisible'},
    },
    tileKey: 'oldWorld|P2|0|0',
    expectedVisibility: VisibilityLevel.fogged.name,
  ),
  (
    description:
        'preserves visibility when Explorer is present in other-faction province',
    oldWorldProvinces: const [_owP2],
    newWorldProvinces: const [],
    oldWorldUnits: [
      Unit(
        id: 'explorer1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P2',
      ),
    ],
    playerVisibilityByTile: const {
      'p1': {'oldWorld|P2|0|0': 'fullyVisible'},
    },
    tileKey: 'oldWorld|P2|0|0',
    expectedVisibility: VisibilityLevel.fullyVisible.name,
  ),
  (
    description: 'does not promote unknown tiles in other-faction province',
    oldWorldProvinces: const [],
    newWorldProvinces: const [_nwP2],
    oldWorldUnits: const [],
    playerVisibilityByTile: const {
      'p1': {'newWorld|P2|0|0': 'unknown'},
    },
    tileKey: 'newWorld|P2|0|0',
    expectedVisibility: VisibilityLevel.unknown.name,
  ),
  (
    description: 'does not change fogged tiles in other-faction province',
    oldWorldProvinces: const [_owP2],
    newWorldProvinces: const [],
    oldWorldUnits: const [],
    playerVisibilityByTile: const {
      'p1': {'oldWorld|P2|0|0': 'fogged'},
    },
    tileKey: 'oldWorld|P2|0|0',
    expectedVisibility: VisibilityLevel.fogged.name,
  ),
];
