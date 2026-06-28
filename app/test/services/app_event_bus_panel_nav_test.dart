// Tests for the AppEventBusPanelNav.closePanelThenEmit helper.
// SPEC/program/app-ui-wiring.md (ClosePanelEvent -> follow-up ordering).

import 'package:colonizethis_app/core/services/app_event_bus_panel_nav.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('AppEventBusPanelNav.closePanelThenEmit', () {
    testWidgets(
      'emits ClosePanelEvent synchronously, then the follow-up once next frame',
      (tester) async {
        // A pumped widget tree ensures `tester.pump()` produces frames that
        // flush `addPostFrameCallback` callbacks.
        await tester.pumpWidget(const SizedBox.shrink());

        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        final followUp = OpenDialogEvent('train_military');
        bus.closePanelThenEmit(followUp);

        // Before a frame runs, only ClosePanelEvent has been emitted; the
        // follow-up is deferred to the post-frame callback.
        await tester.idle();
        expect(events, hasLength(1));
        expect(events.single, isA<ClosePanelEvent>());

        // After the next frame, the follow-up is emitted exactly once.
        tester.binding.scheduleFrame();
        await tester.pump();
        await tester.idle();
        expect(events, hasLength(2));
        expect(events.first, isA<ClosePanelEvent>());
        expect(identical(events[1], followUp), isTrue);
      },
    );

    testWidgets('does not re-emit the follow-up on subsequent frames', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final bus = AppEventBus.create();
      addTearDown(bus.dispose);
      final events = <AppEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      bus.closePanelThenEmit(
        const LocateMapTileEvent(
          tileKey: 'oldWorld|p1|0|0',
          regionId: 'oldWorld',
        ),
      );
      tester.binding.scheduleFrame();
      await tester.pump();
      tester.binding.scheduleFrame();
      await tester.pump();
      await tester.idle();

      expect(events, hasLength(2));
      expect(events.first, isA<ClosePanelEvent>());
      expect(events[1], isA<LocateMapTileEvent>());
    });
  });
}
