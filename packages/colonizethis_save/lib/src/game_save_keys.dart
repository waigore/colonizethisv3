/// Hive key suffixes and envelope field names for game saves.
/// SPEC/program/save-load.md. Refs #4077 / #4664.
library;

/// Max manual named saves for **new** create; overwrite still allowed at cap.
/// SPEC/program/save-load-list-metadata.md.
const int kMaxManualSaves = 20;

/// Fixed Hive key stem for the single auto-save slot. Not listed in listGameIds.
/// See SPEC/program/save-load.md § Auto-save slot.
const String kAutoSaveSlotId = '__colonizethis_autosave';

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
