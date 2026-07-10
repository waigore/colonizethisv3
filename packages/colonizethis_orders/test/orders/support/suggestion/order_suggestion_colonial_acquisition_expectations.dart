// Colonial acquisition suggestion assertions (Refs #2509, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';

/// Pins for [orderSuggestionColonialAcquisitionScenarios] rows.
enum OrderSuggestionColonialAcquisitionTarget {
  joinEmpireCandidateEmitted,
  declareWarCandidateEmitted,
  deterministicAcrossRepeatedCalls,
}

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void runOrderSuggestionColonialAcquisitionExpectation(
  OrderSuggestionColonialAcquisitionTarget target,
) {
  switch (target) {
    case OrderSuggestionColonialAcquisitionTarget.joinEmpireCandidateEmitted:
      final game = colonialAcquisitionEmbassyScenarioGame();
      final view = colonialAcquisitionViewFor(game);
      expect(
        knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: colonialAcquisitionTopology,
        ),
        contains('tribe1'),
      );
      final orders = _api.suggestDiplomaticOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final joinEmpireForTribe = orders.where(
        (o) =>
            o.targetFactionId == 'tribe1' &&
            o.type == DiplomaticOrderType.establishOverture &&
            o.overtureStage == OvertureStage.joinEmpire,
      );
      expect(
        joinEmpireForTribe,
        isNotEmpty,
        reason:
            'AC: merged orders may include establishOverture (Join Empire) '
            'when GP has embassy-stage overture and treasury covers cost',
      );

    case OrderSuggestionColonialAcquisitionTarget.declareWarCandidateEmitted:
      final game = colonialAcquisitionEmbassyScenarioGame();
      final view = colonialAcquisitionViewFor(game);
      final orders = _api.suggestDeclareWarOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      final declareForTribe = orders.where(
        (o) =>
            o.targetFactionId == 'tribe1' &&
            o.type == DiplomaticOrderType.declareWar,
      );
      expect(
        declareForTribe,
        isNotEmpty,
        reason:
            'AC: merged orders may include declareWar toward an at-peace '
            'tribe in the known target set (colonial-support weights must '
            'not gate emission); declare-war-only pass is independent of '
            'the per-target single-diplo cap in suggestDiplomaticOrders',
      );

    case OrderSuggestionColonialAcquisitionTarget
        .deterministicAcrossRepeatedCalls:
      final game = colonialAcquisitionEmbassyScenarioGame();
      final view = colonialAcquisitionViewFor(game);

      List<String> overtureKeys() => _api
          .suggestDiplomaticOrders(
            view,
            game,
            colonialAcquisitionTopology,
            _emptyOrders,
          )
          .map(colonialAcquisitionOrderKey)
          .toList();
      List<String> declareKeys() => _api
          .suggestDeclareWarOrders(
            view,
            game,
            colonialAcquisitionTopology,
            _emptyOrders,
          )
          .map(colonialAcquisitionOrderKey)
          .toList();

      final overtureFirst = overtureKeys();
      final overtureSecond = overtureKeys();
      final declareFirst = declareKeys();
      final declareSecond = declareKeys();

      expect(
        overtureSecond,
        equals(overtureFirst),
        reason:
            'AC: deterministic for fixed seed (suggestDiplomaticOrders '
            'returns the same candidate set every pass)',
      );
      expect(
        declareSecond,
        equals(declareFirst),
        reason:
            'AC: deterministic for fixed seed (suggestDeclareWarOrders '
            'returns the same candidate set every pass)',
      );
      expect(
        overtureFirst,
        contains('establishOverture:tribe1:joinEmpire'),
        reason:
            'deterministic Join Empire candidate must appear in the '
            'overture-pass suggestions',
      );
      expect(
        declareFirst,
        contains('declareWar:tribe1:'),
        reason:
            'deterministic declare-war candidate must appear in the '
            'declare-war-only pass suggestions',
      );
  }
}
