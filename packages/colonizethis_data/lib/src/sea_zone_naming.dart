import 'map_topology.dart';
import 'region_ids.dart';
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

Map<String, String> buildSeaZoneDisplayNamesForRegion({
  required MapTopology topology,
  required String regionId,
  required int namingSeed,
}) {
  // Sea-zone naming is fixed-order by design: same topology ids => same names.
  final _ = namingSeed;
  final seaZoneIds =
      topology.nodes
          .where((n) => n.type == TopologyNodeType.seaZone)
          .map((n) => n.id)
          .toList()
        ..sort();
  if (seaZoneIds.isEmpty) return const <String, String>{};

  final preset = regionId == kNewWorldRegionId
      ? newWorldSeaNamePreset
      : oldWorldSeaNamePreset;
  final n = preset.length;

  final out = <String, String>{};
  for (var i = 0; i < seaZoneIds.length; i++) {
    final base = preset[i % n];
    final cycle = (i ~/ n) + 1;
    final display = cycle == 1 ? base : '$base${_suffixOrdinal(cycle)}';
    out['$regionId|${seaZoneIds[i]}'] = display;
  }
  return out;
}
