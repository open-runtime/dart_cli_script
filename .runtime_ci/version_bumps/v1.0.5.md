# Version Bump Rationale

**Decision**: patch

**Why**:
The changes since the last release (`v1.0.4`) consist exclusively of a development dependency update and a minor formatting change in the `pubspec.yaml` file. These changes are considered routine chore/maintenance and do not affect the public API surface or add new features. Therefore, a `patch` release is appropriate.

**Key Changes**:
- Updated the `runtime_ci_tooling` development dependency from `^0.10.0` to `^0.11.0`.
- Minor formatting adjustment in `pubspec.yaml`.

**Breaking Changes**:
- None.

**New Features**:
- None.

**References**:
- chore: sync runtime_ci templates and dependency metadata
- Merge branch 'feat/enterprise-byok-runtime-ci-sync'
