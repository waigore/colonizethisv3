import 'package:meta/meta.dart';

/// Resolved naming configuration for the active ruleset.
///
/// SPEC/game/naming.md, SPEC/program/ruleset-config.md.
@immutable
class GreatPowerNaming {
  const GreatPowerNaming({
    required this.id,
    required this.countryName,
    required this.adjective,
    required this.leaderKey,
    required this.capitalCityName,
    required this.provinceNamePool,
  });

  final String id;
  final String countryName;
  final String adjective;
  final String leaderKey;
  final String capitalCityName;
  final List<String> provinceNamePool;
}

@immutable
class MinorNationNaming {
  const MinorNationNaming({
    required this.id,
    required this.displayName,
    this.provinceNamePool = const [],
  });

  final String id;
  final String displayName;
  final List<String> provinceNamePool;
}

@immutable
class TribeNaming {
  const TribeNaming({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

@immutable
class ResolvedNamingConfig {
  const ResolvedNamingConfig({
    required this.greatPowers,
    required this.minorNations,
    required this.tribes,
  });

  final List<GreatPowerNaming> greatPowers;
  final List<MinorNationNaming> minorNations;
  final List<TribeNaming> tribes;

  GreatPowerNaming? gpById(String id) =>
      greatPowers.firstWhere((g) => g.id == id, orElse: () => const GreatPowerNaming(
            id: '',
            countryName: '',
            adjective: '',
            leaderKey: '',
            capitalCityName: '',
            provinceNamePool: [],
          )).id.isEmpty
          ? null
          : greatPowers.firstWhere((g) => g.id == id);

  MinorNationNaming? minorById(String id) =>
      minorNations.firstWhere((m) => m.id == id, orElse: () => const MinorNationNaming(
            id: '',
            displayName: '',
          )).id.isEmpty
          ? null
          : minorNations.firstWhere((m) => m.id == id);

  TribeNaming? tribeById(String id) =>
      tribes.firstWhere((t) => t.id == id, orElse: () => const TribeNaming(
            id: '',
            displayName: '',
          )).id.isEmpty
          ? null
          : tribes.firstWhere((t) => t.id == id);
}

/// Default historically inspired naming config for the MVP ruleset.
///
/// This is a program-level stand-in for a future JSON-driven ruleset; it is
/// deterministic and aligned with the Great Power identities from the GDD.
const ResolvedNamingConfig defaultNamingConfig = ResolvedNamingConfig(
  greatPowers: [
    GreatPowerNaming(
      id: 'gp1',
      countryName: 'Spain',
      adjective: 'Spanish',
      leaderKey: 'spain_leader',
      capitalCityName: 'Madrid',
      provinceNamePool: [
        'Castile',
        'Andalusia',
        'Catalonia',
        'Valencia',
        'Navarre',
        'Galicia',
      ],
    ),
    GreatPowerNaming(
      id: 'gp2',
      countryName: 'France',
      adjective: 'French',
      leaderKey: 'france_leader',
      capitalCityName: 'Paris',
      provinceNamePool: [
        'Île-de-France',
        'Normandy',
        'Brittany',
        'Aquitaine',
        'Burgundy',
        'Provence',
      ],
    ),
    GreatPowerNaming(
      id: 'gp3',
      countryName: 'England',
      adjective: 'English',
      leaderKey: 'england_leader',
      capitalCityName: 'London',
      provinceNamePool: [
        'Wessex',
        'Mercia',
        'Northumbria',
        'Lancashire',
        'Kent',
        'Cornwall',
      ],
    ),
    GreatPowerNaming(
      id: 'gp4',
      countryName: 'Austria',
      adjective: 'Austrian',
      leaderKey: 'austria_leader',
      capitalCityName: 'Vienna',
      provinceNamePool: [
        'Bohemia',
        'Moravia',
        'Tyrol',
        'Styria',
        'Galicia',
        'Carniola',
      ],
    ),
    GreatPowerNaming(
      id: 'gp5',
      countryName: 'Prussia',
      adjective: 'Prussian',
      leaderKey: 'prussia_leader',
      capitalCityName: 'Berlin',
      provinceNamePool: [
        'Brandenburg',
        'East Prussia',
        'Pomerania',
        'Silesia',
        'Westphalia',
      ],
    ),
    GreatPowerNaming(
      id: 'gp6',
      countryName: 'Russia',
      adjective: 'Russian',
      leaderKey: 'russia_leader',
      capitalCityName: 'St Petersburg',
      provinceNamePool: [
        'Muscovy',
        'Novgorod',
        'Smolensk',
        'Kiev',
        'Kazan',
        'Astrakhan',
      ],
    ),
    GreatPowerNaming(
      id: 'gp7',
      countryName: 'Ottoman Empire',
      adjective: 'Ottoman',
      leaderKey: 'ottoman_leader',
      capitalCityName: 'Constantinople',
      provinceNamePool: [
        'Anatolia',
        'Rumelia',
        'Syria',
        'Egypt',
        'Bulgaria',
        'Albania',
      ],
    ),
  ],
  minorNations: [
    MinorNationNaming(
      id: 'minor1',
      displayName: 'Portugal',
      provinceNamePool: ['Lisbon', 'Oporto'],
    ),
    MinorNationNaming(
      id: 'minor2',
      displayName: 'Savoy',
      provinceNamePool: ['Savoy', 'Piedmont'],
    ),
  ],
  tribes: [
    TribeNaming(
      id: 'tribe1',
      displayName: 'Aztec',
    ),
    TribeNaming(
      id: 'tribe2',
      displayName: 'Inca',
    ),
  ],
);

