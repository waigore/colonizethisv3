"""Well-known names and defaults for Daytona infra (Refs #2065)."""

# Sticky default Snapshot name (override with DAYTONA_SNAPSHOT_NAME).
DEFAULT_DAYTONA_SNAPSHOT_NAME = "colonizethis-daytona-flutter-tools"

# Local tag after `docker build` step 1.
DEFAULT_LOCAL_IMAGE_TAG = "colonizethis-daytona-flutter-tools:local"

# OpenCode default model — matches .github/workflows/opencode.yml.
OPENCODE_DEFAULT_MODEL = "opencode-go/qwen3.6-plus"
