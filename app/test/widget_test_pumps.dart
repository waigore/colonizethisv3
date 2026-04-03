import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Step between pumpAndSettle iterations (keep small for fast completion).
const Duration _kPumpStep = Duration(milliseconds: 16);

/// Hard cap for each [WidgetTester.pumpAndSettle] so widget tests cannot hang
/// on endless animations or pending frames (default SDK timeout is 10 minutes).
const Duration kWidgetTestPumpSettleMax = Duration(milliseconds: 1200);

/// Bounded pump-and-settle for async layout (images, routes, nine-patch loaders).
Future<void> pumpSettleCapped(
  WidgetTester tester, {
  Duration? timeout,
}) async {
  await tester.pumpAndSettle(
    _kPumpStep,
    EnginePhase.sendSemanticsUpdate,
    timeout ?? kWidgetTestPumpSettleMax,
  );
}

/// A few frames after a gesture when updates are expected to be synchronous.
Future<void> pumpSyncFrames(WidgetTester tester) async {
  await tester.pump(_kPumpStep);
  await tester.pump(_kPumpStep);
}
