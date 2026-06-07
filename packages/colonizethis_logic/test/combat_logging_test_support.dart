import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Filters captured [LogEvent]s for combat-domain logger lines.
///
/// After the `colonizethis_combat` package extraction (Refs #3290 Phase 1),
/// combat-resolution lines emitted from that package carry the `combat:` prefix
/// (e.g. `combat: combat engagement`), while turn-orchestrated combat-phase
/// lines emitted from `colonizethis_logic` keep the `logic:` prefix
/// (e.g. `logic: combat conflict_detection`). This filter matches both so split
/// test files share one filter rather than duplicate it.
List<String> combatMessages(List<LogEvent> events) => [
  for (final e in events)
    if (e.message.contains('logic: combat') ||
        e.message.contains('combat: combat'))
      e.message,
];

/// Holder for combat-logging test capture state.
///
/// Wires a [LogEvent] listener at debug level for the duration of a test, and
/// restores the previous level on teardown. Returned by [setupCombatLogCapture]
/// so split test files can share the attach/detach lifecycle without copy-paste.
class CombatLogCapture {
  CombatLogCapture._();

  final List<LogEvent> events = <LogEvent>[];
  late final void Function(LogEvent) _listener = events.add;

  void attach() {
    Logger.addLogListener(_listener);
    Logger.level = Level.debug;
  }

  void detach() {
    Logger.removeLogListener(_listener);
    events.clear();
    Logger.level = Level.info;
  }

  /// Convenience: filtered combat messages from [events].
  List<String> get combat => combatMessages(events);
}

/// Registers `setUp`/`tearDown` callbacks that wire combat log capture for
/// each test, and returns a getter into the active [CombatLogCapture].
///
/// The returned function is callable inside tests to access the current
/// capture (a fresh instance per test). This avoids duplicating the
/// listener attach/detach boilerplate across split combat-logging files.
CombatLogCapture Function() setupCombatLogCapture() {
  late CombatLogCapture current;
  setUp(() {
    current = CombatLogCapture._();
    current.attach();
  });
  tearDown(() {
    current.detach();
  });
  return () => current;
}
