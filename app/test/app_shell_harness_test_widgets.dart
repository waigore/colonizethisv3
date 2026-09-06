// Inert widgets for app_shell_harness_test (Refs #4734 Slice H).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

class AppShellHarnessTestShellMarker extends StatelessWidget {
  const AppShellHarnessTestShellMarker({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

class AppShellHarnessTestBrieflyAnimating extends StatefulWidget {
  const AppShellHarnessTestBrieflyAnimating({super.key});
  @override
  State<AppShellHarnessTestBrieflyAnimating> createState() =>
      _AppShellHarnessTestBrieflyAnimatingState();
}

class _AppShellHarnessTestBrieflyAnimatingState
    extends State<AppShellHarnessTestBrieflyAnimating> {
  String _label = 'pending';
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _label = 'done');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(_label),
    );
  }
}

const Size kAppShellHarnessTestViewport = Size(800, 900);

Future<void> pumpAppShellNamedRouteHarness(WidgetTester tester) async {
  await tester.pumpWidget(
    buildAppShell(
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          return MaterialPageRoute<void>(
            builder: (_) => const Text('details-route'),
          );
        }
        return null;
      },
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/details'),
                child: const Text('go'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}
