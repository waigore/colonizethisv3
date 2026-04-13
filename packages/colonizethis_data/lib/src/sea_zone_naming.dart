import 'deterministic_pool_shuffle.dart';
import 'map_topology.dart';
import 'topology_node.dart';

const List<String> oldWorldSeaNamePreset = [
  'North Sea',
  'Norwegian Sea',
  'Baltic Sea',
  'Barents Sea',
  'White Sea',
  'Irish Sea',
  'Celtic Sea',
  'English Channel',
  'Bay of Biscay',
  'Ligurian Sea',
  'Tyrrhenian Sea',
  'Adriatic Sea',
  'Ionian Sea',
  'Aegean Sea',
  'Sea of Marmara',
  'Black Sea',
  'Sea of Azov',
  'Alboran Sea',
  'Balearic Sea',
  'Sardinian Sea',
  'Levantine Sea',
  'Cretan Sea',
  'Thracian Sea',
  'Myrtoan Sea',
  'Icarian Sea',
  'Hebrides Sea',
  'Skagerrak',
  'Kattegat',
  'Gulf of Bothnia',
  'Gulf of Finland',
  'Gulf of Riga',
  'Gulf of Lion',
  'Gulf of Cadiz',
  'Strait of Gibraltar',
  'Strait of Dover',
  'Faroe-Shetland Channel',
  'Rockall Trough',
  'Porcupine Bank',
  'Canary Basin',
  'Iberian Basin',
  'Labrador Sea Approach',
  'Mid-Atlantic Ridge Sea',
  'Azores Sea',
  'Madeira Sea',
  'Sicilian Channel',
  'Strait of Messina',
  'Bosphorus Sea',
  'Dardanelles Sea',
  'Sea of the Hebrides',
  'Minch Sea',
  'Firth of Forth Sea',
  'Moray Firth Sea',
  'Solent Sea',
  'Bristol Channel Sea',
  'Dogger Sea',
  'Jutland Sea',
  'Pomeranian Sea',
  'Gulf of Taranto',
  'Gulf of Venice',
  'Corinth Gulf Sea',
];

const List<String> newWorldSeaNamePreset = [
  'Caribbean Sea',
  'Gulf of Mexico',
  'Sargasso Sea',
  'Labrador Sea',
  'Baffin Bay',
  'Hudson Bay',
  'Davis Strait',
  'Gulf of St. Lawrence',
  'Scotia Sea',
  'Argentine Sea',
  'Weddell Sea',
  'Bellingshausen Sea',
  'Peruvian Sea',
  'Chilean Sea',
  'Gulf of California',
  'Sea of Cortez',
  'Gulf of Alaska',
  'Bering Sea',
  'Beaufort Sea',
  'Chukchi Sea',
  'Panama Basin',
  'Colombian Basin',
  'Venezuelan Basin',
  'Yucatan Basin',
  'Florida Straits Sea',
  'Mona Passage Sea',
  'Windward Passage Sea',
  'Anegada Passage Sea',
  'Strait of Magellan Sea',
  'Drake Passage Sea',
  'Gulf of Honduras',
  'Gulf of Darien',
  'Gulf of Panama',
  'Gulf of Guayaquil',
  'Gulf of Penas',
  'Gulf of San Jorge',
  'Gulf of Maine',
  'Bay of Fundy',
  'Chesapeake Sea',
  'Delaware Sea',
  'Cape Cod Sea',
  'Newfoundland Basin',
  'Bahamas Sea',
  'Antilles Sea',
  'Grenada Basin',
  'Amazon Sea',
  'Guiana Sea',
  'Brazil Sea',
  'Patagonian Sea',
  'Rio de la Plata Sea',
  'Bahia Sea',
  'Cape Horn Sea',
  'Aleutian Sea',
  'Vancouver Sea',
  'Californian Sea',
  'Nicaraguan Sea',
  'Mosquito Coast Sea',
  'Campeche Sea',
  'Maracaibo Sea',
  'Paria Sea',
];

String _suffixOrdinal(int n) => ' ($n)';

int _fnv1a32Update(int hash, int value) {
  var out = hash & 0xFFFFFFFF;
  final v = value & 0xFFFFFFFF;
  for (var shift = 0; shift < 32; shift += 8) {
    out ^= (v >> shift) & 0xFF;
    out = (out * 0x01000193) & 0xFFFFFFFF;
  }
  return out;
}

int _stableStringHash(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash = _fnv1a32Update(hash, codeUnit);
  }
  return hash;
}

/// Deterministically derives the per-region shuffle seed for sea-zone naming.
///
/// This must remain independent from process-randomized hash implementations so
/// fixed `(namingSeed, regionId)` inputs are reproducible across app restarts.
int deriveSeaZoneNamingShuffleSeed({
  required int namingSeed,
  required String regionId,
}) {
  var hash = 0x811C9DC5;
  hash = _fnv1a32Update(hash, 0x5EA20E);
  hash = _fnv1a32Update(hash, namingSeed);
  hash = _fnv1a32Update(hash, _stableStringHash(regionId));
  return hash & 0x7FFFFFFF;
}

Map<String, String> buildSeaZoneDisplayNamesForRegion({
  required MapTopology topology,
  required String regionId,
  required int namingSeed,
}) {
  final seaZoneIds =
      topology.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toList()
        ..sort();
  if (seaZoneIds.isEmpty) return const <String, String>{};

  final preset = regionId == 'newWorld'
      ? newWorldSeaNamePreset
      : oldWorldSeaNamePreset;
  final n = preset.length;
  final rngSeed = deriveSeaZoneNamingShuffleSeed(
    namingSeed: namingSeed,
    regionId: regionId,
  );
  final poolIndices = shuffledPoolIndices(poolLength: n, seed: rngSeed);

  final out = <String, String>{};
  for (var i = 0; i < seaZoneIds.length; i++) {
    final base = preset[poolIndices[i % n]];
    final cycle = (i ~/ n) + 1;
    final display = cycle == 1 ? base : '$base${_suffixOrdinal(cycle)}';
    out['$regionId|${seaZoneIds[i]}'] = display;
  }
  return out;
}
