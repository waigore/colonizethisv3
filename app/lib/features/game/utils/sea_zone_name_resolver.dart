import 'package:colonizethis_models/colonizethis_models.dart';

String seaZoneDisplayName({
  required Game game,
  required String regionId,
  required String seaZoneId,
}) {
  final localId = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  final prefixed = '$regionId|$localId';
  return game.worldState.seaZoneDisplayNameById[prefixed] ?? localId;
}
