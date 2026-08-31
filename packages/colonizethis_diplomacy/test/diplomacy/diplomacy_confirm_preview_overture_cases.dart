import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_confirm_preview_shared.dart';

List<ConfirmPreviewCase> overtureConfirmPreviewCases() => [
  (
    name: 'consulate overture shows single treasury cost',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewMinorId,
      overtureStage: OvertureStage.tradeConsulate,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('£$overtureConsulateCost'));
      expect('£'.allMatches(body).length, 1);
      expect(body.toLowerCase(), contains('explore'));
      expect(body.toLowerCase(), contains('prospect'));
      expect(body.toLowerCase(), contains('first right'));
      expect(body, isNot(contains('-50')));
      expect(body, isNot(contains('-10')));
    },
  ),
  (
    name: 'consulate overture toward GP omits explore and prospect',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewTargetGp,
      overtureStage: OvertureStage.tradeConsulate,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body.toLowerCase(), isNot(contains('explore')));
      expect(body.toLowerCase(), isNot(contains('prospect')));
      expect(body.toLowerCase(), isNot(contains('purchase land')));
    },
  ),
  (
    name: 'join empire minor absorb omits province counts',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewMinorId,
      overtureStage: OvertureStage.joinEmpire,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('join your realm'));
      expect(body, contains('£'));
      expect(body.toLowerCase(), isNot(contains('province')));
    },
  ),
  (
    name: 'join empire tribe colony outcome',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewTribeId,
      overtureStage: OvertureStage.joinEmpire,
    ),
    targetDisplayName: 'Aztec',
    assertLines: (lines, body) {
      expect(body, contains('colony'));
    },
  ),
  (
    name: 'join empire toward nearly defeated GP uses absorption copy',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewTargetGp,
      overtureStage: OvertureStage.joinEmpire,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('nearly defeated'));
      expect(body, contains('absorbed'));
      expect(body, isNot(contains('£')));
    },
  ),
  (
    name: 'embassy overture shows single treasury cost',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewMinorId,
      overtureStage: OvertureStage.embassy,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('£$overtureEmbassyCost'));
      expect('£'.allMatches(body).length, 1);
      expect(body.toLowerCase(), contains('grant aid'));
      expect(body.toLowerCase(), contains('subsidy'));
      expect(body.toLowerCase(), contains('purchase land'));
      expect(body.toLowerCase(), contains('intervene'));
    },
  ),
  (
    name: 'nap overture states free cost and join empire path',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewMinorId,
      overtureStage: OvertureStage.nap,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('join empire'));
      expect(body.toLowerCase(), contains('declare war'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
];
