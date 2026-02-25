## [1.0.12] - 2026-02-25

### Added
- Added deep Windows path and environment regression coverage (#5)

### Changed
- Updated runtime_ci_tooling to v0.14.1 and expanded autodoc coverage
- Updated dependency versions for workspace compatibility

### Fixed
- Normalized absolute glob output and handled escaped Windows absolute glob patterns in CliArguments (#5)
- Completed Windows compatibility for glob and subprocess tests, hardening environment handling on Windows (#5)
- Stabilized Windows CI behavior and test expectations