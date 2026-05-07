// Turn-start news modal. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// Prior-turn summary dialog; [newTurnNumber] is current turn after resolution.
class TurnNewsDialog extends StatelessWidget {
  const TurnNewsDialog({
    super.key,
    required this.game,
    required this.digest,
    required this.newTurnNumber,
  });

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final lines = digest.lines.isEmpty
        ? <String>[l10n.turnNews_empty]
        : digest.lines.map((e) => formatTurnNewsLine(l10n, game, e)).toList();

    return AlertDialog(
      title: Text(l10n.turnNews_title(newTurnNumber)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.turnNews_close),
        ),
      ],
    );
  }
}

String _factionLabel(Game g, String id) {
  for (final p in g.players) {
    if (p.id == id) return p.displayName;
  }
  for (final m in g.minorNations) {
    if (m.id == id) return m.displayName ?? m.id;
  }
  for (final t in g.tribes) {
    if (t.id == id) return t.displayName ?? t.id;
  }
  return id;
}

String _provinceLabel(Game g, String fullProvinceId) {
  for (final r in [g.worldState.oldWorld, g.worldState.newWorld]) {
    for (final p in r.provinces) {
      final full = p.id.contains('|')
          ? p.id
          : ProvinceId.full(p.regionId, p.id);
      if (full == fullProvinceId) {
        return p.displayName ?? fullProvinceId;
      }
    }
  }
  return fullProvinceId;
}

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
