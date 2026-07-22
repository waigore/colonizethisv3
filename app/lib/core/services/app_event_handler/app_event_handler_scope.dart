import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_handler.dart';
import 'app_event_handler_scope_state.dart';

export 'app_event_handler_scope_session_helpers.dart'
    show
        civilianWorkUpsertValidationPassCountForTests,
        resetCivilianWorkUpsertValidationPassCountForTests;
export 'app_event_handler_scope_train_orders.dart'
    show applyCombatModeChoiceToGame;

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.
const String trainCiviliansDialogId = 'train_civilians';

/// [OpenDialogEvent] id for [TrainMilitaryDialog]. SPEC/program/app-ui-wiring.md.
const String trainMilitaryDialogId = 'train_military';

/// [OpenDialogEvent] id for [TrainNavalDialog]. SPEC/program/app-ui-wiring.md.
const String trainNavalDialogId = 'train_naval';

/// [OpenDialogEvent] id for [GrantOrSubsidyDialog]. SPEC/program/app-ui-wiring.md.
const String grantOrSubsidyDialogId = 'grant_or_subsidy';

/// [OpenDialogEvent] id for the new-game leader-selection dialog. The dialog
/// builder lives in the shell feature (`features/shell/`) and is injected into
/// this scope at the composition root via [AppEventHandlerScope.extraDialogBuilders]
/// (Refs #3546). SPEC/program/app-ui-wiring.md.
const String newGameLeaderSelectionDialogId = 'new_game_leader_selection';

/// [OpenDialogEvent] id for [CombatModeChoiceDialog]. SPEC/program/app-ui-wiring.md.
const String combatModeChoiceDialogId = 'combat_mode_choice';

/// [OpenDialogEvent] id for [QuickBattleResultDialog]. SPEC/program/app-ui-wiring.md.
const String quickBattleResultDialogId = 'quick_battle_result';

/// [OpenDialogEvent] id for [TurnNewsDialog]. SPEC/program/app-ui-wiring.md.
const String turnNewsDialogId = 'turn_news';

/// [OpenDialogEvent] id for the save-game name dialog (shell feature builder).
/// SPEC/ui/save-game-name-dialog.md, SPEC/program/app-ui-wiring.md.
const String saveGameNameDialogId = 'save_game_name';

/// [OpenDialogEvent] id for the load-game list dialog (shell feature builder).
/// SPEC/ui/load-game-list-dialog.md, SPEC/program/app-ui-wiring.md.
const String loadGameListDialogId = 'load_game_list';

/// [OpenDialogEvent] id for the app Settings dialog (shell feature builder).
/// SPEC/ui/settings-dialog.md, SPEC/program/app-ui-wiring.md.
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

  /// Feature-layer dialog builder factories injected by the composition root,
  /// merged over the core builders in [_DialogBuilders._dialogBuilders]. Each
  /// factory is resolved with [appNavigatorKey] inside this scope (the
  /// documented `core/services/` choke point), so feature files thread the
  /// navigator key explicitly instead of reading the global. This keeps
  /// `core/services/` free of `features/` dialog imports: a feature owns its
  /// dialog construction and `main.dart` wires it in by [OpenDialogEvent] id
  /// (Refs #3546). SPEC/program/app-ui-wiring.md.
  final Map<String, NavigatorKeyDialogBuilder> extraDialogBuilders;

  @override
  ConsumerState<AppEventHandlerScope> createState() =>
      AppEventHandlerScopeState();
}
