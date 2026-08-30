// GAME30003 Intelligence Council. SPEC/ui/intelligence-council.md.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/routes.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';
import '../../widgets/diplomacy/diplomacy_panel.dart' show FactionKind;
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'intelligence_council_format.dart';

void emitOpenIntelligenceCouncil({
  required AppEventBus bus,
  required Game game,
  required String humanPlayerId,
}) {
  bus.emit(
    NavigateToRouteEvent(Routes.intelligence, {
      'game': game,
      'humanPlayerId': humanPlayerId,
    }),
  );
}

class IntelligenceCouncilScreen extends ConsumerWidget {
  const IntelligenceCouncilScreen({
    super.key,
    required this.game,
    required this.humanPlayerId,
  });

  static const screenId = UiScreenIds.intelligenceCouncilScreen;

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Intelligence';

  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_diplomacy.png';

  static const Key topBarKey = ValueKey<String>('intelligenceCouncilTopBar');

  final Game game;
  final String humanPlayerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bus = ref.watch(appEventBusProvider);
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: topBarKey,
        title: topBarTitle,
        iconAsset: topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        final sentinel = observeNotDefinedSentinel(shell, 'Intelligence');
        if (sentinel != null) return sentinel;
        return IntelligenceCouncilBody(
          game: displayGame,
          humanPlayerId: humanPlayerId,
          bus: bus,
        );
      },
    );
  }
}

class IntelligenceCouncilBody extends StatelessWidget {
  const IntelligenceCouncilBody({
    super.key,
    required this.game,
    required this.humanPlayerId,
    this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus? bus;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final digest = game.lastTurnIntelligenceDigest;
    final worldLines = digest?.worldLines ?? const <IntelligenceWorldLine>[];
    final spyBlocks = digest?.spyReportsFor(humanPlayerId) ?? const [];
    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: const EdgeInsets.all(CtSpacing.l),
        children: [
          Text(
            l10n.intelligence_worldHeading,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: CtSpacing.m),
          if (worldLines.isEmpty)
            Text(
              l10n.intelligence_worldEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.muted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final line in worldLines)
              IntelligenceCouncilLineTile(
                text: formatIntelligenceWorldLine(l10n, game, line),
                onTap: () => _onWorldLineTap(line),
              ),
          const SizedBox(height: CtSpacing.xl),
          Text(l10n.intelligence_spyHeading, style: theme.textTheme.titleSmall),
          const SizedBox(height: CtSpacing.m),
          if (spyBlocks.isEmpty || spyBlocks.every((b) => b.lines.isEmpty))
            Text(
              l10n.intelligence_spyEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: EditorialMonoclePalette.muted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final block in spyBlocks)
              for (final line in block.lines)
                IntelligenceCouncilLineTile(
                  text: formatIntelligenceSpyLine(
                    l10n,
                    game,
                    humanPlayerId,
                    block.courtFactionId,
                    line,
                  ),
                  onTap: () => _openCourt(block.courtFactionId),
                ),
        ],
      ),
    );
  }

  void _onWorldLineTap(IntelligenceWorldLine line) {
    final bus = this.bus;
    if (bus == null) return;
    final provinceId = line.provinceId;
    if (provinceId != null && provinceId.isNotEmpty) {
      bus.emit(const PopNavigationEvent());
      bus.emit(OpenProvinceDetailPanelEvent(provinceId));
      return;
    }
    final courtId = line.factionIdB ?? line.factionIdA;
    if (courtId != null) _openCourt(courtId);
  }

  void _openCourt(String factionId) {
    final bus = this.bus;
    if (bus == null) return;
    bus.emit(
      NavigateToRouteEvent(Routes.diplomacyDetail, {
        'game': game,
        'humanPlayerId': humanPlayerId,
        'factionId': factionId,
        'factionDisplayName': intelligenceFactionLabel(game, factionId),
        'kind': _kindFor(game, factionId),
        'relation': null,
      }),
    );
  }
}

class IntelligenceCouncilLineTile extends StatelessWidget {
  const IntelligenceCouncilLineTile({
    super.key,
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.m),
      child: InkWell(
        onTap: onTap,
        child: Text(text, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

FactionKind _kindFor(Game game, String id) {
  if (game.players.any((p) => p.id == id)) return FactionKind.greatPower;
  if (game.minorNations.any((m) => m.id == id)) return FactionKind.minor;
  return FactionKind.tribe;
}
