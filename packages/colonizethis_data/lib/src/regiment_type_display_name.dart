/// Human-readable regiment labels for UI. Aligned with
/// SPEC/game/military-units.md § Regiment Table (names column).

/// Display name for a land regiment [regimentTypeId] (matches [RegimentStats.id]).
/// Unknown ids fall back to [regimentTypeId].
String regimentTypeDisplayName(String regimentTypeId) =>
    _regimentDisplayNameById[regimentTypeId] ?? regimentTypeId;

/// Map from regiment id to display string; kept in sync with [regimentCatalog].
const Map<String, String> _regimentDisplayNameById = {
  'peasant_levies': 'Peasant Levies',
  'pikemen': 'Pikemen',
  'arquebusiers': 'Arquebusiers',
  'bowmen': 'Bowmen',
  'squires': 'Squires',
  'knights': 'Knights',
  'culverin': 'Culverin',
  'calivermen': 'Calivermen',
  'halberdiers': 'Halberdiers',
  'musketeers': 'Musketeers',
  'cossacks': 'Cossacks',
  'lancers': 'Lancers',
  'harquebusiers': 'Harquebusiers',
  'horse_artillery': 'Horse Artillery',
  'royal_artillery': 'Royal Artillery',
  'skirmishers': 'Skirmishers',
  'regulars': 'Regulars',
  'grenadiers': 'Grenadiers',
  'hussars': 'Hussars',
  'cuirassiers': 'Cuirassiers',
  'light_artillery': 'Light Artillery',
  'heavy_artillery': 'Heavy Artillery',
  'sharpshooters': 'Sharpshooters',
  'rifle_infantry': 'Rifle Infantry',
  'guards': 'Guards',
  'scouts': 'Scouts',
  'carbine_cavalry': 'Carbine Cavalry',
  'field_artillery': 'Field Artillery',
  'siege_guns': 'Siege Guns',
};
