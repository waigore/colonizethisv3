import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';

/// Slice A structural pins for turn wave-7 (Refs #4342): concern-split
/// `turn_resolver` siblings stay under the incoming 300-line ceiling and public
/// entry names remain on the package barrel.
void main() {
  final turnLib = Directory('lib/src/turn');

  int physicalLines(String relativePath) {
    final file = File('${turnLib.path}/$relativePath');
    expect(file.existsSync(), isTrue, reason: relativePath);
    return file.readAsLinesSync().length;
  }

  test('turn_resolver concern-split siblings are each ≤300 physical lines', () {
    expect(physicalLines('turn_resolver.dart'), lessThanOrEqualTo(300));
    expect(
      physicalLines('turn_resolver_order_entry.dart'),
      lessThanOrEqualTo(300),
    );
    expect(
      physicalLines('turn_resolver_world_state_stub.dart'),
      lessThanOrEqualTo(300),
    );
  });

  test('Slice B research/combat siblings are each ≤300 physical lines', () {
    expect(
      physicalLines('research_resolver_allocation.dart'),
      lessThanOrEqualTo(300),
    );
    expect(physicalLines('research_resolver.dart'), lessThanOrEqualTo(300));
    expect(physicalLines('combat_phase_helpers.dart'), lessThanOrEqualTo(300));
    expect(
      physicalLines('combat_phase_land_battle_apply.dart'),
      lessThanOrEqualTo(300),
    );
    expect(
      physicalLines('combat_phase_land_battle_outcome.dart'),
      lessThanOrEqualTo(300),
    );
  });

  test('public trusted/untrusted entry points remain distinct barrel exports', () {
    expect(validateOrdersAndResolveTurn, isA<Function>());
    expect(validateOrdersAndResolveTurnFromTrustedOrders, isA<Function>());
    expect(resolveTurnForGame, isA<Function>());
    expect(resolveTurnForGameWithConfig, isA<Function>());
    expect(resolveTurn, isA<Function>());
  });

  test('Slice C densified non-support suites are each ≤250 physical lines', () {
    int testPhysicalLines(String relativePath) {
      final file = File('test/$relativePath');
      expect(file.existsSync(), isTrue, reason: relativePath);
      return file.readAsLinesSync().length;
    }

    const densified = [
      'turn/diplomacy_phase_handler_test.dart',
      'turn_trace_army_move_order_events_test.dart',
      'research_extraction_integration_test.dart',
      'turn/world_market_phase_treasury_clamp_test.dart',
    ];
    for (final path in densified) {
      expect(
        testPhysicalLines(path),
        lessThanOrEqualTo(250),
        reason: path,
      );
    }
  });
}
