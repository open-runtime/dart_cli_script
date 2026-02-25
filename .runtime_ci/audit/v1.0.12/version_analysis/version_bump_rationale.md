# Version Bump Rationale: Patch

**Decision**: patch

The changes introduced between `v1.0.11` and `HEAD` strictly address cross-platform compatibility bugs (primarily on Windows), improve test coverage, and update CI tooling. No public API signatures were modified, and no new features were introduced.

**Key Changes**:
- Fixed Windows glob expansion for absolute and UNC paths by normalizing `package:glob` patterns to POSIX separators internally.
- Handled edge cases with escaped Windows absolute glob patterns to correctly preserve matches.
- Stabilized Windows process spawning when `includeParentEnvironment: false` is used by injecting `SystemRoot` and `WINDIR`, preventing immediate `ProcessException` crashes.
- Ensured absolute glob path output is normalized to the correct platform-specific path separators.
- Resolved Windows-sensitive CI behavior and environment casing quirks.
- Updated `runtime_ci_tooling` and regenerated CI templates for full platform matrix coverage.

**Breaking Changes**:
- None. (Note: injecting base Windows environment variables when `includeParentEnvironment: false` is a bug fix addressing unavoidable subprocess execution failures on Windows, not an API-breaking change).

**New Features**:
- None.

**References**:
- PR #5: "chore/windows-total-compatibility"
- Commits addressing deep Windows path and environment regression coverage.
