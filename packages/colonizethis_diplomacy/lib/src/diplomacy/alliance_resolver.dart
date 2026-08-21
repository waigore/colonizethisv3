// Alliance resolver host: Join Empire/Colony + processAlliances re-exports.
// SPEC/program/diplomacy-resolution.md. Refs #4574.

export 'alliance_join_empire.dart'
    show
        absorbGreatPowerIntoGp,
        absorbMinorOrTribeIntoGp,
        isGreatPowerNearlyDefeatedForJoinEmpire,
        markTribeAsColony,
        resolveJoinEmpireColony;
export 'alliance_process.dart' show processAlliances;
