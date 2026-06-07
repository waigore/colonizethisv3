/// Home army id for a Great Power player. Parallels [homeFleetIdFor] in naval.dart.
String homeArmyIdFor(String playerId) => 'army_$playerId';

/// Deterministic id for a non-home army holding regiments in one province.
String fieldArmyIdFor(String ownerId, String fullProvinceId) =>
    'army_field_${ownerId}_${fullProvinceId.replaceAll('|', '_')}';
