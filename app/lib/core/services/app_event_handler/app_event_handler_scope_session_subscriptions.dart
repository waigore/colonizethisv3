import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_handler_scope_session_helpers.dart';
import 'app_event_handler_scope_session_subscriptions_army.dart';
import 'app_event_handler_scope_session_subscriptions_civilian.dart';
import 'app_event_handler_scope_session_subscriptions_debug.dart';
import 'app_event_handler_scope_session_subscriptions_diplomacy.dart';
import 'app_event_handler_scope_session_subscriptions_naval.dart';
import 'app_event_handler_scope_session_subscriptions_observe.dart';

mixin AppEventHandlerScopeSessionCommands
    on
        AppEventHandlerScopeSessionHelpers,
        AppEventHandlerScopeSessionObserveListeners,
        AppEventHandlerScopeSessionCivilianWorkListeners,
        AppEventHandlerScopeSessionNavalListeners,
        AppEventHandlerScopeSessionArmyListeners,
        AppEventHandlerScopeSessionDiplomacyListeners,
        AppEventHandlerScopeSessionDebugListeners {
  List<StreamSubscription<dynamic>> sessionCommandListeners(AppEventBus bus) {
    return [
      ...observeSessionListeners(bus),
      ...civilianWorkSessionListeners(bus),
      ...navalSessionListeners(bus),
      ...armySessionListeners(bus),
      ...diplomacySessionListeners(bus),
      ...debugSessionListeners(bus),
    ];
  }
}
