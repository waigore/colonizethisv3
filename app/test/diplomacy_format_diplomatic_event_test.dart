// formatDiplomaticEvent — all [DiplomaticEventType] branches. SPEC/ui/diplomacy-panel.md.
import 'package:colonizethis_app/features/game/screens/diplomacy/diplomacy_detail_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_format_diplomatic_event_fixtures.dart';

void main() {
  suppressLogsForTests();

  test('declareWar', () {
    final g = diplomacyFormatMinimalGame();
    final s = formatDiplomaticEvent(
      diplomacyFormatEvent(DiplomaticEventType.declareWar),
      g,
      diplomacyFormatHumanId,
    );
    expect(s, contains('declared war'));
  });

  test('peace', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.peace),
        g,
        diplomacyFormatHumanId,
      ),
      contains('peace'),
    );
  });

  test('allianceFormed', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.allianceFormed),
        g,
        diplomacyFormatHumanId,
      ),
      contains('alliance'),
    );
  });

  test('allianceBroken', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.allianceBroken),
        g,
        diplomacyFormatHumanId,
      ),
      contains('Alliance'),
    );
  });

  test('overtureAccepted with stage', () {
    final g = diplomacyFormatMinimalGame();
    final s = formatDiplomaticEvent(
      diplomacyFormatEvent(
        DiplomaticEventType.overtureAccepted,
        stage: OvertureStage.embassy,
      ),
      g,
      diplomacyFormatHumanId,
    );
    expect(s, contains('Embassy'));
  });

  test('overtureRejected', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(
          DiplomaticEventType.overtureRejected,
          stage: OvertureStage.nap,
        ),
        g,
        diplomacyFormatHumanId,
      ),
      contains('rejected'),
    );
  });

  test('grantAidApplied', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.grantAidApplied, amount: 100),
        g,
        diplomacyFormatHumanId,
      ),
      contains('100'),
    );
  });

  test('subsidySet', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.subsidySet, amount: 5),
        g,
        diplomacyFormatHumanId,
      ),
      contains('5'),
    );
  });

  test('subsidyUpdated', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.subsidyUpdated, amount: 7),
        g,
        diplomacyFormatHumanId,
      ),
      contains('7'),
    );
  });

  test('subsidyCancelled', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(
          DiplomaticEventType.subsidyCancelled,
          reason: 'treasury',
        ),
        g,
        diplomacyFormatHumanId,
      ),
      contains('treasury'),
    );
  });

  test('interventionIntervene', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.interventionIntervene),
        g,
        diplomacyFormatHumanId,
      ),
      contains('intervened'),
    );
  });

  test('interventionDoNothing', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.interventionDoNothing),
        g,
        diplomacyFormatHumanId,
      ),
      contains('did not intervene'),
    );
  });

  test('interventionProtest', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.interventionProtest),
        g,
        diplomacyFormatHumanId,
      ),
      contains('protested'),
    );
  });

  test('agreementsClearedOnWar', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.agreementsClearedOnWar),
        g,
        diplomacyFormatHumanId,
      ),
      contains('war'),
    );
  });

  test('callToArmsAccepted', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.callToArmsAccepted),
        g,
        diplomacyFormatHumanId,
      ),
      contains('joined the war'),
    );
  });

  test('callToArmsRefused', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.callToArmsRefused),
        g,
        diplomacyFormatHumanId,
      ),
      contains('refused call to arms'),
    );
  });

  test('ftpFormed', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(DiplomaticEventType.ftpFormed),
        g,
        diplomacyFormatHumanId,
      ),
      contains('free trade partnership'),
    );
  });

  test('ftpBroken', () {
    final g = diplomacyFormatMinimalGame();
    expect(
      formatDiplomaticEvent(
        diplomacyFormatEvent(
          DiplomaticEventType.ftpBroken,
          reason: 'war',
        ),
        g,
        diplomacyFormatHumanId,
      ),
      contains('ended (war)'),
    );
  });
}
