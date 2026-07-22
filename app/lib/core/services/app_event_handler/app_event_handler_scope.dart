import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_handler.dart';
import 'app_event_handler_scope_state.dart';

export 'app_event_handler_scope_session_helpers.dart'
    show
        civilianWorkUpsertValidationPassCountForTests,
        resetCivilianWorkUpsertValidationPassCountForTests;
export 'app_event_handler_scope_session_subscriptions.dart'
    show applyCombatModeChoiceToGame;

const String trainCiviliansDialogId = 'train_civilians';
const String trainMilitaryDialogId = 'train_military';
const String trainNavalDialogId = 'train_naval';
const String grantOrSubsidyDialogId = 'grant_or_subsidy';
const String newGameLeaderSelectionDialogId = 'new_game_leader_selection';
const String combatModeChoiceDialogId = 'combat_mode_choice';
const String quickBattleResultDialogId = 'quick_battle_result';
const String turnNewsDialogId = 'turn_news';
const String saveGameNameDialogId = 'save_game_name';
const String loadGameListDialogId = 'load_game_list';
const String settingsDialogId = 'settings';

/// Binds [AppEventHandler] to [appNavigatorKey] for the app lifetime.
/// SPEC/program/app-event-bus.md (handler); SPEC/program/app-ui-wiring.md (dialog registration).
class AppEventHandlerScope extends ConsumerStatefulWidget {
  const AppEventHandlerScope({
    super.key,
    required this.child,
    this.extraDialogBuilders = const {},
  });

  final Widget child;

  /// Feature dialog builders injected at composition root (Refs #3546).
  final Map<String, NavigatorKeyDialogBuilder> extraDialogBuilders;

  @override
  ConsumerState<AppEventHandlerScope> createState() =>
      AppEventHandlerScopeState();
}
