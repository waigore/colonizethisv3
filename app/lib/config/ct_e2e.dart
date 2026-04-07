import 'package:flutter/material.dart';

/// Compile-time flag for integration / e2e builds only.
/// Pass `--dart-define=CT_E2E=true` when running `flutter test integration_test/ …`.
/// **SPEC:** `SPEC/program/e2e-integration-tests.md`.
const bool kCtE2EEnabled = bool.fromEnvironment('CT_E2E', defaultValue: false);

// ignore: public_member_api_docs — keys are documented in SPEC/program/e2e-integration-tests.md
/// Opens province detail for the human capital tile (same as a map tap) without Flame hit-testing.
const Key kCtE2EOpenCapitalProvinceDetailKey = Key('ct_e2e_open_capital_province_detail');

// ignore: public_member_api_docs
/// Root of the wide-layout province side panel subtree (for collecting [Text] in tree order).
const Key kCtE2EProvincePanelRootKey = Key('ct_e2e_province_panel_root');
