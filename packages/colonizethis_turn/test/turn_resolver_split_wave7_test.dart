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

  test('public trusted/untrusted entry points remain distinct barrel exports', () {
    expect(validateOrdersAndResolveTurn, isA<Function>());
    expect(validateOrdersAndResolveTurnFromTrustedOrders, isA<Function>());
    expect(resolveTurnForGame, isA<Function>());
    expect(resolveTurnForGameWithConfig, isA<Function>());
    expect(resolveTurn, isA<Function>());
  });
}
