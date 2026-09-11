// Host gating and emit pins for MAP20001 capital Train (Refs #4769).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_train_military.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';

void main() {
  suppressLogsForTests();

  late AppEventBus bus;

  setUp(() {
    bus = AppEventBus.create();
  });

  tearDown(() {
    bus.dispose();
  });

  ProvinceTrainMilitaryOverlayControls controls({
    required String displayId,
    required String capitalProvinceId,
    bool canMutateViaUi = true,
    bool isSeaZone = false,
    bool omniscientDetail = true,
  }) {
    final base = provinceDetailMinimalGame();
    final human = base.players.first;
    final game = base.copyWith(
      players: [human.copyWith(capitalProvinceId: capitalProvinceId)],
    );
    return buildProvinceTrainMilitaryOverlayControls(
      game: game,
      region: provinceDetailEmptyRegion(),
      humanPlayerId: provinceDetailSupportPlayerId,
      playerView: provinceDetailPlayerView(game),
      displayId: displayId,
      canMutateViaUi: canMutateViaUi,
      omniscientDetail: omniscientDetail,
      bus: bus,
      isSeaZone: isSeaZone,
    );
  }

  test('shows Train on the human capital', () {
    final c = controls(
      displayId: 'oldWorld|p1',
      capitalProvinceId: 'oldWorld|p1',
    );
    expect(c.show, isTrue);
    expect(c.onTap, isNotNull);
  });

  test('hides Train on a human-owned non-capital province', () {
    final c = controls(
      displayId: 'oldWorld|p2',
      capitalProvinceId: 'oldWorld|p1',
    );
    expect(c.show, isFalse);
    expect(c.onTap, isNull);
  });

  test('hides Train on a foreign capital', () {
    final c = controls(
      displayId: 'oldWorld|foreign_cap',
      capitalProvinceId: 'oldWorld|p1',
    );
    expect(c.show, isFalse);
  });

  test('hides Train on a sea-zone', () {
    final c = controls(
      displayId: 'oldWorld|p1',
      capitalProvinceId: 'oldWorld|p1',
      isSeaZone: true,
    );
    expect(c.show, isFalse);
  });

  test('hides Train when observe cannot mutate', () {
    final c = controls(
      displayId: 'oldWorld|p1',
      capitalProvinceId: 'oldWorld|p1',
      canMutateViaUi: false,
    );
    expect(c.show, isFalse);
  });

  test('tap emits OpenDialogEvent without panel close or hire', () async {
    final opened = <OpenDialogEvent>[];
    final panels = <OpenMilitaryUnitsPanelEvent>[];
    final closes = <ClosePanelEvent>[];
    bus.on<OpenDialogEvent>().listen(opened.add);
    bus.on<OpenMilitaryUnitsPanelEvent>().listen(panels.add);
    bus.on<ClosePanelEvent>().listen(closes.add);
    final c = controls(
      displayId: 'oldWorld|p1',
      capitalProvinceId: 'oldWorld|p1',
    );
    c.onTap!();
    await Future<void>.delayed(Duration.zero);
    expect(opened, hasLength(1));
    expect(opened.single.dialogId, trainMilitaryDialogId);
    expect(opened.single.params, isNull);
    expect(panels, isEmpty);
    expect(closes, isEmpty);
  });
}
