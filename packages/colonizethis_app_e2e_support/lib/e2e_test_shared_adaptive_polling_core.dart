import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Next interval after an idle poll pump in E2E busy-wait loops (25→50→75→100 ms).
/// Aligns with [e2eWaitUntilFound] backoff (`SPEC/program/e2e-integration-tests.md`, #2336).
int e2eAdaptivePollRampAfterIdle(int previousMs) {
  if (previousMs < 100) {
    return previousMs + 25;
  }
  return 100;
}

class E2ePerfLog {
  E2ePerfLog(this.testName);

  final String testName;
  final Map<String, int> _counters = <String, int>{};

  void bumpCounter(String name, {int by = 1, String? meta}) {
    _counters[name] = (_counters[name] ?? 0) + by;
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_COUNTER|test=$testName|name=$name|value=${_counters[name]}$metaPart',
    );
  }

  void timing(String phase, Duration elapsed, {String? meta}) {
    final metaPart = meta == null ? '' : '|meta=$meta';
    debugPrint(
      'E2E_TIMING|test=$testName|phase=$phase|ms=${elapsed.inMilliseconds}$metaPart',
    );
  }
}

Future<void> e2ePumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Next idle poll step for E2E `while` loops (GitHub #2336 / AC5): doubles the
/// previous pump duration until [maxMs] to reduce wasted frames on headless Linux.
int e2eNextIdlePollStepMs(int currentMs, {int maxMs = 500}) {
  final next = currentMs * 2;
  return next > maxMs ? maxMs : next;
}
