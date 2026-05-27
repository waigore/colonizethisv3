// Turn-start news modal. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Prior-turn summary dialog; [newTurnNumber] is current turn after resolution.
class TurnNewsDialog extends StatelessWidget {
  const TurnNewsDialog({
    super.key,
    required this.game,
    required this.digest,
    required this.newTurnNumber,
  });

  static const screenId = UiScreenIds.turnNewsDialog;

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleLarge ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final mutedStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.muted);
    final isEmpty = digest.lines.isEmpty;
    final lines = isEmpty
        ? const <String>[]
        : digest.lines.map((e) => formatTurnNewsLine(l10n, game, e)).toList();

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.turnNews_title(newTurnNumber), style: titleStyle),
          const SizedBox(height: 12),
          if (isEmpty)
            Text(l10n.turnNews_empty, style: mutedStyle)
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lines.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(lines[i], style: bodyStyle),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: CtNinePatchButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.turnNews_close),
            ),
          ),
        ],
      ),
    );
  }
}

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
