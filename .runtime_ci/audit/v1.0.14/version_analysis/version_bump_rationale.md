# Version Bump Rationale

**Decision**: patch

**Key Changes**:
- Fixed CI build failures by removing `resolution: workspace` constraints from the committed `pubspec.yaml`
- Regenerated all GitHub Actions workflows (`ci.yaml`, `issue-triage.yaml`, `release.yaml`) using the latest `runtime_ci_tooling` templates
- Removed `runtime_ci_tooling` from `dev_dependencies` in favor of global tool activation
- Updated `.gemini` settings, introducing a new autodoc safety policy and modifying the default model
- Corrected repository naming from `cli_script` to `dart_cli_script` in the CI configuration
- Fixed cross-repo Git dependency clones by updating GitHub Actions to use a personal access token instead of the default `GITHUB_TOKEN`

**Breaking Changes**:
- None

**New Features**:
- None

**References**:
- Commits between `v1.0.13` and `HEAD`