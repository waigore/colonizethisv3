import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Asserts two digests carry the same resolved turn and identical ordered lines.
void expectDigestLinesEqual(TurnNewsDigest a, TurnNewsDigest b) {
  expect(a.resolvedTurnNumber, b.resolvedTurnNumber);
  expect(a.lines.length, b.lines.length);
  for (var i = 0; i < a.lines.length; i++) {
    expectLineEqual(a.lines[i], b.lines[i]);
  }
}

/// Asserts two news lines are the same kind with equal payload fields.
void expectLineEqual(TurnNewsLine x, TurnNewsLine y) {
  expect(x.runtimeType, y.runtimeType);
  switch ((x, y)) {
    case (
      TurnNewsProvinceCapturedLine(
        provinceId: final ap,
        previousOwnerId: final a1,
        newOwnerId: final a2,
      ),
      TurnNewsProvinceCapturedLine(
        provinceId: final bp,
        previousOwnerId: final b1,
        newOwnerId: final b2,
      ),
    ):
      expect(ap, bp);
      expect(a1, b1);
      expect(a2, b2);
    case (
      TurnNewsDiplomacyLine(
        factionIdA: final aa,
        factionIdB: final ab,
        kind: final ak,
      ),
      TurnNewsDiplomacyLine(
        factionIdA: final ba,
        factionIdB: final bb,
        kind: final bk,
      ),
    ):
      expect(aa, ba);
      expect(ab, bb);
      expect(ak, bk);
    case (
      TurnNewsOvertureAdvancedLine(
        offererGpId: final ao,
        targetFactionId: final at,
        newStage: final as_,
      ),
      TurnNewsOvertureAdvancedLine(
        offererGpId: final bo,
        targetFactionId: final bt,
        newStage: final bs,
      ),
    ):
      expect(ao, bo);
      expect(at, bt);
      expect(as_, bs);
    case (
      TurnNewsProvinceDiscoveredLine(provinceId: final ap),
      TurnNewsProvinceDiscoveredLine(provinceId: final bp),
    ):
      expect(ap, bp);
    case (
      TurnNewsSeaZoneFleetLine(seaZoneId: final az),
      TurnNewsSeaZoneFleetLine(seaZoneId: final bz),
    ):
      expect(az, bz);
    default:
      fail('Unexpected line pair: $x vs $y');
  }
}
