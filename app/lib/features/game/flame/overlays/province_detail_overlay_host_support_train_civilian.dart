import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainCiviliansDialogId;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

/// Opens `UNIT40001` with no highlight params (Refs #4752).
VoidCallback buildTrainCivilianDialogTap(ct_models.AppEventBus bus) {
  return () =>
      bus.emit(const ct_models.OpenDialogEvent(trainCiviliansDialogId));
}
