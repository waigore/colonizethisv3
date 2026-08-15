/// Maximum number of evidence entries kept per dossier (per (observer, subject)).
/// When the list would exceed this cap, the oldest entries are dropped so that
/// the evidence list remains capped and chronological.
/// SPEC/ai/ai-dossier.md § Evidence list cap.
const int kMaxDossierEvidenceEntries = 50;
