// Init-game setup markdown tables. SPEC/program/init-game-tool.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'faction_setup_helpers.dart';

/// Formats faction setup and starting state as markdown tables.
String formatInitGameSetupMarkdown(Game game) {
  final buf = StringBuffer();
  buf.writeln('# Game Setup');
  buf.writeln();
  buf.writeln('## Faction Setup');
  buf.writeln();
  buf.writeln('| Faction | Type | Capital Province | Provinces Owned |');
  buf.writeln('|---------|------|------------------|-----------------|');

  final oldWorldProvinces = game.worldState.provincesForRegion(kRegionOldWorld);
  final newWorldProvinces = game.worldState.provincesForRegion(kRegionNewWorld);
  forEachSetupFaction(
    game,
    onPlayer: (p) {
      buf.writeln(
        factionSetupTableRow(
          displayLabel: p.displayName,
          factionId: p.id,
          typeLabel: 'Great Power',
          capitalProvinceId: p.capitalProvinceId,
          ownedProvinceIds: ownedProvinceIdsForFaction(oldWorldProvinces, p.id),
        ),
      );
    },
    onMinorNation: (m) {
      buf.writeln(
        factionSetupTableRow(
          displayLabel: m.displayName ?? m.id,
          factionId: m.id,
          typeLabel: 'Minor Nation',
          capitalProvinceId: m.capitalProvinceId,
          ownedProvinceIds: ownedProvinceIdsForFaction(oldWorldProvinces, m.id),
        ),
      );
    },
    onTribe: (t) {
      buf.writeln(
        factionSetupTableRow(
          displayLabel: t.displayName ?? t.id,
          factionId: t.id,
          typeLabel: 'Tribe',
          capitalProvinceId: t.capitalProvinceId,
          ownedProvinceIds: ownedProvinceIdsForFaction(newWorldProvinces, t.id),
        ),
      );
    },
  );

  buf.writeln();
  buf.writeln('## Faction Starting State');
  buf.writeln();
  buf.writeln('| Faction | Stockpile | Workers | Treasury | Units |');
  buf.writeln('|---------|-----------|---------|----------|-------|');

  forEachSetupFaction(
    game,
    onPlayer: (p) {
      final stock = p.stockpile.quantities.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.key}:${e.value}')
          .join(', ');
      final workers =
          '${p.workerPool.peasants}p/${p.workerPool.apprentices}a/${p.workerPool.journeymen}j/${p.workerPool.masters}m';
      final units = allUnitsFromWorld(
        game.worldState,
      ).where((u) => u.ownerId == p.id).length;
      buf.writeln(
        '| ${p.displayName} (${p.id}) | ${stock.isEmpty ? "—" : stock} | $workers | ${p.treasury} | $units |',
      );
    },
    onMinorNation: (m) {
      buf.writeln('| ${m.displayName ?? m.id} (${m.id}) | — | — | — | — |');
    },
    onTribe: (t) {
      buf.writeln('| ${t.displayName ?? t.id} (${t.id}) | — | — | — | — |');
    },
  );

  return buf.toString();
}
