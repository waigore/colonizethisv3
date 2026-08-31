// Shared timing helpers for empire-rail session-cache reopen anchors (Refs #4688).

int empireRailOpenPathTimeMicros(
  void Function() fn, {
  required int iterations,
}) {
  for (var i = 0; i < 3; i++) {
    fn();
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    fn();
  }
  sw.stop();
  return sw.elapsedMicroseconds ~/ iterations;
}

int empireRailOpenPathTimeMicrosMedian(
  void Function() fn, {
  required int iterations,
}) {
  final samples = <int>[
    for (var run = 0; run < 3; run++)
      empireRailOpenPathTimeMicros(fn, iterations: iterations),
  ]..sort();
  return samples[1];
}
