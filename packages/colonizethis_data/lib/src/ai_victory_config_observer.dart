/// Observer campaign quota and expansion-pressure helpers.
///
/// Extracted from the victory-config kitchen sink (Refs #4121). Public API
/// remains available via `ai_victory_config.dart` and the package barrel.
library;

import 'ai_victory_config_stalled_ow.dart';

/// Observer default start OW provinces per GP (Refs #2509).
const int kObserverDefaultStartOldWorldProvincesPerGp = 7;

/// True when zero-regiment survival peace may engage: below the observer
/// conquest quota and either in the stalled OW band or at terminal attrition
/// collapse (zero OW holdings; Refs #2847 § H8).
bool isZeroRegimentSurvivalOwContext(int oldWorldProvincesOwned) =>
    isBelowObserverConquestQuota(oldWorldProvincesOwned) &&
    (isStalledOldWorldExpansion(oldWorldProvincesOwned) ||
        oldWorldProvincesOwned == 0);

/// Default observer start OW provinces per GP plus the turn-100 conquest gate (+3).
const int kObserverConquestMinOwProvincesPerGp = 10;

/// Turn when near-quota GPs in EXPAND may enter COLONIAL-lite (Refs #2509 S10).
const int kObserverColonialLiteMinTurn = 120;

/// OW holdings at or above this while still below quota enables COLONIAL-lite.
const int kObserverColonialLiteNearQuotaOw = 9;

/// Civilian work threshold cap in DEVELOP phase (improvement-first; Refs #2509 S10).
const int kDevelopCivilianWorkThresholdCap = 5;

/// True when OW holdings have not yet met the observer per-GP conquest quota.
bool isBelowObserverConquestQuota(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp;

/// At or below the turn-100 observer per-GP conquest quota (stalled band + quota).
bool isAtObserverConquestQuotaBand(int oldWorldProvincesOwned) =>
    oldWorldProvincesOwned > 0 &&
    oldWorldProvincesOwned <= kObserverConquestMinOwProvincesPerGp;

/// Stalled band or still below the turn-100 observer per-GP conquest quota.
bool isObserverConquestExpansionPressure(int oldWorldProvincesOwned) =>
    isStalledOldWorldExpansion(oldWorldProvincesOwned) ||
    isBelowObserverConquestQuota(oldWorldProvincesOwned);

/// Minimum OW holdings before [consolidateGainsSoleGpPeaceTarget] may fire (quota + buffer).
const int kObserverConquestConsolidateMinOwProvinces =
    kObserverConquestMinOwProvincesPerGp + 2;
