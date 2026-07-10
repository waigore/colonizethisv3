part of 'app_event_handler_scope.dart';

extension _SessionCommands on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _sessionCommandListeners(AppEventBus bus) {
    return [
      ..._observeSessionListeners(bus),
      ..._civilianWorkSessionListeners(bus),
      ..._navalSessionListeners(bus),
      ..._armySessionListeners(bus),
      ..._diplomacySessionListeners(bus),
      ..._debugSessionListeners(bus),
    ];
  }
}
