// State verifier - assertion engine for verifying game state.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'scenario.dart';

/// Result of verification.
class VerificationResult {
  const VerificationResult({
    required this.passed,
    required this.failures,
  });

  final bool passed;
  final List<String> failures;
}

/// Verifies game state against assertions.
class StateVerifier {
  /// Verifies all assertions against the game state.
  /// If atTurn is specified, only checks assertions for that turn.
  VerificationResult verify(
    Game game,
    List<Assertion> assertions, {
    int? atTurn,
  }) {
    final failures = <String>[];

    for (final assertion in assertions) {
      // Filter by turn if specified
      if (atTurn != null &&
          assertion.turn != null &&
          assertion.turn != atTurn) {
        continue;
      }

      final result = _verifyAssertion(game, assertion);
      if (!result.passed) {
        failures.addAll(result.failures);
      }
    }

    return VerificationResult(
      passed: failures.isEmpty,
      failures: failures,
    );
  }

  VerificationResult _verifyAssertion(Game game, Assertion assertion) {
    final failures = <String>[];

    // Resource-placement assertions (SPEC/game/resource-terrain-region-rules.md)
    if (assertion.region != null &&
        assertion.resource != null &&
        assertion.province == null &&
        assertion.player == null) {
      final bad = _tilesInRegionWithResource(
        game.worldState.resourceByTileKey,
        assertion.region!,
        assertion.resource!,
      );
      if (bad.isNotEmpty) {
        failures.add(
          'Region ${assertion.region}: expected no resource "${assertion.resource}", '
          'but found on ${bad.length} tile(s), e.g. ${bad.first}',
        );
      }
    } else if (assertion.everyTileResourceAllowedInRegion == true) {
      final ruleFailures = _verifyEveryTileResourceAllowedInRegion(
        game.worldState.resourceByTileKey,
        assertion.region,
      );
      failures.addAll(ruleFailures);
    } else if (assertion.region != null &&
        assertion.maxBothFraction != null &&
        assertion.province == null &&
        assertion.player == null) {
      final result = _checkResourcePlacementCap(
        game.worldState.resourceByTileKey,
        assertion.region!,
        assertion.maxBothFraction!,
      );
      if (!result.passed) {
        failures.add(result.message);
      }
    }

    // Faction count assertions (SPEC/game/factions.md)
    if (assertion.greatPowerCount != null ||
        assertion.minorNationCount != null ||
        assertion.tribeCount != null) {
      if (assertion.greatPowerCount != null &&
          game.players.length != assertion.greatPowerCount!) {
        failures.add(
          'Great Power count: expected ${assertion.greatPowerCount}, got ${game.players.length}',
        );
      }
      if (assertion.minorNationCount != null &&
          game.minorNations.length != assertion.minorNationCount!) {
        failures.add(
          'Minor Nation count: expected ${assertion.minorNationCount}, got ${game.minorNations.length}',
        );
      }
      if (assertion.tribeCount != null &&
          game.tribes.length != assertion.tribeCount!) {
        failures.add(
          'Tribe count: expected ${assertion.tribeCount}, got ${game.tribes.length}',
        );
      }
    }

    // Province-based assertions
    if (assertion.province != null) {
      final province =
          _findProvince(game, assertion.region, assertion.province!);
      if (province == null) {
        final regionStr =
            assertion.region != null ? '${assertion.region}:' : '';
        failures.add('Province "$regionStr${assertion.province}" not found');
        return VerificationResult(passed: false, failures: failures);
      }

      // Check owner
      if (assertion.owner != null) {
        if (province.ownerId != assertion.owner) {
          failures.add(
            'Province ${assertion.province}: expected owner "${assertion.owner}", got "${province.ownerId}"',
          );
        }
      }

      // Check notOwner (negative assertion)
      if (assertion.notOwner != null) {
        if (province.ownerId == assertion.notOwner) {
          failures.add(
            'Province ${assertion.province}: expected not owned by "${assertion.notOwner}", but it is',
          );
        }
      }

      // Province display name (SPEC/game/naming.md)
      if (assertion.provinceDisplayName != null) {
        final actual = province.displayName ?? '';
        if (actual != assertion.provinceDisplayName) {
          failures.add(
            'Province ${assertion.province}: expected displayName "${assertion.provinceDisplayName}", got "$actual"',
          );
        }
      }

      // Check unit count
      if (assertion.unitCount != null ||
          assertion.hasUnit != null ||
          assertion.hasPlayerUnits != null) {
        final units =
            _getUnitsInProvince(game, assertion.region, assertion.province!);

        if (assertion.unitCount != null) {
          final matchResult = _matchCount(
            units.length,
            assertion.unitCount!,
            assertion.matchType,
            assertion.matchMin,
            assertion.matchMax,
          );
          if (!matchResult.passed) {
            failures.add(
              'Province ${assertion.province}: ${matchResult.message}',
            );
          }
        }

        // Check specific unit
        if (assertion.hasUnit != null) {
          final hasUnit = units.any((u) => u.id == assertion.hasUnit);
          if (!hasUnit) {
            failures.add(
              'Province ${assertion.province}: expected unit "${assertion.hasUnit}" not found',
            );
          }
        }

        // Check player units
        if (assertion.hasPlayerUnits != null) {
          final hasPlayerUnits =
              units.any((u) => u.ownerId == assertion.hasPlayerUnits);
          if (!hasPlayerUnits) {
            failures.add(
              'Province ${assertion.province}: no units found for player "${assertion.hasPlayerUnits}"',
            );
          }
        }
      }
    }

    // Capital assertions (player/minor/tribe faction id + capitalProvinceId / capitalTileKey)
    if (assertion.player != null &&
        (assertion.capitalProvinceId != null ||
            assertion.capitalTileKey != null)) {
      final factionId = assertion.player!;
      String? actualProvinceId;
      String? actualTileKey;
      if (game.players.any((p) => p.id == factionId)) {
        final p = game.players.firstWhere((x) => x.id == factionId);
        actualProvinceId = p.capitalProvinceId;
        actualTileKey = p.capitalTile?.toTileKey();
      } else if (game.minorNations.any((m) => m.id == factionId)) {
        final m = game.minorNations.firstWhere((x) => x.id == factionId);
        actualProvinceId = m.capitalProvinceId;
        actualTileKey = m.capitalTile?.toTileKey();
      } else if (game.tribes.any((t) => t.id == factionId)) {
        final t = game.tribes.firstWhere((x) => x.id == factionId);
        actualProvinceId = t.capitalProvinceId;
        actualTileKey = t.capitalTile?.toTileKey();
      } else {
        failures.add(
            'Faction "$factionId" not found (players, minorNations, tribes)');
      }
      if (actualProvinceId != null || actualTileKey != null) {
        if (assertion.capitalProvinceId != null &&
            actualProvinceId != assertion.capitalProvinceId) {
          failures.add(
            'Faction $factionId: expected capitalProvinceId "${assertion.capitalProvinceId}", got "$actualProvinceId"',
          );
        }
        if (assertion.capitalTileKey != null &&
            actualTileKey != assertion.capitalTileKey) {
          failures.add(
            'Faction $factionId: expected capitalTileKey "${assertion.capitalTileKey}", got "$actualTileKey"',
          );
        }
      } else if (assertion.capitalProvinceId != null ||
          assertion.capitalTileKey != null) {
        failures.add(
          'Faction $factionId: expected capital but capitalProvinceId/capitalTile are null',
        );
      }
    }

    // Player-based assertions (stockpile, treasury, diplomacy) — only for game.players
    if (assertion.player != null &&
        (assertion.stockpile != null || assertion.treasury != null)) {
      final player = game.players.firstWhere(
        (p) => p.id == assertion.player,
        orElse: () => throw StateError('Player ${assertion.player} not found'),
      );

      if (assertion.stockpile != null) {
        // Sum all commodity quantities in stockpile
        final totalStockpile =
            player.stockpile.quantities.values.fold<int>(0, (a, b) => a + b);
        final matchResult = _matchCount(
          totalStockpile,
          assertion.stockpile!,
          assertion.matchType,
          assertion.matchMin,
          assertion.matchMax,
        );
        if (!matchResult.passed) {
          failures.add(
            'Player ${assertion.player} stockpile: ${matchResult.message}',
          );
        }
      }

      if (assertion.commodity != null && assertion.stockpileCommodity != null) {
        final quantity = player.stockpile.quantityOf(assertion.commodity!);
        final matchResult = _matchCount(
          quantity,
          assertion.stockpileCommodity!,
          assertion.matchType,
          assertion.matchMin,
          assertion.matchMax,
        );
        if (!matchResult.passed) {
          failures.add(
            'Player ${assertion.player} commodity ${assertion.commodity}: ${matchResult.message}',
          );
        }
      }

      if (assertion.treasury != null) {
        final matchResult = _matchCount(
          player.treasury,
          assertion.treasury!,
          assertion.matchType,
          assertion.matchMin,
          assertion.matchMax,
        );
        if (!matchResult.passed) {
          failures.add(
            'Player ${assertion.player} treasury: ${matchResult.message}',
          );
        }
      }

      // Worker pool assertions (SPEC/game/workers-and-population.md)
      if (assertion.workerPeasants != null) {
        if (player.workerPool.peasants != assertion.workerPeasants) {
          failures.add(
            'Player ${assertion.player} workerPeasants: expected ${assertion.workerPeasants}, got ${player.workerPool.peasants}',
          );
        }
      }
      if (assertion.workerApprentices != null) {
        if (player.workerPool.apprentices != assertion.workerApprentices) {
          failures.add(
            'Player ${assertion.player} workerApprentices: expected ${assertion.workerApprentices}, got ${player.workerPool.apprentices}',
          );
        }
      }
      if (assertion.workerJourneymen != null) {
        if (player.workerPool.journeymen != assertion.workerJourneymen) {
          failures.add(
            'Player ${assertion.player} workerJourneymen: expected ${assertion.workerJourneymen}, got ${player.workerPool.journeymen}',
          );
        }
      }
      if (assertion.workerMasters != null) {
        if (player.workerPool.masters != assertion.workerMasters) {
          failures.add(
            'Player ${assertion.player} workerMasters: expected ${assertion.workerMasters}, got ${player.workerPool.masters}',
          );
        }
      }

      // Per-commodity stockpile (SPEC/game/workers-and-population.md)
      if (assertion.commodity != null && assertion.stockpileCommodity != null) {
        final actual = player.stockpile.quantityOf(assertion.commodity!);
        final expected = assertion.stockpileCommodity!;
        if (actual != expected) {
          failures.add(
            'Player ${assertion.player} stockpile ${assertion.commodity}: expected $expected, got $actual',
          );
        }
      }

      // Capital assertion (SPEC/game/capital-choice-phase.md): player's capital province
      if (assertion.capitalProvince != null) {
        final expected = assertion.capitalProvince!;
        final actual = player.capitalProvinceId;
        if (actual != expected) {
          failures.add(
            'Player ${assertion.player} capital: expected "$expected", got "${actual ?? "null"}"',
          );
        }
      }

      // Diplomacy relation assertions between [player] and [relationWith]
      if (assertion.relationWith != null) {
        final rel =
            _findRelation(game, assertion.player!, assertion.relationWith!);
        if (rel == null) {
          failures.add(
            'Relation between ${assertion.player} and ${assertion.relationWith} not found',
          );
        } else {
          if (assertion.relationState != null &&
              rel.state.name != assertion.relationState) {
            failures.add(
              'Relation ${assertion.player}-${assertion.relationWith}: '
              'expected state "${assertion.relationState}", got "${rel.state.name}"',
            );
          }
          if (assertion.relationScore != null &&
              rel.score != assertion.relationScore) {
            failures.add(
              'Relation ${assertion.player}-${assertion.relationWith}: '
              'expected score ${assertion.relationScore}, got ${rel.score}',
            );
          }
          if (assertion.relationLevel != null &&
              rel.level.name != assertion.relationLevel) {
            failures.add(
              'Relation ${assertion.player}-${assertion.relationWith}: '
              'expected level "${assertion.relationLevel}", got "${rel.level.name}"',
            );
          }
          if (assertion.relationSinceTurn != null &&
              rel.sinceTurn != assertion.relationSinceTurn) {
            failures.add(
              'Relation ${assertion.player}-${assertion.relationWith}: '
              'expected sinceTurn ${assertion.relationSinceTurn}, got ${rel.sinceTurn}',
            );
          }
          if (assertion.relationLastInteractionTurn != null &&
              rel.lastInteractionTurn !=
                  assertion.relationLastInteractionTurn) {
            failures.add(
              'Relation ${assertion.player}-${assertion.relationWith}: '
              'expected lastInteractionTurn ${assertion.relationLastInteractionTurn}, '
              'got ${rel.lastInteractionTurn}',
            );
          }
        }

        // Overture stage (GP–Minor/Tribe) between [player] and [relationWith]
        if (assertion.overtureStage != null) {
          final overture =
              _findOverture(game, assertion.player!, assertion.relationWith!);
          if (overture == null) {
            failures.add(
              'Overture between ${assertion.player} and ${assertion.relationWith} not found',
            );
          } else if (overture.stage.name != assertion.overtureStage) {
            failures.add(
              'Overture ${assertion.player}-${assertion.relationWith}: '
              'expected stage "${assertion.overtureStage}", got "${overture.stage.name}"',
            );
          }
        }
      }
    }

    // Fog/exploration assertions (SPEC/game/fog-and-exploration.md)
    if (assertion.player != null &&
        (assertion.tileVisibility != null ||
            assertion.tileProspected != null) &&
        assertion.tileKey != null) {
      final playerId = assertion.player!;
      final tileKey = assertion.tileKey!;
      final visByTile = game.worldState.playerVisibilityByTile[playerId];
      if (assertion.tileVisibility != null) {
        final expected = assertion.tileVisibility!;
        final actual = visByTile?[tileKey];
        if (actual != expected) {
          failures.add(
            'Player $playerId tile $tileKey visibility: expected "$expected", got "${actual ?? "absent/unknown"}"',
          );
        }
      }
      if (assertion.tileProspected != null) {
        final prospected = game.worldState.playerProspectedTiles[playerId];
        final isProspected = prospected?.contains(tileKey) ?? false;
        if (isProspected != assertion.tileProspected!) {
          failures.add(
            'Player $playerId tile $tileKey prospected: expected ${assertion.tileProspected}, got $isProspected',
          );
        }
      }
    }

    // Improvement naming assertions (SPEC/game/extraction-and-improvements.md)
    if (assertion.tileImprovementName != null && assertion.tileKey != null) {
      final tileKey = assertion.tileKey!;
      final expectedName = assertion.tileImprovementName!;
      final actualName = _improvementNameForTile(game, tileKey);
      if (actualName != expectedName) {
        failures.add(
          'Tile $tileKey improvementName: expected "$expectedName", got "$actualName"',
        );
      }
    }

    // Road / transport-level assertions (SPEC/game/capital-and-connectivity.md, SPEC/program/development-resolution.md)
    if (assertion.tileRoadLevel != null && assertion.tileKey != null) {
      final tileKey = assertion.tileKey!;
      final expectedLevel = assertion.tileRoadLevel!;
      final actualLevel = game.worldState.tileState.roadLevel(tileKey);
      if (actualLevel != expectedLevel) {
        failures.add(
          'Tile $tileKey roadLevel: expected $expectedLevel, got $actualLevel',
        );
      }
    }

    // Improvement level assertion (SPEC/game/extraction-and-improvements.md). With [tileKey]: expected improvement level 0-4.
    if (assertion.tileImprovementLevel != null && assertion.tileKey != null) {
      final tileKey = assertion.tileKey!;
      final expectedLevel = assertion.tileImprovementLevel!;
      final actualLevel = game.worldState.tileState.improvementLevel(tileKey);
      if (actualLevel != expectedLevel) {
        failures.add(
          'Tile $tileKey improvementLevel: expected $expectedLevel, got $actualLevel',
        );
      }
    }

    // Leader assertion (SPEC/game/leader-bonuses.md): player's leaderKey
    if (assertion.player != null && assertion.leaderKey != null) {
      try {
        final player = game.players.firstWhere((p) => p.id == assertion.player);
        final expected = assertion.leaderKey!;
        final actual = player.leaderKey;
        if (actual != expected) {
          failures.add(
            'Player ${assertion.player} leaderKey: expected "$expected", got "${actual ?? "null"}"',
          );
        }
      } on StateError {
        failures.add(
            'Player ${assertion.player} not found for leaderKey assertion');
      }
    }

    // Research-state assertion (SPEC/game/research-state.md): player's techUnlocked must contain listed tech ids
    if (assertion.player != null &&
        assertion.techUnlocked != null &&
        assertion.techUnlocked!.isNotEmpty) {
      try {
        final player = game.players.firstWhere((p) => p.id == assertion.player);
        final unlocked = player.techUnlocked ?? const <String, bool>{};
        for (final techId in assertion.techUnlocked!) {
          if (unlocked[techId] != true) {
            failures.add(
              'Player ${assertion.player} techUnlocked: expected "$techId" to be true, got ${unlocked[techId]}',
            );
          }
        }
      } on StateError {
        failures.add(
          'Player ${assertion.player} not found for techUnlocked assertion',
        );
      }
    }

    // General count assertion (SPEC/game/military-generals.md): player must have expected number of generals
    if (assertion.player != null && assertion.generalCount != null) {
      final count = game.generals.where((g) => g.ownerId == assertion.player).length;
      if (count != assertion.generalCount) {
        failures.add(
          'Player ${assertion.player} generalCount: expected ${assertion.generalCount}, got $count',
        );
      }
    }

    // Faction effective military level (SPEC/game/factions.md): Minor or Tribe [player] must have expected effectiveMilitaryLevel.
    if (assertion.player != null && assertion.effectiveMilitaryLevel != null) {
      final factionId = assertion.player!;
      final expected = assertion.effectiveMilitaryLevel!;
      MinorNation? minor;
      for (final m in game.minorNations) {
        if (m.id == factionId) {
          minor = m;
          break;
        }
      }
      Tribe? tribe;
      if (minor == null) {
        for (final t in game.tribes) {
          if (t.id == factionId) {
            tribe = t;
            break;
          }
        }
      }
      if (minor != null) {
        if (minor.effectiveMilitaryLevel != expected) {
          failures.add(
            'Minor $factionId effectiveMilitaryLevel: expected $expected, got ${minor.effectiveMilitaryLevel}',
          );
        }
      } else if (tribe != null) {
        if (tribe.effectiveMilitaryLevel != expected) {
          failures.add(
            'Tribe $factionId effectiveMilitaryLevel: expected $expected, got ${tribe.effectiveMilitaryLevel}',
          );
        }
      } else {
        failures.add(
          'Faction $factionId not found (effectiveMilitaryLevel applies to Minor or Tribe only)',
        );
      }
    }

    return VerificationResult(
      passed: failures.isEmpty,
      failures: failures,
    );
  }

  /// Tile key format: regionId|provinceId|x|y. Returns region id or empty if invalid.
  static String _regionFromTileKey(String tileKey) {
    final parts = tileKey.split('|');
    return parts.isNotEmpty ? parts[0] : '';
  }

  /// Tile keys in [region] that have [resource].
  List<String> _tilesInRegionWithResource(
    Map<String, String> resourceByTileKey,
    String region,
    String resource,
  ) {
    final list = <String>[];
    for (final entry in resourceByTileKey.entries) {
      if (_regionFromTileKey(entry.key) == region && entry.value == resource) {
        list.add(entry.key);
      }
    }
    return list;
  }

  List<String> _verifyEveryTileResourceAllowedInRegion(
    Map<String, String> resourceByTileKey,
    String? scopeRegion,
  ) {
    final failures = <String>[];
    final rules = ResourceRules.defaultRules;
    for (final entry in resourceByTileKey.entries) {
      final regionId = _regionFromTileKey(entry.key);
      if (regionId.isEmpty) continue;
      if (scopeRegion != null && regionId != scopeRegion) continue;
      final resourceId = entry.value;
      Resource resource;
      try {
        resource = Resource.values.byName(resourceId);
      } catch (_) {
        failures.add('Tile ${entry.key}: unknown resource "$resourceId"');
        continue;
      }
      if (!rules.isAllowedInRegion(resource, regionId)) {
        failures.add(
          'Tile ${entry.key}: resource "$resourceId" not allowed in region "$regionId"',
        );
      }
    }
    return failures;
  }

  _CapResult _checkResourcePlacementCap(
    Map<String, String> resourceByTileKey,
    String region,
    double maxBothFraction,
  ) {
    final rules = ResourceRules.defaultRules;
    var bothCount = 0;
    var totalCount = 0;
    for (final entry in resourceByTileKey.entries) {
      if (_regionFromTileKey(entry.key) != region) continue;
      final resourceId = entry.value;
      if (resourceId.isEmpty) continue;
      totalCount++;
      try {
        final resource = Resource.values.byName(resourceId);
        if (rules.regionRule[resource] == ResourceRegionRule.both) {
          bothCount++;
        }
      } catch (_) {
        // Unknown resource: count as non-both
      }
    }
    if (totalCount == 0) {
      return _CapResult(passed: true, message: '');
    }
    final fraction = bothCount / totalCount;
    final passed = fraction <= maxBothFraction;
    return _CapResult(
      passed: passed,
      message: passed
          ? ''
          : 'Region $region: both-fraction $fraction (${bothCount}/$totalCount) '
              'exceeds maxBothFraction $maxBothFraction',
    );
  }

  Province? _findProvince(Game game, String? regionId, String provinceId) {
    // If provinceId contains '|', it includes the region prefix (e.g., "oldWorld|p1")
    // The province.id stored in game is already in format "regionId|provinceId"
    // So we just search by the full ID

    // If region is specified, search only that region
    if (regionId != null) {
      final regionData = _getRegionData(game, regionId);
      if (regionData != null) {
        for (final province in regionData.provinces) {
          if (province.id == provinceId) return province;
        }
      }
      return null;
    }

    // If no region specified, search both oldWorld and newWorld by full ID
    // The province.id includes region prefix (e.g., "oldWorld|p1")
    for (final province in game.worldState.oldWorld.provinces) {
      if (province.id == provinceId) return province;
    }
    for (final province in game.worldState.newWorld.provinces) {
      if (province.id == provinceId) return province;
    }
    return null;
  }

  RegionData? _getRegionData(Game game, String regionId) {
    if (regionId == 'oldWorld') return game.worldState.oldWorld;
    if (regionId == 'newWorld') return game.worldState.newWorld;
    return null;
  }

  List<Unit> _getUnitsInProvince(
      Game game, String? regionId, String provinceId) {
    final units = <Unit>[];

    // If region is specified, only check that region's units
    if (regionId != null) {
      final regionData = _getRegionData(game, regionId);
      if (regionData != null) {
        for (final unit in regionData.units) {
          if (unit.provinceId == provinceId) {
            units.add(unit);
          }
        }
      }
      return units;
    }

    // If no region, check both oldWorld and newWorld units
    for (final unit in game.worldState.oldWorld.units) {
      if (unit.provinceId == provinceId) {
        units.add(unit);
      }
    }

    for (final unit in game.worldState.newWorld.units) {
      if (unit.provinceId == provinceId) {
        units.add(unit);
      }
    }

    return units;
  }

  _CountMatchResult _matchCount(
    int actual,
    int expected,
    MatchType matchType,
    int? matchMin,
    int? matchMax,
  ) {
    bool passed;
    String message;

    switch (matchType) {
      case MatchType.exact:
        passed = actual == expected;
        message = passed ? 'ok' : 'expected $expected, got $actual';
        break;
      case MatchType.range:
        final min = matchMin ?? 0;
        final max = matchMax ?? expected;
        passed = actual >= min && actual <= max;
        message = passed ? 'ok' : 'expected $min-$max, got $actual';
        break;
      case MatchType.atLeast:
        passed = actual >= expected;
        message = passed ? 'ok' : 'expected >=$expected, got $actual';
        break;
      case MatchType.atMost:
        passed = actual <= expected;
        message = passed ? 'ok' : 'expected <=$expected, got $actual';
        break;
    }

    return _CountMatchResult(passed: passed, message: message);
  }

  /// Diplomacy helpers
  DiplomacyRelation? _findRelation(
    Game game,
    String factionId1,
    String factionId2,
  ) {
    String _pairKey(String a, String b) =>
        a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
    final key = _pairKey(factionId1, factionId2);
    for (final r in game.diplomacyRelations) {
      if (_pairKey(r.factionId1, r.factionId2) == key) return r;
    }
    return null;
  }

  OvertureState? _findOverture(
    Game game,
    String gpId,
    String targetId,
  ) {
    for (final o in game.overtureStates) {
      if (o.gpId == gpId && o.targetId == targetId) return o;
    }
    return null;
  }
}

/// Derives the improvement display name for a tile based on its resource id.
/// Mirrors SPEC/game/extraction-and-improvements.md (Improvement Naming table).
String _improvementNameForTile(Game game, String tileKey) {
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  final normalized = resourceId ?? '';
  switch (normalized) {
    case 'grain':
      return 'Farm';
    case 'meat':
    case 'horses':
      return 'Ranch';
    case 'wool':
      return 'Pasture';
    case 'timber':
      return 'Lumber camp';
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return 'Plantation';
    case 'furs':
      return 'Fur post';
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return 'Mine';
    default:
      return 'Improvement';
  }
}

class _CountMatchResult {
  const _CountMatchResult({required this.passed, required this.message});
  final bool passed;
  final String message;
}

class _CapResult {
  const _CapResult({required this.passed, required this.message});
  final bool passed;
  final String message;
}
