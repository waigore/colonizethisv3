import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3823).
///
/// Guards the shared bid-treasury-spend helper in the economy package.
/// `treasury_bid_budget.dart` owns `bidTreasurySpendForOrder`; the validator
/// must delegate to it instead of re-inlining price × quantity math.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/treasury_bid_budget.dart';

const _consumerRelativePath =
    'packages/colonizethis_economy/lib/src/economy/world_market/trade_order_validator.dart';

const _sharedSymbol = 'bidTreasurySpendForOrder';

const _sharedModuleImportToken = "treasury_bid_budget.dart'";

void main() {
  exit(runCheckEconomyBidTreasurySpendShared(Directory.current.path));
}

int runCheckEconomyBidTreasurySpendShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE(
      'ERROR: Missing shared bid-treasury-spend helper file: '
      '$_helperRelativePath',
    );
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  if (!helperSource.contains('$_sharedSymbol(')) {
    logE(
      'ERROR: $_helperRelativePath no longer defines `$_sharedSymbol`; '
      'bid spend must stay centralized (Refs #3823).',
    );
    return 1;
  }

  final consumerFile = File(p.join(root, _consumerRelativePath));
  if (!consumerFile.existsSync()) {
    logE('ERROR: Missing bid-spend consumer: $_consumerRelativePath');
    return 1;
  }
  final consumerSource = consumerFile.readAsStringSync();
  if (!consumerSource.contains(_sharedModuleImportToken) ||
      !consumerSource.contains('$_sharedSymbol(')) {
    logE(
      'ERROR: $_consumerRelativePath must import treasury_bid_budget.dart '
      'and call `$_sharedSymbol` instead of re-inlining bid spend (Refs #3823).',
    );
    return 1;
  }

  logI('Economy bid-treasury-spend shared-helper check passed.');
  return 0;
}
