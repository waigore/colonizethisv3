/// Display-only Upgrade town workshop payoff gist. Refs #4747.
library;

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/widgets.dart';

import 'upgrade_town_payoff_gist_line.dart';

export 'upgrade_town_payoff_gist_line.dart';

const int _kUpgradeTownGoodsNameCap = 2;

/// Localized after-this-work gist for the next town-workshop step.
String upgradeTownPayoffGistLine({
  required AppLocalizations l10n,
  required int fromLevel,
  required int turns,
  String goodsClause = '',
}) {
  return switch (fromLevel) {
    1 => l10n.provinceOverlay_upgradeTownPayoffGistStart(goodsClause, turns),
    2 => l10n.provinceOverlay_upgradeTownPayoffGistPause(goodsClause, turns),
    _ => l10n.provinceOverlay_upgradeTownPayoffGistResume(goodsClause, turns),
  };
}

/// Formats at most two `+N Name` quantities; empty when [bonus] is empty.
String upgradeTownPayoffGoodsClause(
  AppLocalizations l10n,
  Map<String, int> bonus,
) {
  if (bonus.isEmpty) return '';
  final ids = bonus.keys.toList()..sort();
  final parts = <String>[];
  for (final id in ids.take(_kUpgradeTownGoodsNameCap)) {
    final qty = bonus[id] ?? 0;
    if (qty <= 0) continue;
    parts.add('+$qty ${commodityDisplayName(l10n, id)}');
  }
  if (parts.isEmpty) return '';
  return ' (${parts.join(', ')})';
}

/// Resolves gist when Upgrade town is enabled for a human-owned town tile.
String? upgradeTownPayoffGistForTile({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String tileKey,
  required bool enabled,
  bool canMutateViaUi = true,
  GameMapData? mapData,
  Map<String, int>? currentBonus,
  Map<String, int>? nextBonus,
}) {
  if (!enabled || !canMutateViaUi) return null;
  final provinceId = Unit.provinceIdFromTileKey(tileKey);
  if (provinceId == null) return null;
  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null || province.ownerId != humanPlayerId) return null;
  final level = province.townDevelopmentLevel;
  if (level < kTownDevelopmentLevelMin || level >= kTownDevelopmentLevelMax) {
    return null;
  }
  var current = currentBonus ?? const <String, int>{};
  var next = nextBonus ?? const <String, int>{};
  if (currentBonus == null && nextBonus == null && mapData != null) {
    final pair = previewTownManufacturingBonusCurrentAndNextByProvince(
      game: game,
      topology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
    );
    current = pair.currentByProvinceId[provinceId] ?? const {};
    next = pair.nextByProvinceId[provinceId] ?? const {};
  }
  final goods = upgradeTownPayoffGoodsClause(l10n, level == 2 ? current : next);
  return upgradeTownPayoffGistLine(
    l10n: l10n,
    fromLevel: level,
    turns: totalTurnsForWork(kWorkTargetUpgradeTown),
    goodsClause: goods,
  );
}

/// Pending `upgrade_town` gist widgets, or empty when hidden.
List<Widget> upgradeTownPayoffPendingGistChildren({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required WorkOrder pendingWork,
  required bool readOnly,
  GameMapData? mapData,
}) {
  if (pendingWork.target != kWorkTargetUpgradeTown) return const [];
  final gist = upgradeTownPayoffGistForTile(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    tileKey: pendingWork.targetTileKey,
    enabled: true,
    canMutateViaUi: !readOnly,
    mapData: mapData,
  );
  if (gist == null) return const [];
  return [UpgradeTownPayoffGistLine(text: gist)];
}

/// Builder-shortcut Upgrade town gist, or null when the tile key is unset.
String? upgradeTownShortcutGist({
  required AppLocalizations l10n,
  required Game game,
  required String humanPlayerId,
  required String? tileKey,
  required bool readOnly,
  GameMapData? mapData,
}) {
  if (tileKey == null || tileKey.isEmpty) return null;
  return upgradeTownPayoffGistForTile(
    l10n: l10n,
    game: game,
    humanPlayerId: humanPlayerId,
    tileKey: tileKey,
    enabled: true,
    canMutateViaUi: !readOnly,
    mapData: mapData,
  );
}
