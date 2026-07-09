// Shared WorkSuggestionPipeline scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

List<String> wspSuggestWorkLines(List<LogEvent> events) => [
      for (final e in events)
        if (e.message.contains('suggest_work')) e.message,
    ];

void withWspLogCapture(void Function(List<LogEvent> events) body) {
  final capturedEvents = <LogEvent>[];
  void listener(LogEvent e) => capturedEvents.add(e);
  Logger.addLogListener(listener);
  Logger.level = Level.debug;
  try {
    body(capturedEvents);
  } finally {
    Logger.removeLogListener(listener);
    Logger.level = Level.info;
  }
}

Unit wspBuilderUnit({String unitId = 'u1'}) => Unit(
      id: unitId,
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'ow|p1',
      tileKey: 'ow|p1|0|0',
      status: UnitStatus.idle,
    );

Unit wspExplorerUnit({String unitId = 'u1'}) => Unit(
      id: unitId,
      type: kUnitTypeExplorer,
      ownerId: 'gp1',
      locationProvinceId: 'ow|p1',
      tileKey: 'ow|p1|0|0',
      status: UnitStatus.idle,
    );
