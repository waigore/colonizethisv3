import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flame/game.dart' hide Game;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/game_to_ui_bus_listener.dart';
import '../../flame/host/host.dart';
import '../../flame/map_state/map_state.dart';
import '../../flame/overlays/victory_overlay.dart';
import '../../widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import '../../widgets/dialogue/intervention_dialogue_overlay.dart';
import '../../widgets/dialogue/overture_dialogue_overlay.dart';
import '../../widgets/dialogue/tribe_first_contact_overlay.dart';
import '../../widgets/dialogue/tribe_first_contact_sync.dart';
import 'diplomacy_resume_helper.dart';
import 'game_screen_fallback_next_turn.dart';
import '../../widgets/dialogue/game_start_intro_overlay.dart';

void showGameScreenPauseMenu(AppEventBus bus) {
  bus.emit(const OpenPauseMenuPanelEvent());
}

/// Composes the Flame canvas / map shell, pause + fallback next-turn chrome,
/// victory overlay, and dialogue overlays (intro, tribe herald, diplomacy).
class GameScreenOverlayStack extends ConsumerWidget {
  const GameScreenOverlayStack({
    super.key,
    required this.game,
    required this.mapViewData,
    required this.victory,
    required this.showOverlayButtons,
    required this.showIntro,
    required this.pendingHerald,
    required this.pendingDiplomacy,
    required this.turnResolutionBlocking,
  });

  final Game? game;
  final InitGameMapViewData? mapViewData;
  final VictoryState? victory;
  final bool showOverlayButtons;
  final bool showIntro;
  final TribeFirstContactHeraldPayload? pendingHerald;
  final PendingDiplomacyState? pendingDiplomacy;
  final bool turnResolutionBlocking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content = Stack(
      children: [
        if (mapViewData != null && game != null)
          GameMapArea(game: game!, mapViewData: mapViewData!)
        else
          GameWidget(game: ColonizeThisGame()),
        if (showOverlayButtons) ...[
          Positioned(
            left: 16,
            top: 16,
            child: CtIconAction(
              icon: Icons.menu,
              iconSize: 24,
              onPressed: turnResolutionBlocking
                  ? null
                  : () => showGameScreenPauseMenu(ref.read(appEventBusProvider)),
              enabled: !turnResolutionBlocking,
              tooltip: appL10n(context).game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: GameScreenFallbackNextTurnButton(
              game: game!,
              turnResolutionBlocking: turnResolutionBlocking,
            ),
          ),
        ],
        if (game != null && victory != null)
          VictoryOverlay(
            game: game!,
            victory: victory!,
            bus: ref.read(appEventBusProvider),
          ),
      ],
    );

    if (game != null) {
      content = TribeFirstContactSyncListener(
        child: GameToUIBusListener(gameId: game!.id, child: content),
      );
    }

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref.read(gameIdsWithIntroShownProvider.notifier).markShown(game!.id);
        },
        child: content,
      );
    }

    if (!showIntro && game != null && pendingHerald != null) {
      content = TribeFirstContactOverlay(
        tribeName: pendingHerald!.tribeName,
        capitalName: pendingHerald!.capitalName,
        onDismissed: () {
          ref
              .read(tribeFirstContactHeraldsShownProvider.notifier)
              .markShown(game!.id, pendingHerald!.tribeId);
          ref.read(tribeFirstContactHeraldQueueProvider.notifier).dequeueHead();
        },
        child: content,
      );
    }

    if (game != null && pendingDiplomacy != null) {
      switch (pendingDiplomacy!) {
        case PendingDiplomacyOvertures(:final offers) when offers.isNotEmpty:
          content = OvertureDialogueOverlay(
            game: game!,
            pendingOvertures: offers,
            onDecisions: (decisions) {
              applyDiplomacyResumeDecisions(
                service: ref.read(gameServiceProvider),
                orders: ref.read(currentOrdersProvider),
                applier: ref.read(turnResolutionResultApplierProvider),
                resume: (service, orders) => service.resumeOvertureDecisions(
                  game!,
                  offers,
                  decisions,
                  orders,
                ),
              );
            },
            child: content,
          );
        case PendingDiplomacyIntervention(:final prompts)
            when prompts.isNotEmpty:
          content = InterventionDialogueOverlay(
            game: game!,
            prompts: prompts,
            onDecisions: (decisions) {
              applyDiplomacyResumeDecisions(
                service: ref.read(gameServiceProvider),
                orders: ref.read(currentOrdersProvider),
                applier: ref.read(turnResolutionResultApplierProvider),
                resume: (service, orders) =>
                    service.resumeInterventionDecisions(
                  game!,
                  decisions,
                  orders,
                ),
              );
            },
            child: content,
          );
        case PendingDiplomacyCallToArms(:final pending) when pending.isNotEmpty:
          content = CallToArmsDialogueOverlay(
            game: game!,
            pending: pending,
            onDecisions: (decisions) {
              applyDiplomacyResumeDecisions(
                service: ref.read(gameServiceProvider),
                orders: ref.read(currentOrdersProvider),
                applier: ref.read(turnResolutionResultApplierProvider),
                resume: (service, orders) =>
                    service.resumeCallToArmsDecisions(
                  game!,
                  decisions,
                  orders,
                ),
              );
            },
            child: content,
          );
        case _:
          break;
      }
    }

    return content;
  }
}
