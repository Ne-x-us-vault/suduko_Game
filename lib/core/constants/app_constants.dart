/// Application-wide constants for the QUEENS game.
library;

/// Puzzle engine generator version. Bump when generation changes incompatibly
/// so puzzle identity stays reproducible.
const int kGeneratorVersion = 1;

/// Persistence schema version for the local data store.
const int kSchemaVersion = 1;

/// Supported board sizes (production).
const List<int> kSupportedBoardSizes = [5, 6, 7, 8, 9, 10];

/// Default board sizes for quick play by difficulty.
const Map<String, int> kDefaultSizeByPlay = {
  'easy': 6,
  'medium': 7,
  'hard': 8,
  'expert': 9,
};

/// Maximum generation attempts before giving up on a seed combo.
const int kMaxGenerationAttempts = 400;

/// Generation per-attempt timeout (milliseconds).
const int kGenerationTimeoutMillis = 2000;

/// How many recent puzzle ids are kept to avoid immediate duplicates.
const int kRecentPuzzleIdPoolSize = 100;

/// App identifier used in share messages.
const String kAppName = 'QUEENS';

/// Current app version, kept in sync with pubspec.yaml.
const String kAppVersion = '1.0.0';

const String kSharePrefix = 'QUEENS';