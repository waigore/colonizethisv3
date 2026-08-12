// Shared Game fixtures for dossier perception pins (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

Game dossierGameWithEvidence(List<DossierEvidenceEntry> entries) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'obs', displayName: 'Observer', isHuman: true),
      Player(id: 'subj', displayName: 'Subject', isHuman: false),
    ],
    dossierEvidenceEntries: entries,
  );
}
