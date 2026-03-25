## [1.0.14] - 2026-03-25

### Added
- Enabled autodoc feature flag and regenerated workflows for automated documentation runs
- Added autodoc safety policy and updated gemini settings from runtime_ci_tooling v0.23.10

### Changed
- Upgraded runtime_ci_tooling templates up to v0.23.11, removing it as a dev_dependency in favor of global activation
- Bumped setup-dart action to v1.7.2 in CI workflows
- Configured gemini-3-flash-preview as the review model for autodoc
- Aligned Dart workspace resolution and dependency constraints in pubspec

### Fixed
- Removed accidental 'resolution: workspace' from pubspec.yaml that broke standalone CI
- Corrected repository name from cli_script to dart_cli_script in config.json
- Switched to using TSAVO_AT_PIECES_PERSONAL_ACCESS_TOKEN to properly clone cross-repo git dependencies in CI