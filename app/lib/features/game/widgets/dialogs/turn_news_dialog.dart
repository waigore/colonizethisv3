// Turn-start news modal. SPEC/ui/turn-news-dialog.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../../../../widgets/turn_news_court_snapshot.dart';

/// Prior-turn summary dialog; [newTurnNumber] is current turn after resolution.
class TurnNewsDialog extends StatelessWidget {
  const TurnNewsDialog({
    super.key,
    required this.game,
    required this.digest,
    required this.newTurnNumber,
    this.spyReportCount = 0,
    this.courtSnapshot = TurnNewsCourtSnapshot.empty,
    this.onOpenIntelligence,
    this.onOpenEvents,
  });

  static const screenId = UiScreenIds.turnNewsDialog;
  static const courtBlockKey = ValueKey<String>('turnNews.courtBlock');

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;
  final int spyReportCount;
  final TurnNewsCourtSnapshot courtSnapshot;
  final VoidCallback? onOpenIntelligence;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleLarge ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final mutedStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.muted);
    final showEmptyCopy = digest.lines.isEmpty && courtSnapshot.isEmpty;
    final lines = digest.lines.isEmpty
        ? const <String>[]
        : digest.lines.map((e) => formatTurnNewsLine(l10n, game, e)).toList();
    final openEvents = onOpenEvents;
    final openIntelligence = onOpenIntelligence;

    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.turnNews_title(newTurnNumber), style: titleStyle),
          const SizedBox(height: CtSpacing.ml),
          if (showEmptyCopy)
            Text(l10n.turnNews_empty, style: mutedStyle)
          else if (lines.isNotEmpty)
            _TurnNewsDigestList(lines: lines, bodyStyle: bodyStyle),
          const SizedBox(height: CtSpacing.l),
          if (!courtSnapshot.isEmpty && openEvents != null)
            _TurnNewsCourtBlock(
              snapshot: courtSnapshot,
              style: mutedStyle,
              onOpenEvents: openEvents,
            ),
          if (spyReportCount > 0 && openIntelligence != null)
            _TurnNewsSpiesFooter(
              spyReportCount: spyReportCount,
              style: mutedStyle,
              onOpenIntelligence: openIntelligence,
            ),
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

class _TurnNewsDigestList extends StatelessWidget {
  const _TurnNewsDigestList({required this.lines, required this.bodyStyle});

  final List<String> lines;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: lines.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: CtSpacing.m),
          child: Text(lines[i], style: bodyStyle),
        ),
      ),
    );
  }
}

class _TurnNewsCourtBlock extends StatelessWidget {
  const _TurnNewsCourtBlock({
    required this.snapshot,
    required this.style,
    required this.onOpenEvents,
  });

  final TurnNewsCourtSnapshot snapshot;
  final TextStyle style;
  final VoidCallback onOpenEvents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: InkWell(
        key: TurnNewsDialog.courtBlockKey,
        onTap: onOpenEvents,
        child: Text(
          formatTurnNewsCourtBlock(appL10n(context), snapshot),
          style: style,
        ),
      ),
    );
  }
}

class _TurnNewsSpiesFooter extends StatelessWidget {
  const _TurnNewsSpiesFooter({
    required this.spyReportCount,
    required this.style,
    required this.onOpenIntelligence,
  });

  final int spyReportCount;
  final TextStyle style;
  final VoidCallback onOpenIntelligence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: InkWell(
        onTap: onOpenIntelligence,
        child: Text(
          appL10n(context).turnNews_spiesFooter(spyReportCount),
          style: style,
        ),
      ),
    );
  }
}

String formatTurnNewsCourtBlock(
  AppLocalizations l10n,
  TurnNewsCourtSnapshot snapshot,
) {
  final clauses = snapshot.families.map((hit) {
    return _courtClause(l10n, hit);
  }).toList();
  if (snapshot.overflowFamilyCount > 0) {
    clauses.add(l10n.turnNews_courtMore(snapshot.overflowFamilyCount));
  }
  return l10n.turnNews_courtBlock(clauses.join(' · '));
}

String _courtClause(AppLocalizations l10n, TurnNewsCourtFamilyHit hit) {
  return switch (hit.family) {
    TurnNewsCourtFamily.orderRejected =>
      hit.count == 1
          ? l10n.turnNews_courtDecreeRefused
          : l10n.turnNews_courtDecreesRefused(hit.count),
    TurnNewsCourtFamily.researchComplete => _researchClause(l10n, hit),
    TurnNewsCourtFamily.combat =>
      hit.count == 1
          ? l10n.turnNews_courtBattleFought
          : l10n.turnNews_courtBattlesFought(hit.count),
    TurnNewsCourtFamily.marketEconomy => l10n.turnNews_courtMarket,
    TurnNewsCourtFamily.workFinished =>
      hit.count == 1
          ? l10n.turnNews_courtWorkFinished
          : l10n.turnNews_courtWorksFinished(hit.count),
  };
}

String _researchClause(AppLocalizations l10n, TurnNewsCourtFamilyHit hit) {
  final name = hit.techDisplayName;
  if (hit.count == 1 && name != null && name.isNotEmpty) {
    return l10n.turnNews_courtResearchFinished(name);
  }
  if (hit.count > 1) {
    return l10n.turnNews_courtResearchFinishedMany(hit.count);
  }
  return l10n.turnNews_courtResearchFinishedUnknown;
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
