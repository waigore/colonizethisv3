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
