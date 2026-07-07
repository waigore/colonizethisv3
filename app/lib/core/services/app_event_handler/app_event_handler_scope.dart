import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_order_helpers.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/quick_battle_result_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/turn_news_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/observe_session_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/turn_resolution_blocking_provider.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../debug/debug_command_session_handler.dart';
import '../observe/observe_mode_session_handler.dart';

import 'app_event_handler.dart';
import '../debug/app_event_handler_debug_flip_province.dart'
    show applyDebugFlipProvinceOwnership;
import '../debug/app_event_handler_debug_reveal_province.dart'
    show applyDebugRevealProvince;
import '../debug/app_event_handler_debug_set_diplomacy.dart'
    show applyDebugSetDiplomacyRelation;
import 'app_event_handler_break_alliance_immediately.dart'
    show applyBreakAllianceImmediately;
import '../debug/app_event_handler_debug_spawn_civilian.dart'
    show applyDebugCivilianSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_regiment.dart'
    show applyDebugRegimentSpawnAtCapital;
import '../debug/app_event_handler_debug_spawn_ship.dart'
    show applyDebugShipSpawnAtCapitalHomeFleet;
import '../debug/app_event_handler_debug_stockpile.dart'
    show applyDebugStockpileCredit;
import '../debug/app_event_handler_debug_treasury.dart'
    show applyDebugTreasuryCredit;
import '../debug/app_event_handler_debug_worker_pool.dart'
    show applyDebugWorkerPoolCredit;
import '../debug/debug_command_helpers.dart' show DebugCommandResult;

/// [OpenDialogEvent] id for [TrainCiviliansDialog]. SPEC/program/app-ui-wiring.md.

part 'app_event_handler_scope_dialog_builders.dart';
part 'app_event_handler_scope_session_helpers.dart';
part 'app_event_handler_scope_train_orders.dart';
part 'app_event_handler_scope_session_subscriptions_observe.dart';
part 'app_event_handler_scope_session_subscriptions_civilian.dart';
part 'app_event_handler_scope_session_subscriptions_naval.dart';
part 'app_event_handler_scope_session_subscriptions_army.dart';
part 'app_event_handler_scope_session_subscriptions_diplomacy.dart';
part 'app_event_handler_scope_session_subscriptions_debug.dart';
part 'app_event_handler_scope_session_subscriptions.dart';

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

final _logEvent = packageLogger('event');

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
      _AppEventHandlerScopeState();
}

class _AppEventHandlerScopeState extends ConsumerState<AppEventHandlerScope> {
  AppEventHandler? _handler;
  var _bound = false;
  final List<StreamSubscription<dynamic>> _sessionCommandSubs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) {
      return;
    }
    _bound = true;
    final bus = ref.read(appEventBusProvider);
    _handler = AppEventHandler(
      bus: bus,
      navigatorKey: appNavigatorKey,
      dialogBuilders: _dialogBuilders(),
      onShowSnackBar: _showSnackBar,
    );
    _handler!.bind();
    _sessionCommandSubs.addAll(_sessionCommandListeners(bus));
    _logEvent.d('AppEventHandler bound; session command listeners attached');
  }

  void _showSnackBar(ShowSnackBarEvent event) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(event.message),
        action: event.actionLabel != null && event.action != null
            ? SnackBarAction(
                label: event.actionLabel!,
                onPressed: event.action!,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    for (final s in _sessionCommandSubs) {
      s.cancel();
    }
    _sessionCommandSubs.clear();
    _handler?.unbind();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
