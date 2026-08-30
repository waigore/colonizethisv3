/// Shared constants for industry counsel scoring (AI core path).
library;

/// Shortage target below which a commodity is considered needed.
const int kIndustryCounselShortageThreshold = 8;

/// Weight for shortage component in recipe score.
const double kIndustryCounselShortageWeight = 2.0;

/// Weight for chain/luxury value.
const double kIndustryCounselChainWeight = 1.0;

/// Weight for agenda/personality modifier.
const double kIndustryCounselAgendaWeight = 0.5;

const int kIndustryCounselVeryLargeRuns = 999999;

/// Agenda id that yields zero agenda contribution in recipe scoring.
const String kIndustryCounselNeutralAgendaId = '';

/// When true, growth-stage scoring replaces plain recipe scoring in counsel.
const bool kIndustryCounselGrowthStageEnabled = false;

/// Additive bias so in-stage low-shortage recipes can win.
const double kIndustryCounselGrowthStagePriorityBias = 16.0;

const double kIndustryCounselMinCategoryFloor = 0.1;

const int kIndustryCounselTargetLabourForMaturity = 12;
const int kIndustryCounselTargetFeedstockTileCount = 6;
const int kIndustryCounselMinLabourForMilitary = 6;
const int kIndustryCounselLabourRangeForMilitary = 6;
const int kIndustryCounselReserveTarget = 20;
const double kIndustryCounselAtWarMilitaryFloor = 0.3;

const Set<String> kIndustryCounselCriticalFeedstockResourceIds = {
  'wool',
  'cotton',
  'timber',
  'iron',
  'coal',
};
