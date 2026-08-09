import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('general medal gained feed line uses province context', () {
    final entries = buildCtTurnFeedEntries(
      events: const [
        AppGeneralMedalGainedEvent(
          playerId: 'gp1',
          generalId: 'g1',
          provinceId: 'oldWorld|cap',
          newMedals: 2,
          turnNumber: 5,
        ),
      ],
      context: CtTurnFeedEntryContext(
        mapPlayerId: 'gp1',
        factionLabel: (id) => id,
        provinceLabel: (id) => id == 'oldWorld|cap' ? 'Capital' : id,
        seaZoneLabel: (id) => id,
        diplomacyOutcomeLine:
            ({required actorId, required targetId, required changeType}) =>
                '$actorId $changeType $targetId',
        isCatalogTech: (_) => false,
        researchCompleteLine: (techId) => techId,
        navigateToTechnologyScreen: () {},
        workTargetLabel: (target) => target,
        overtureStageLabel: (stage) => stage,
        locateProvinceById: (_) {},
        locateSeaZoneTile: (_) {},
        counterpartFactionId:
            ({required actorId, required targetId}) => targetId,
        overtureCounterpartFactionId:
            ({required offererGpId, required targetFactionId}) =>
                targetFactionId,
        spyCounterpartFactionId:
            ({required spyOwnerId, required territoryOwnerId}) => spyOwnerId,
        diplomacyDetailTapForFaction: (_) => null,
        provinceOverlayTapForProvince: (_) => null,
        navalCombatTapForSeaZone: (_) => null,
        workOrderCompletedTap: ({required unitId, required targetTileKey}) =>
            null,
        overseasProfitCreditedTap: null,
        orderRejectedTapForKind: (_) => null,
      ),
    );

    expect(entries, hasLength(1));
    expect(
      entries.single.text,
      'Victory at Capital: a general earned a medal (now 2).',
    );
  });
}
