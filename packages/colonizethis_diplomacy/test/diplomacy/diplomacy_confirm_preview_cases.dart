import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

export 'diplomacy_confirm_preview_shared.dart';
import 'diplomacy_confirm_preview_overture_cases.dart';
import 'diplomacy_confirm_preview_shared.dart';

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
    name: 'establish ftp states free cost and favoured-trading terms',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishFtp,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body, contains('Favored Trading Partners'));
      expect(body, contains('same bid rank'));
      expect(body, contains('Prices do not change'));
      expect(body, contains('First right of refusal'));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
      expect(body, isNot(contains('65')));
    },
  ),
  (
    name: 'boycott states full colony embargo effects',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.boycott,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body, contains('will not fill in either direction'));
      expect(body.toLowerCase(), contains('purchase land'));
      expect(body.toLowerCase(), contains('grant aid'));
      expect(body.toLowerCase(), contains('subsid'));
      expect(body.toLowerCase(), contains('cancelled'));
      expect(body, contains('Aztec'));
      expect(body, isNot(contains(previewTribeId)));
      expect(body, isNot(contains('-50')));
      expect(body, isNot(contains('-10')));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  (
    name: 'revoke boycott restores trade and court work copy',
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.revokeBoycott,
      targetFactionId: previewTargetGp,
    ),
    targetDisplayName: 'Spain',
    assertLines: (lines, body) {
      expect(body, contains('No treasury charge'));
      expect(body.toLowerCase(), contains('embargo'));
      expect(body.toLowerCase(), contains('purchase land'));
      expect(body.toLowerCase(), contains('grant aid'));
      expect(body, contains('Aztec'));
      expect(body, isNot(contains(previewTribeId)));
      expect(lines.any((l) => l.startsWith('When:')), isFalse);
    },
  ),
  ...overtureConfirmPreviewCases(),
];
