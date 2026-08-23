import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Host that owns an active [Ticker] and counts every frame the binding
/// processes after the ticker is started.
class TickerFrameCounterHost extends StatefulWidget {
  const TickerFrameCounterHost({required this.onState});

  final void Function(TickerFrameCounterHostState state) onState;

  @override
  State<TickerFrameCounterHost> createState() => TickerFrameCounterHostState();
}

class TickerFrameCounterHostState extends State<TickerFrameCounterHost>
    with SingleTickerProviderStateMixin {
  int framesPumped = 0;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    widget.onState(this);
    _ticker = createTicker((_) => framesPumped++);
  }

  void startCounting() {
    framesPumped = 0;
    _ticker.start();
  }

  void stopCounting() {
    _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<TickerFrameCounterHostState> pumpTickerFrameCounterHost(
  WidgetTester tester,
) async {
  late TickerFrameCounterHostState captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TickerFrameCounterHost(onState: (s) => captured = s),
      ),
    ),
  );
  return captured;
}
