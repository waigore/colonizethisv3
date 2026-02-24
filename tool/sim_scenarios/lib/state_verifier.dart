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
      if (atTurn != null && assertion.turn != null && assertion.turn != atTurn) {
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
    if (assertion.region != null && assertion.resource != null &&
        assertion.province == null && assertion.player == null) {
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
    } else if (assertion.region != null && assertion.maxBothFraction != null &&
        assertion.province == null && assertion.player == null) {
      final result = _checkResourcePlacementCap(
        game.worldState.resourceByTileKey,
        assertion.region!,
        assertion.maxBothFraction!,
      );
      if (!result.passed) {
        failures.add(result.message);
      }
    }

    // Province-based assertions
    if (assertion.province != null) {
      final province = _findProvince(game, assertion.region, assertion.province!);
      if (province == null) {
        final regionStr = assertion.region != null ? '${assertion.region}:' : '';
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

      // Check unit count
      if (assertion.unitCount != null || assertion.hasUnit != null || assertion.hasPlayerUnits != null) {
        final units = _getUnitsInProvince(game, assertion.region, assertion.province!);
        
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
          final hasPlayerUnits = units.any((u) => u.ownerId == assertion.hasPlayerUnits);
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
        (assertion.capitalProvinceId != null || assertion.capitalTileKey != null)) {
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
        failures.add('Faction "$factionId" not found (players, minorNations, tribes)');
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
      } else if (assertion.capitalProvinceId != null || assertion.capitalTileKey != null) {
        failures.add(
          'Faction $factionId: expected capital but capitalProvinceId/capitalTile are null',
        );
      }
    }

    // Player-based assertions (stockpile, treasury) — only for game.players
    if (assertion.player != null &&
        (assertion.stockpile != null || assertion.treasury != null)) {
      final player = game.players.firstWhere(
        (p) => p.id == assertion.player,
        orElse: () => throw StateError('Player ${assertion.player} not found'),
      );

      if (assertion.stockpile != null) {
        // Sum all commodity quantities in stockpile
        final totalStockpile = player.stockpile.quantities.values.fold<int>(0, (a, b) => a + b);
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

  List<Unit> _getUnitsInProvince(Game game, String? regionId, String provinceId) {
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
        message = passed 
          ? 'ok' 
          : 'expected $expected, got $actual';
        break;
      case MatchType.range:
        final min = matchMin ?? 0;
        final max = matchMax ?? expected;
        passed = actual >= min && actual <= max;
        message = passed 
          ? 'ok' 
          : 'expected $min-$max, got $actual';
        break;
      case MatchType.atLeast:
        passed = actual >= expected;
        message = passed 
          ? 'ok' 
          : 'expected >=$expected, got $actual';
        break;
      case MatchType.atMost:
        passed = actual <= expected;
        message = passed 
          ? 'ok' 
          : 'expected <=$expected, got $actual';
        break;
    }

    return _CountMatchResult(passed: passed, message: message);
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
