// Evidence rules for dossier. SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.
// When diplomatic (or other) actions are applied, evidence rules add suspicion points per agenda type.
// Evidence is stored per (observer, subject, agenda type); only human observers receive entries.
library;

// `isAiControlledForEvidence` now lives in the diplomacy shared helpers so
// diplomacy resolvers can read AI-control without importing the dossier layer
// (Refs #3562). Re-exported here to preserve the existing public surface for
// callers that import this file directly (e.g. the colonizethis_logic barrel).
export '../diplomacy/diplomacy_shared_helpers.dart' show isAiControlledForEvidence;
export 'evidence_rules_apply.dart'
    show
        evidenceForDeclareWar,
        evidenceForEnvyResearchMirror,
        evidenceForIsolationistCallToArmsRefuse,
        evidenceForLandBattleVictory,
        evidenceForNavalBattleVictory,
        evidenceForOfferPeace;
export 'evidence_rules_predicates.dart'
    show hadCallToArmsRefusedWithTargetInAttackWindow;
