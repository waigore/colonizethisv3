// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

GameSetupConfig gameSetupFromObserverCli({
  String? configJsonPath,
  int? seedOverride,
}) {
  var config = GameSetupConfig.defaultConfig;
  if (configJsonPath != null && configJsonPath.isNotEmpty) {
    final f = File(configJsonPath);
    if (!f.existsSync()) {
      throw FileSystemException('config file not found', configJsonPath);
    }
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    List<String> selectedIds = config.selectedGreatPowerIds;
    final jsonSelected = json['selectedGreatPowerIds'];
    if (jsonSelected is List) {
      selectedIds = jsonSelected.map((e) => e.toString()).toList();
    }
    Map<String, String> leaderVariantByGpId = config.leaderVariantByGpId;
    final jsonLeader = json['leaderVariantByGpId'];
    if (jsonLeader is Map) {
      leaderVariantByGpId = Map<String, String>.from(
        jsonLeader.map(
          (dynamic k, dynamic v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }
    config = GameSetupConfig(
      selectedGreatPowerIds: selectedIds,
      leaderVariantByGpId: leaderVariantByGpId,
      continentCount:
          (json['continentCount'] as num?)?.toInt() ?? config.continentCount,
      minorNationCount:
          (json['minorNationCount'] as num?)?.toInt() ??
          config.minorNationCount,
      tribeCount: (json['tribeCount'] as num?)?.toInt() ?? config.tribeCount,
      numProvincesOldWorld:
          (json['numProvincesOldWorld'] as num?)?.toInt() ??
          config.numProvincesOldWorld,
      numProvincesNewWorld:
          (json['numProvincesNewWorld'] as num?)?.toInt() ??
          config.numProvincesNewWorld,
      minProvincesPerMinor:
          (json['minProvincesPerMinor'] as num?)?.toInt() ??
          config.minProvincesPerMinor,
      seed: (json['seed'] as num?)?.toInt() ?? config.seed,
      initTownRoadWiringRegionIds:
          json['initTownRoadWiringRegionIds'] is List<dynamic>
          ? (json['initTownRoadWiringRegionIds'] as List<dynamic>)
                .map((e) => e.toString())
                .toSet()
          : config.initTownRoadWiringRegionIds,
    );
  }

  if (seedOverride != null) {
    config = GameSetupConfig(
      selectedGreatPowerIds: config.selectedGreatPowerIds,
      leaderVariantByGpId: config.leaderVariantByGpId,
      continentCount: config.continentCount,
      minorNationCount: config.minorNationCount,
      tribeCount: config.tribeCount,
      numProvincesOldWorld: config.numProvincesOldWorld,
      numProvincesNewWorld: config.numProvincesNewWorld,
      minProvincesPerMinor: config.minProvincesPerMinor,
      seed: seedOverride,
      preferredInitialMapZoomMultiplier:
          config.preferredInitialMapZoomMultiplier,
      startingResources: config.startingResources,
      initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
    );
  }

  return config;
}
