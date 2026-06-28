import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Catalog effect-or-prerequisite audit (Slice D of issue #3470).
///
/// SPEC/game/tech-tree.md § Acceptance Criteria: every catalog tech must have at
/// least one of a structural effect (regiment unlock, ship unlock, extraction-cap
/// entry, discovery-resource gate), a documented runtime effect hook, or at least
/// one dependent in the prerequisite graph. This guards against silently adding a
/// tech with no gameplay effect and no prerequisite role.
///
/// Techs whose only catalog footprint is a runtime effect hook (no structural
/// effect data and no dependent) must be listed here with their documented effect.
/// Effect copy is authored in colonizethis_data tech_effect_summary.yaml and the
/// app localization (techEffectSummary_*). Adding a new terminal tech with a real
/// runtime effect requires adding it here (and wiring the effect); a terminal tech
/// with no effect at all will (correctly) fail this audit.
const Map<String, String> _documentedRuntimeEffectTechIds = {
  // Enables fabric_from_cotton production recipe (per-player, tech-gated).
  // SPEC/game/tech-tree-new-world.md; recipe gate tracked by issue #3470 Slice C.
  kTechIdCottonWeaving: 'Enables cloth production from cotton (recipe gate).',
  // Enables the Join Empire diplomatic overture toward nearly-defeated GPs.
  // SPEC/game/diplomacy.md.
  kTechIdEmpireBuilding: 'Enables the Join Empire diplomatic overture.',
  // Upgrades defender emplaced fort batteries to Siege Gun quality (final tier).
  // SPEC/game/tech-tree-military.md.
  kTechIdEmplacedSiegeGuns: 'Improves defender emplaced fort batteries to Siege Gun quality.',
};

/// Returns true when [techId] satisfies the effect-or-prerequisite role per
/// SPEC/game/tech-tree.md. [dependents] is the set of tech ids that appear as a
/// prerequisite of at least one tech in [catalog].
bool _hasEffectOrPrereqRole(
  String techId,
  TechDefinition def, {
  required Set<String> dependents,
  required Set<String> extractionTechIds,
  required Map<String, String> documentedRuntimeEffects,
}) {
  if (def.regimentUnlockIds.isNotEmpty) return true;
  if (def.shipUnlockIds.isNotEmpty) return true;
  if (def.discoveryResourceIds?.isNotEmpty ?? false) return true;
  if (extractionTechIds.contains(techId)) return true;
  if (documentedRuntimeEffects.containsKey(techId)) return true;
  if (dependents.contains(techId)) return true;
  return false;
}

Set<String> _dependentsOf(Map<String, TechDefinition> catalog) => {
  for (final def in catalog.values) ...def.prerequisiteIds,
};

void main() {
  group('tech catalog effect-or-prerequisite audit', () {
    test('every catalog tech has a structural effect, documented runtime effect, or dependent', () {
      final dependents = _dependentsOf(techCatalog);
      final extractionTechIds = extractionCapTechIds;

      final offenders = <String>[];
      techCatalog.forEach((id, def) {
        final ok = _hasEffectOrPrereqRole(
          id,
          def,
          dependents: dependents,
          extractionTechIds: extractionTechIds,
          documentedRuntimeEffects: _documentedRuntimeEffectTechIds,
        );
        if (!ok) offenders.add(id);
      });

      expect(
        offenders,
        isEmpty,
        reason:
            'These techs have no structural effect, no documented runtime effect, and no '
            'dependent. Wire an effect or document the runtime hook in '
            '_documentedRuntimeEffectTechIds: $offenders',
      );
    });

    test('documented runtime-effect set only lists real catalog techs (no stale entries)', () {
      for (final id in _documentedRuntimeEffectTechIds.keys) {
        expect(
          techCatalog.containsKey(id),
          isTrue,
          reason: 'Documented runtime-effect tech "$id" is not in the catalog',
        );
      }
    });

    test('documented runtime-effect set is minimal: each listed tech genuinely needs it', () {
      // A listed tech "needs" the documented entry only if it has no structural
      // effect AND no dependent; otherwise it would pass without the entry and the
      // documentation would be misleading.
      final dependents = _dependentsOf(techCatalog);
      final extractionTechIds = extractionCapTechIds;
      for (final id in _documentedRuntimeEffectTechIds.keys) {
        final def = techCatalog[id]!;
        final hasStructural = def.regimentUnlockIds.isNotEmpty ||
            def.shipUnlockIds.isNotEmpty ||
            (def.discoveryResourceIds?.isNotEmpty ?? false) ||
            extractionTechIds.contains(id);
        expect(
          hasStructural || dependents.contains(id),
          isFalse,
          reason:
              'Tech "$id" already passes via a structural effect or a dependent, so it '
              'does not need a documented-runtime-effect entry. Remove it to keep the '
              'audit honest.',
        );
      }
    });

    test('negative: a tech with no effect and no dependent fails the audit', () {
      const phantom = TechDefinition(
        id: 'phantom_no_effect_tech',
        era: 1,
        category: 'military',
        cost: 100,
      );
      final result = _hasEffectOrPrereqRole(
        phantom.id,
        phantom,
        dependents: const <String>{},
        extractionTechIds: const <String>{},
        documentedRuntimeEffects: const <String, String>{},
      );
      expect(result, isFalse,
          reason: 'A tech with no structural effect, no documented runtime effect, '
              'and no dependent must fail the audit classifier');
    });
  });
}
