/// Per-panel snapshot+expected-text matchers for the four E2E scenarios in
/// `app/integration_test/`.
///
/// Lifted from inline closures in `new_game_full_turn_e2e_test.dart`
/// (`expectCivilianPanelTexts` / `expectNavalPanelTexts` /
/// `expectProductionPanelTexts`) and the inline province-panel assertion in
/// `new_game_capital_panel_e2e_test.dart`. Each helper encapsulates the
/// panel-specific root key, snapshot global, expected-text builder, and
/// canonical phase name so future scenarios can compose the same recipe
/// without re-declaring the closure shape (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6).
///
/// Every helper forwards into [e2eExpectPanelTextsMatchSnapshot]
/// (`e2e_test_shared_panel_text_assertions.dart`) byte-identically. The
/// per-panel widget-test pins in
/// `app/test/e2e_expect_*_panel_matches_snapshot_test.dart` exercise the
/// composition and AC1 barrel wiring.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/test_support/civilian_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/naval_units_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/production_panel_e2e_expected_lines.dart';
import 'package:colonizethis_app/test_support/province_panel_e2e_expected_lines.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Phase name forwarded into [e2eExpectPanelTextsMatchSnapshot] by
/// [e2eExpectCivilianPanelMatchesE2eSnapshot]. Captured as a public constant
/// so AC8 timing tables keyed on `wait_until_found_civilian_panel` remain
/// stable across the lift, and any silent rename is caught by the widget-test
/// pin instead of by the slow CI lane.
const String kE2eExpectCivilianPanelTextsPhase =
    'wait_until_found_civilian_panel';

/// Phase name forwarded into [e2eExpectPanelTextsMatchSnapshot] by
/// [e2eExpectNavalPanelMatchesE2eSnapshot]. Captured as a public constant so
/// AC8 timing tables keyed on `wait_until_found_naval_panel` remain stable
/// across the lift.
const String kE2eExpectNavalPanelTextsPhase = 'wait_until_found_naval_panel';

/// Phase name forwarded into [e2eExpectPanelTextsMatchSnapshot] by
/// [e2eExpectProductionPanelMatchesE2eSnapshot]. Captured as a public
/// constant so AC8 timing tables keyed on
/// `wait_until_found_production_panel` remain stable across the lift.
const String kE2eExpectProductionPanelTextsPhase =
    'wait_until_found_production_panel';

/// Phase name forwarded into [e2eExpectPanelTextsMatchSnapshot] by
/// [e2eExpectProvincePanelMatchesE2eSnapshot]. The capital-panel scenario
/// pre-lift used `open_panel_province` here — capturing the literal so AC8
/// timing tables keep that attribution across the lift.
const String kE2eExpectProvincePanelTextsPhase = 'open_panel_province';

/// Timeout forwarded into [e2eExpectPanelTextsMatchSnapshot] by
/// [e2eExpectProvincePanelMatchesE2eSnapshot]. The pre-lift inline assertion
/// in `new_game_capital_panel_e2e_test.dart` passed an explicit 30s; the
/// civilian / naval / production wrappers used the 20s default
/// ([kE2eDefaultExpectPanelTextsTimeout]). The province panel mounts later
/// in its scenario, so the wider budget is preserved verbatim.
const Duration kE2eExpectProvincePanelTextsTimeout = Duration(seconds: 30);

/// Asserts the [CivilianUnitsPanel] rendered tree matches
/// [civilianUnitsPanelExpectedTexts] for the currently primed
/// [ctE2eCivilianPanelSnapshot].
///
/// Lifted from the inline `expectCivilianPanelTexts` closure in
/// `new_game_full_turn_e2e_test.dart` — the body now forwards into
/// [e2eExpectPanelTextsMatchSnapshot] with:
///
/// - `panelRootKey`: [kCtE2ECivilianPanelRootKey]
/// - `snapshot`: [ctE2eCivilianPanelSnapshot]
/// - `buildExpected`: closure over the (non-null) snapshot + [l10n]
/// - `phaseName`: [kE2eExpectCivilianPanelTextsPhase]
/// - `timeout`: [kE2eDefaultExpectPanelTextsTimeout]
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
Future<void> e2eExpectCivilianPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) async {
  await e2eWaitUntilFound(
    tester,
    find.byKey(kCtE2ECivilianPanelRootKey),
    timeout: kE2eDefaultExpectPanelTextsTimeout,
    perf: perf,
    phaseName: kE2eExpectCivilianPanelTextsPhase,
  );
  await e2ePrepareCivilianPanelListForTextCollection(tester);
  await e2eExpectPanelTextsMatchSnapshot(
    tester,
    panelRootKey: kCtE2ECivilianPanelRootKey,
    snapshotReader: () => ctE2eCivilianPanelSnapshot,
    buildExpected: () =>
        civilianUnitsPanelExpectedTexts(ctE2eCivilianPanelSnapshot!, l10n),
    phaseName: kE2eExpectCivilianPanelTextsPhase,
    perf: perf,
  );
}

/// Asserts the [NavalUnitsPanel] rendered tree matches
/// [navalUnitsPanelExpectedTexts] for the currently primed
/// [ctE2eNavalPanelSnapshot].
///
/// When [expanded] is `true`, falls back via the helper's
/// `buildAlternativeExpected` to the `fleetTilesExpanded: false` mirror so
/// the post-tap expansion settle that lands on the collapsed variant still
/// passes — this preserves the pre-lift `anyOf` semantics from the inline
/// `expectNavalPanelTexts` closure in `new_game_full_turn_e2e_test.dart`.
///
/// Forwards into [e2eExpectPanelTextsMatchSnapshot] with:
///
/// - `panelRootKey`: [kCtE2ENavalPanelRootKey]
/// - `snapshot`: [ctE2eNavalPanelSnapshot]
/// - `phaseName`: [kE2eExpectNavalPanelTextsPhase]
/// - `timeout`: [kE2eDefaultExpectPanelTextsTimeout]
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
Future<void> e2eExpectNavalPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  required bool expanded,
  E2ePerfLog? perf,
}) => e2eExpectPanelTextsMatchSnapshot(
  tester,
  panelRootKey: kCtE2ENavalPanelRootKey,
  snapshotReader: () => ctE2eNavalPanelSnapshot,
  buildExpected: () => navalUnitsPanelExpectedTexts(
    ctE2eNavalPanelSnapshot!,
    l10n,
    fleetTilesExpanded: expanded,
  ),
  phaseName: kE2eExpectNavalPanelTextsPhase,
  perf: perf,
  buildAlternativeExpected: expanded
      ? () => navalUnitsPanelExpectedTexts(
          ctE2eNavalPanelSnapshot!,
          l10n,
          fleetTilesExpanded: false,
        )
      : null,
  // The dense fleet-action cluster (Move / Split / Locate) renders Move and
  // Split icon-only at the narrow macOS test host but as Icon + Text on the
  // wider Linux desktop integration host, so the canonical icon-only mirror
  // (which omits these labels) would spuriously fail on Linux. Normalize the
  // two host-width-dependent labels out of the collected texts so the
  // assertion is deterministic across hosts; Locate is always icon-only and
  // Combine is a non-dense top-level action the mirror keeps (Refs GitHub
  // #2336 AC6).
  ignoreActualTexts: [l10n.common_move, l10n.common_split],
);

/// Asserts the wide [ProductionPanel] rendered tree matches
/// [productionPanelWideExpectedTexts] for the currently primed
/// [ctE2eProductionPanelSnapshot].
///
/// Lifted from the inline `expectProductionPanelTexts` closure in
/// `new_game_full_turn_e2e_test.dart` — the body now forwards into
/// [e2eExpectPanelTextsMatchSnapshot] with:
///
/// - `panelRootKey`: [kCtE2EProductionPanelRootKey]
/// - `snapshot`: [ctE2eProductionPanelSnapshot]
/// - `buildExpected`: closure over the (non-null) snapshot + [l10n]
/// - `phaseName`: [kE2eExpectProductionPanelTextsPhase]
/// - `timeout`: [kE2eDefaultExpectPanelTextsTimeout]
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
Future<void> e2eExpectProductionPanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectPanelTextsMatchSnapshot(
  tester,
  panelRootKey: kCtE2EProductionPanelRootKey,
  snapshotReader: () => ctE2eProductionPanelSnapshot,
  buildExpected: () =>
      productionPanelWideExpectedTexts(ctE2eProductionPanelSnapshot!, l10n),
  phaseName: kE2eExpectProductionPanelTextsPhase,
  perf: perf,
);

/// Asserts the wide-layout province detail panel rendered tree matches
/// [provincePanelWideLayoutExpectedTexts] for the currently primed
/// [ctE2eLastPanelSnapshot].
///
/// Lifted from the inline `expectPanelTextsMatchSnapshot` call site in
/// `new_game_capital_panel_e2e_test.dart` — the body now forwards into
/// [e2eExpectPanelTextsMatchSnapshot] with:
///
/// - `panelRootKey`: [kCtE2EProvincePanelRootKey]
/// - `snapshot`: [ctE2eLastPanelSnapshot]
/// - `buildExpected`: closure over the (non-null) snapshot + [l10n]
/// - `phaseName`: [kE2eExpectProvincePanelTextsPhase]
/// - `timeout`: [kE2eExpectProvincePanelTextsTimeout] (30 s — the
///   capital-panel scenario mounts the province panel later in its run, so
///   the pre-lift call passed the wider budget explicitly).
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
Future<void> e2eExpectProvincePanelMatchesE2eSnapshot(
  WidgetTester tester,
  AppLocalizations l10n, {
  E2ePerfLog? perf,
}) => e2eExpectPanelTextsMatchSnapshot(
  tester,
  panelRootKey: kCtE2EProvincePanelRootKey,
  snapshotReader: () => ctE2eLastPanelSnapshot,
  buildExpected: () =>
      provincePanelWideLayoutExpectedTexts(ctE2eLastPanelSnapshot!, l10n),
  phaseName: kE2eExpectProvincePanelTextsPhase,
  timeout: kE2eExpectProvincePanelTextsTimeout,
  perf: perf,
);
