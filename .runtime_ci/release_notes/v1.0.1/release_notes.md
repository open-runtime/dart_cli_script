# cli_script v1.0.1

# Version Bump Rationale

- **Decision**: patch (The updates consist of style changes, tooling setups, and test fixes)
- **Key Changes**:
  - Re-formatted the codebase using a 120-character line-length limit.
  - Setup internal CI/CD tooling (`runtime_ci_tooling`) for automated versioning and releases.
  - Configured GitHub Actions workflows (`ci.yaml`, `release.yaml`, `issue-triage.yaml`) and Gemini CLI tool configurations.
  - Stabilized tests for `cli_script` standalone mode and subprocess environments.
  - Updated Dart SDK lower-bound constraint to `^3.9.0` and removed workspace-specific `sass_analysis` dependency.
- **Breaking Changes**: None
- **New Features**: None
- **References**:
  - Commit: `style: format all files at line-length 120`
  - Commit: `chore: add runtime_ci_tooling for automated releases`
  - Commit: `fix: stabilize cli_script standalone mode and subprocess env tests`


---
[Full Changelog](https://github.com/open-runtime/cli_script/compare/v1.0.0...v1.0.1)
