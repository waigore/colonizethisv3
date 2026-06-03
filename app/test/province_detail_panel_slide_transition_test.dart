// Pins `ProvinceDetailPanelSlideTransition` (Refs #2865 S8).
//
// SPEC: `SPEC/ui/province-sea-zone-detail-overlay.md` § Interaction (panel
// motion); `SPEC/ui/game-map-narrow-detail-overlay-slot.md` § Open / close
// motion.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/province_detail_panel_slide_transition.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceDetailPanelSlideTransition (Refs #2865 S8)', () {
    testWidgets('mounts AnimatedSwitcher with 200 ms duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvinceDetailPanelSlideTransition(
            visible: true,
            axis: ProvinceDetailPanelSlideAxis.bottom,
            child: Text('panel'),
          ),
        ),
      );

      final host = tester.widget<ProvinceDetailPanelSlideTransition>(
        find.byType(ProvinceDetailPanelSlideTransition),
      );
      expect(host.visible, isTrue);
      expect(host.axis, ProvinceDetailPanelSlideAxis.bottom);

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(ProvinceDetailPanelSlideTransition.kTransitionHostKey),
      );
      expect(switcher.duration, ProvinceDetailPanelSlideTransition.kDuration);
      expect(switcher.switchInCurve, Curves.easeOut);
      expect(switcher.switchOutCurve, Curves.easeIn);
    });

    testWidgets(
      'visible false keeps outgoing child mounted through first exit frame',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProvinceDetailPanelSlideTransition(
              visible: true,
              axis: ProvinceDetailPanelSlideAxis.bottom,
              child: const Text('panel-body'),
            ),
          ),
        );
        expect(find.text('panel-body'), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(
            home: ProvinceDetailPanelSlideTransition(
              visible: false,
              axis: ProvinceDetailPanelSlideAxis.bottom,
              child: Text('panel-body'),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('panel-body'), findsOneWidget);

        await tester.pump(ProvinceDetailPanelSlideTransition.kDuration);
      },
    );

    testWidgets('end axis aligns stack to centerRight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProvinceDetailPanelSlideTransition(
            visible: true,
            axis: ProvinceDetailPanelSlideAxis.end,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );

      final stack = tester.widget<Stack>(
        find.descendant(
          of: find.byType(ProvinceDetailPanelSlideTransition),
          matching: find.byType(Stack),
        ),
      );
      expect(stack.alignment, Alignment.centerRight);
    });
  });
}
