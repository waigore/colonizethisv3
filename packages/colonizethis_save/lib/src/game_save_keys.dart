/// Hive key suffixes and envelope field names for game saves.
/// SPEC/program/save-load.md. Refs #4077.
library;

const String kSuffixTileMapByRegion = '_tileMapByRegion';
const String kSuffixTopologyByRegion = '_topologyByRegion';
const String kSuffixCombinedTopology = '_combinedTopology';
const String kSuffixWarpLinks = '_warpLinks';

const String kSaveFormatVersionKey = 'saveFormatVersion';
const String kSaveGamePayloadKey = 'game';
const String kDraftOrdersKey = 'draftOrders';
const String kProductionDesiredOutputKey = 'productionDesiredOutputByRecipe';
const String kDisplayNameKey = 'displayName';
const String kListMetaKey = 'listMeta';
const String kListMetaLastSavedAtKey = 'lastSavedAt';
const String kListMetaTurnNumberKey = 'turnNumber';
const String kListMetaCalendarYearKey = 'calendarYear';
const String kListMetaHumanNationKey = 'humanNation';

const List<String> kMapDataKeySuffixes = <String>[
  kSuffixTileMapByRegion,
  kSuffixTopologyByRegion,
  kSuffixCombinedTopology,
  kSuffixWarpLinks,
];
