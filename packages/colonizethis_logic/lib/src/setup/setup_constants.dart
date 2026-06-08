/// Setup-domain constants so the `setup/` tree can move into a future
/// `colonizethis_setup` package without depending on the thin logic core
/// `constants.dart` barrel (Refs #3290 C2 prerequisite).
library;

/// Default sea fraction for map generation (0.6 = 60% sea, 40% land).
const double kDefaultSeaFraction = 0.6;
