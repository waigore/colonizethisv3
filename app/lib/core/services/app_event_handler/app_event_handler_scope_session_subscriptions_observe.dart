import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../observe/observe_mode_session_handler.dart';
import 'app_event_handler_scope_session_helpers.dart';

mixin AppEventHandlerScopeSessionObserveListeners
    on AppEventHandlerScopeSessionHelpers {
  List<StreamSubscription<dynamic>> observeSessionListeners(AppEventBus bus) {
    return [
      bus.on<SetObserveModeOffEvent>().listen((_) {
        unlessTurnResolutionBlocksSession('SetObserveModeOffEvent', () {
          ref.read(observeModeSessionHandlerProvider).applySetObserveModeOff();
        });
      }),
      bus.on<SetObserveModeGlobalEvent>().listen((_) {
        unlessTurnResolutionBlocksSession('SetObserveModeGlobalEvent', () {
          ref
              .read(observeModeSessionHandlerProvider)
              .applySetObserveModeGlobal();
        });
      }),
      bus.on<SetObserveModePlayerEvent>().listen((e) {
        unlessTurnResolutionBlocksSession('SetObserveModePlayerEvent', () {
          ref
              .read(observeModeSessionHandlerProvider)
              .applySetObserveModePlayer(e.targetPlayerId);
        });
      }),
    ];
  }
}
