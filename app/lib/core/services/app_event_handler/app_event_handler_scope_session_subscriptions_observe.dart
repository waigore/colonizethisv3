part of 'app_event_handler_scope.dart';

extension _SessionObserveListeners on _AppEventHandlerScopeState {
  List<StreamSubscription<dynamic>> _observeSessionListeners(AppEventBus bus) {
    return [
      bus.on<SetObserveModeOffEvent>().listen((_) {
        _unlessTurnResolutionBlocksSession('SetObserveModeOffEvent', () {
          ref.read(observeModeSessionHandlerProvider).applySetObserveModeOff();
        });
      }),
      bus.on<SetObserveModeGlobalEvent>().listen((_) {
        _unlessTurnResolutionBlocksSession(
          'SetObserveModeGlobalEvent',
          () {
            ref
                .read(observeModeSessionHandlerProvider)
                .applySetObserveModeGlobal();
          },
        );
      }),
      bus.on<SetObserveModePlayerEvent>().listen((e) {
        _unlessTurnResolutionBlocksSession(
          'SetObserveModePlayerEvent',
          () {
            ref
                .read(observeModeSessionHandlerProvider)
                .applySetObserveModePlayer(e.targetPlayerId);
          },
        );
      }),
    ];
  }
}
