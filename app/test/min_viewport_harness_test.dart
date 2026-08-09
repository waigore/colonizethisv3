// Smoke tests for the shared minimum-viewport pump harness (Refs #3730).
//
// These pin the harness contract that every migrated
// `*_320dp_min_viewport_test.dart` file now relies on:
//
//  * the surface size is forced to the requested minimum viewport so the
//    framework's `RenderFlex` math and `MediaQuery.sizeOf` both see it;
//  * a tear-down restores the surface size after the test;
//  * the editorial-monocle theme drives the shell;
//  * provider overrides are threaded into the wrapping `ProviderScope`;
//  * `settle: true` drains pending animations.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

const Size _kMinViewport = Size(320, 640);

final Provider<String> _labelProvider = Provider<String>((ref) => 'default');

void main() {
  suppressLogsForTests();

  testWidgets(
    'pumpAtMinViewport forces the surface size and editorial-monocle theme',
    (WidgetTester tester) async {
      late Size observedSize;
      late ThemeData observedTheme;

      await pumpAtMinViewport(
        tester,
        size: _kMinViewport,
        child: Builder(
          builder: (context) {
            observedSize = MediaQuery.sizeOf(context);
            observedTheme = Theme.of(context);
            return const SizedBox.shrink();
          },
        ),
      );

      expect(observedSize, _kMinViewport);
      expect(observedTheme.colorScheme, AppThemes.editorialMonocle.colorScheme);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pumpAtMinViewport threads provider overrides into the scope', (
    WidgetTester tester,
  ) async {
    late String observedLabel;

    await pumpAtMinViewport(
      tester,
      size: _kMinViewport,
      overrides: [_labelProvider.overrideWithValue('overridden')],
      child: Consumer(
        builder: (context, ref, _) {
          observedLabel = ref.watch(_labelProvider);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(observedLabel, 'overridden');
  });

  testWidgets('pumpAtMinViewport constrains the child to the forced width', (
    WidgetTester tester,
  ) async {
    late double maxWidth;

    await pumpAtMinViewport(
      tester,
      size: _kMinViewport,
      child: LayoutBuilder(
        builder: (context, constraints) {
          maxWidth = constraints.maxWidth;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(maxWidth, _kMinViewport.width);
  });

  testWidgets('pumpAtMinViewport with settle drains pending animations', (
    WidgetTester tester,
  ) async {
    await pumpAtMinViewport(
      tester,
      size: _kMinViewport,
      settle: true,
      child: const _BrieflyAnimating(),
    );

    expect(find.text('done'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _BrieflyAnimating extends StatefulWidget {
  const _BrieflyAnimating();

  @override
  State<_BrieflyAnimating> createState() => _BrieflyAnimatingState();
}

class _BrieflyAnimatingState extends State<_BrieflyAnimating> {
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
