/// Human-readable ship type labels for UI. Aligned with
/// SPEC/game/ships-and-naval.md ship_type_id roster ([NavalStatsCatalog.byId]).

/// Display name for a naval [shipTypeId]. Unknown ids fall back to [shipTypeId].
String shipTypeDisplayName(String shipTypeId) =>
    _shipDisplayNameById[shipTypeId] ?? shipTypeId;

const Map<String, String> _shipDisplayNameById = {
  'carrack': 'Carrack',
  'fluyte': 'Fluyte',
  'sloop': 'Sloop',
  'trader': 'Trader',
  'galleon': 'Galleon',
  'indiaman': 'Indiaman',
  'frigate': 'Frigate',
  'raider': 'Raider',
  'ship_of_the_line': 'Ship of the Line',
  'clipper': 'Clipper',
  'merchant_steamship': 'Merchant Steamship',
  'ironclad': 'Ironclad',
};
