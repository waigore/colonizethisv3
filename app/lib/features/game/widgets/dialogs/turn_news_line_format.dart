// Gazette line formatting for DLG50001 Turn News.
// SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

String _factionLabel(Game g, String id) => g.factionDisplayNameById(id) ?? id;

String _provinceLabel(Game g, String fullProvinceId) =>
    g.worldState.tryGetProvince(fullProvinceId)?.displayName ?? fullProvinceId;

String _seaZoneLabel(Game g, String seaZoneId) {
  return g.worldState.seaZoneDisplayNameById[seaZoneId] ?? seaZoneId;
}

String _overtureStageLabel(AppLocalizations l10n, OvertureStage s) {
  return switch (s) {
    OvertureStage.tradeConsulate => l10n.turnNews_stage_tradeConsulate,
    OvertureStage.embassy => l10n.turnNews_stage_embassy,
    OvertureStage.nap => l10n.turnNews_stage_nap,
    OvertureStage.joinEmpire => l10n.turnNews_stage_joinEmpire,
    OvertureStage.none => s.name,
  };
}

/// Formats one digest line using [game] for display names.
String formatTurnNewsLine(AppLocalizations l10n, Game game, TurnNewsLine line) {
  return switch (line) {
    TurnNewsProvinceCapturedLine(
      :final provinceId,
      :final previousOwnerId,
      :final newOwnerId,
    ) =>
      l10n.turnNews_capture(
        _provinceLabel(game, provinceId),
        _factionLabel(game, previousOwnerId),
        _factionLabel(game, newOwnerId),
      ),
    TurnNewsDiplomacyLine(:final factionIdA, :final factionIdB, :final kind) =>
      kind == TurnNewsDiplomacyKind.war
          ? l10n.turnNews_war(
              _factionLabel(game, factionIdA),
              _factionLabel(game, factionIdB),
            )
          : l10n.turnNews_peace(
              _factionLabel(game, factionIdA),
              _factionLabel(game, factionIdB),
            ),
    TurnNewsOvertureAdvancedLine(
      :final offererGpId,
      :final targetFactionId,
      :final newStage,
    ) =>
      l10n.turnNews_overture(
        _factionLabel(game, offererGpId),
        _factionLabel(game, targetFactionId),
        _overtureStageLabel(l10n, newStage),
      ),
    TurnNewsProvinceDiscoveredLine(:final provinceId) =>
      l10n.turnNews_provinceDiscovered(_provinceLabel(game, provinceId)),
    TurnNewsSeaZoneFleetLine(:final seaZoneId) => l10n.turnNews_seaDiscovered(
      _seaZoneLabel(game, seaZoneId),
    ),
  };
}
