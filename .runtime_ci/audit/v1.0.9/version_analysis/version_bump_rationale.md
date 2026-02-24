# Version Bump Rationale

- **Decision**: patch
  - The changes are strictly to the internal '.gemini/commands/triage.toml' tool script. No public APIs, dependencies, or package sources were affected. Tooling and maintenance improvements warrant a patch release.
- **Key Changes**:
  - Updated the internal triage command to include repository validation.
  - Added an org allowlist to prevent the tool from running triage commands on unauthorized or upstream repositories.
  - Updated issue fetching logic to include existing comments for duplicate detection.
- **Breaking Changes**: None.
- **New Features**: None (no feature additions to the cli_script Dart package itself).
- **References**:
  - 'fix(triage): add --repo + org allowlist to triage.toml to prevent upstream leakage'
