import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Table-driven cases for diplomacy confirm-preview densify (Refs #4341 AC4).
typedef ConfirmPreviewCase = ({
  String name,
  DiplomaticOrder order,
  String targetDisplayName,
  void Function(List<String> lines, String body) assertLines,
});

const previewHumanId = 'gp1';
const previewTargetGp = 'gp2';
const previewMinorId = 'minor1';
const previewTribeId = 'tribe1';

List<ConfirmPreviewCase> confirmPreviewCases() => [
  (
    name: 'break alliance includes immediate timing line only',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.breakAlliance,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(lines.any((l) => l.startsWith('When:')), isTrue);
      expect(lines.any((l) => l.contains('immediately')), isTrue);
      expect(lines.any((l) => l.contains('-50')), isFalse);
      expect(lines.any((l) => l.contains('-10')), isFalse);
    },
  ),
  (
    name: 'declare war states pair war and overture end without timing line',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
      expect(body.toLowerCase(), contains('war'));
      expect(body.toLowerCase(), contains('overtures'));
    },
  ),
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
      expect(body, contains('only on acceptance'));
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
    name: 'offer peace states conditional peace without timing line',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
      expect(body.toLowerCase(), contains('peace'));
      expect(body.toLowerCase(), contains('accept'));
    },
  ),
  (
    name: 'alliance states free cost and mutual-defence offer',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('treaty'));
      expect(body.toLowerCase(), contains('allied'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  (
    name:
        'set subsidy states buy surcharge and sell discount without vague market terms',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: previewMinorId,
      amount: 10,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('No per-turn gold charge'));
      expect(
        body,
        contains(
          subsidyFillPriceConsequence(
            targetDisplayName: 'Bavaria',
            percent: 10,
          ),
        ),
      );
      expect(body.toLowerCase(), isNot(contains('market terms are affected')));
      expect(body, isNot(contains('+0.2')));
      expect(body, isNot(contains('-50')));
      expect(body, isNot(contains('-10')));
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
      expect(body, contains('only on acceptance'));
    },
  ),
  (
    name: 'nap overture states free cost and pact offer',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: previewMinorId,
      overtureStage: OvertureStage.nap,
    ),
    targetDisplayName: 'Bavaria',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body, contains('Non-Aggression Pact'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  (
    name: 'establish ftp states free cost and favoured-trading terms',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishFtp,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('favoured-trading-partner'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  (
    name: 'boycott states colony trade embargo',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.boycott,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('colonies'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  (
    name: 'revoke boycott ends trade embargo copy',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.revokeBoycott,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('embargo'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
];

