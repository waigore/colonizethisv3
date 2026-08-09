import 'package:meta/meta.dart';

export 'naming_default_config.dart';

/// A leader variant for a Great Power. GDD 09. Each variant has distinct
/// bonuses and optionally a distinct province pool (e.g. Prussia's two variants).
@immutable
class LeaderVariant {
  const LeaderVariant({
    required this.id,
    required this.name,
    required this.leaderKey,
    required this.provinceNamePool,
  });

  final String id;
  final String name;
  final String leaderKey;

  /// Homeland province names (9 non-capital). Capital applied separately.
  final List<String> provinceNamePool;
}

/// Resolved naming configuration for the active ruleset.
///
/// SPEC/game/naming.md, SPEC/program/ruleset-config.md.
@immutable
class GreatPowerNaming {
  const GreatPowerNaming({
    required this.id,
    required this.countryName,
    required this.adjective,
    required this.capitalCityName,
    required this.leaderVariants,
  });

  final String id;
  final String countryName;
  final String adjective;
  final String capitalCityName;
  final List<LeaderVariant> leaderVariants;

  LeaderVariant variantById(String variantId) => leaderVariants.firstWhere(
    (v) => v.id == variantId,
    orElse: () => leaderVariants.first,
  );

  bool get hasMultipleVariants => leaderVariants.length > 1;

  String get defaultLeaderVariantId => leaderVariants.first.id;
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
    this.provinceNamePool = const [],
  });

  final String id;
  final String displayName;
  final List<String> provinceNamePool;
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
      greatPowers
          .firstWhere((g) => g.id == id, orElse: () => _emptyGp)
          .id
          .isEmpty
      ? null
      : greatPowers.firstWhere((g) => g.id == id);

  static const GreatPowerNaming _emptyGp = GreatPowerNaming(
    id: '',
    countryName: '',
    adjective: '',
    capitalCityName: '',
    leaderVariants: [],
  );

  String defaultLeaderVariantId(String gpId) {
    final gp = gpById(gpId);
    if (gp == null || gp.leaderVariants.isEmpty) return '';
    return gp.leaderVariants.first.id;
  }

  bool hasMultipleLeaderVariants(String gpId) {
    final gp = gpById(gpId);
    return gp != null && gp.leaderVariants.length > 1;
  }

  MinorNationNaming? minorById(String id) =>
      minorNations
          .firstWhere(
            (m) => m.id == id,
            orElse: () => const MinorNationNaming(id: '', displayName: ''),
          )
          .id
          .isEmpty
      ? null
      : minorNations.firstWhere((m) => m.id == id);

  TribeNaming? tribeById(String id) =>
      tribes
          .firstWhere(
            (t) => t.id == id,
            orElse: () => const TribeNaming(
              id: '',
              displayName: '',
              provinceNamePool: [],
            ),
          )
          .id
          .isEmpty
      ? null
      : tribes.firstWhere((t) => t.id == id);
}

/// All selectable Great Power semantic ids. GDD 09. Each GP appears at most once per game.
const List<String> allGreatPowerIds = [
  'england',
  'france',
  'spain',
  'portugal',
  'netherlands',
  'prussia',
  'sweden',
];

/// Prussia leader variant ids.
const String prussiaVariantFrederickTheGreat = 'frederick_the_great';
const String prussiaVariantFrederickWilliam = 'frederick_william';
