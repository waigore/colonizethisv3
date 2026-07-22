import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_handler_scope.dart';
import 'app_event_handler_scope_dialog_builders.dart';
import 'app_event_handler_scope_lifecycle.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions.dart';
import 'app_event_handler_scope_session_subscriptions_army.dart';
import 'app_event_handler_scope_session_subscriptions_civilian.dart';
import 'app_event_handler_scope_session_subscriptions_debug.dart';
import 'app_event_handler_scope_session_subscriptions_diplomacy.dart';
import 'app_event_handler_scope_session_subscriptions_naval.dart';
import 'app_event_handler_scope_session_subscriptions_observe.dart';

/// Session-scoped [AppEventHandler] binding and bus listeners.
class AppEventHandlerScopeState extends ConsumerState<AppEventHandlerScope>
    with
        AppEventHandlerScopeSessionHelpers,
        AppEventHandlerScopeDialogBuilders,
        AppEventHandlerScopeSessionObserveListeners,
        AppEventHandlerScopeSessionCivilianWorkListeners,
        AppEventHandlerScopeSessionNavalListeners,
        AppEventHandlerScopeSessionArmyListeners,
        AppEventHandlerScopeSessionDiplomacyListeners,
        AppEventHandlerScopeSessionDebugListeners,
        AppEventHandlerScopeSessionCommands,
        AppEventHandlerScopeLifecycle {}
