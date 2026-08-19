// Turn-start news modal. SPEC/ui/turn-news-dialog.md.


import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Prior-turn summary dialog; [newTurnNumber] is current turn after resolution.
class TurnNewsDialog extends StatelessWidget {
  const TurnNewsDialog({
    super.key,
    required this.game,
    required this.digest,
    required this.newTurnNumber,
    this.courtSummary = const TurnNewsCourtSummary.empty(),
    this.spyReportCount = 0,
    this.onOpenIntelligence,
    this.onOpenEvents,
  });

  static const screenId = UiScreenIds.turnNewsDialog;

  static Key courtBlockKey() => const ValueKey<String>('turn_news_court_block');

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;
  final TurnNewsCourtSummary courtSummary;
  final int spyReportCount;
  final VoidCallback? onOpenIntelligence;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: _TurnNewsDialogContent(
        game: game,
        digest: digest,
        newTurnNumber: newTurnNumber,
        courtSummary: courtSummary,
        spyReportCount: spyReportCount,
        onOpenIntelligence: onOpenIntelligence,
        onOpenEvents: onOpenEvents,
      ),
    );
  }
}

class _TurnNewsDialogContent extends StatelessWidget {
  const _TurnNewsDialogContent({
    required this.game,
    required this.digest,
    required this.newTurnNumber,
    required this.courtSummary,
    required this.spyReportCount,
    this.onOpenIntelligence,
    this.onOpenEvents,
  });

  final Game game;
  final TurnNewsDigest digest;
  final int newTurnNumber;
  final TurnNewsCourtSummary courtSummary;
  final int spyReportCount;
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
    final isEmpty = digest.lines.isEmpty;
    final hasCourt = !courtSummary.isEmpty;
    final lines = isEmpty
        ? const <String>[]
        : digest.lines.map((e) => formatTurnNewsLine(l10n, game, e)).toList();

    final courtParts = <String>[...courtSummary.clauses];
    if (courtSummary.overflowFamilyCount > 0) {
      courtParts.add(l10n.turnNews_courtMore(courtSummary.overflowFamilyCount));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.turnNews_title(newTurnNumber), style: titleStyle),
        const SizedBox(height: CtSpacing.ml),
        _TurnNewsGazetteSection(
          isEmpty: isEmpty,
          hasCourt: hasCourt,
          lines: lines,
          emptyLabel: l10n.turnNews_empty,
          mutedStyle: mutedStyle,
          bodyStyle: bodyStyle,
        ),
        if (hasCourt) ...[
          if (!isEmpty) const SizedBox(height: CtSpacing.m),
          _CourtBlock(
            key: TurnNewsDialog.courtBlockKey(),
            body: l10n.turnNews_courtBlock(courtParts.join(' · ')),
            openEventsLabel: l10n.turnNews_openEvents,
            mutedStyle: mutedStyle,
            onOpenEvents: onOpenEvents,
          ),
        ],
        const SizedBox(height: CtSpacing.l),
        if (spyReportCount > 0 && onOpenIntelligence != null)
          _TurnNewsSpyFooter(
            label: l10n.turnNews_spiesFooter(spyReportCount),
            mutedStyle: mutedStyle,
            onOpenIntelligence: onOpenIntelligence!,
          ),
        Align(
          alignment: Alignment.centerRight,
          child: CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.turnNews_close),
          ),
        ),
      ],
    );
  }
}

class _TurnNewsGazetteSection extends StatelessWidget {
  const _TurnNewsGazetteSection({
    required this.isEmpty,
    required this.hasCourt,
    required this.lines,
    required this.emptyLabel,
    required this.mutedStyle,
    required this.bodyStyle,
  });

  final bool isEmpty;
  final bool hasCourt;
  final List<String> lines;
  final String emptyLabel;
  final TextStyle mutedStyle;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    if (isEmpty && !hasCourt) {
      return Text(emptyLabel, style: mutedStyle);
    }
    if (isEmpty) {
      return const SizedBox.shrink();
    }
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

class _TurnNewsSpyFooter extends StatelessWidget {
  const _TurnNewsSpyFooter({
    required this.label,
    required this.mutedStyle,
    required this.onOpenIntelligence,
  });

  final String label;
  final TextStyle mutedStyle;
  final VoidCallback onOpenIntelligence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: InkWell(
        onTap: onOpenIntelligence,
        child: Text(label, style: mutedStyle),
      ),
    );
  }
}

class _CourtBlock extends StatelessWidget {
  const _CourtBlock({
    super.key,
    required this.body,
    required this.openEventsLabel,
    required this.mutedStyle,
    this.onOpenEvents,
  });

  final String body;
  final String openEventsLabel;
  final TextStyle mutedStyle;
  final VoidCallback? onOpenEvents;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenEvents,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CtSpacing.xs,
        runSpacing: CtSpacing.xs,
        children: [
          Text(body, style: mutedStyle),
          if (onOpenEvents != null)
            Text(openEventsLabel, style: mutedStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: mutedStyle.color,
            )),
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
