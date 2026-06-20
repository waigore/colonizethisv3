import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

String seaZoneDisplayName({
  required Game game,
  required String regionId,
  required String seaZoneId,
}) {
  final localId = prefixedIdLocalSegment(seaZoneId);
  final prefixed = '$regionId|$localId';
  return game.worldState.seaZoneDisplayNameById[prefixed] ?? localId;
}
