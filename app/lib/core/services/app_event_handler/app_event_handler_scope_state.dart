import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_handler_scope.dart';
import 'app_event_handler_scope_lifecycle.dart';
import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions.dart';

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
