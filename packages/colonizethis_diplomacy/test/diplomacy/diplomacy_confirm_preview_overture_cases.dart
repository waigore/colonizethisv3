import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
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
      expect(body.toLowerCase(), contains(kWorkTargetExplore));
      expect(body.toLowerCase(), contains(kWorkTargetProspect));
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
      expect(body.toLowerCase(), isNot(contains(kWorkTargetExplore)));
      expect(body.toLowerCase(), isNot(contains(kWorkTargetProspect)));
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
      expect(body.toLowerCase(), contains('absorbed'));
      expect(body.toLowerCase(), contains('land'));
      expect(body.toLowerCase(), contains('armies'));
      expect(body.toLowerCase(), contains('fleets'));
      expect(body.toLowerCase(), contains('leave the map'));
      expect(body, contains('£'));
      expect('£'.allMatches(body).length, 1);
      expect(body, isNot(contains(RegExp(r'\d+\s+province', caseSensitive: false))));
      expect(body, isNot(contains('-50')));
      expect(body, isNot(contains('-10')));
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
      expect(body.toLowerCase(), contains('colony'));
      expect(body.toLowerCase(), contains('own ownership'));
      expect(body.toLowerCase(), contains('does not become yours'));
      expect(body, contains('31 Old World provinces'));
      expect(body.toLowerCase(), isNot(contains('absorbed')));
      expect(body.toLowerCase(), isNot(contains('provinces transfer')));
      expect(body, contains('£'));
      expect('£'.allMatches(body).length, 1);
      expect(body, isNot(contains(RegExp(r'\d+\s+province', caseSensitive: false))));
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
      expect(body.toLowerCase(), contains('absorbed'));
      expect(body.toLowerCase(), contains('land'));
      expect(body.toLowerCase(), contains('armies'));
      expect(body.toLowerCase(), contains('fleets'));
      expect(body.toLowerCase(), contains('leaves the map'));
      expect(body, contains('No treasury charge'));
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
