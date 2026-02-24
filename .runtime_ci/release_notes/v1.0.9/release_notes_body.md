# cli_script v1.0.9

> Bug fix release — 2026-02-24

## Bug Fixes

- **Triage command safety** — Added shell-level organization guards and `--repo` requirements to the internal `triage.toml` command to prevent upstream leakage when triaging issues in fork contexts.

## Upgrade

```bash
dart pub upgrade cli_script
```

## Contributors

Thanks to everyone who contributed to this release:
- @tsavo-at-pieces
## Issues Addressed

No linked issues for this release.
## Full Changelog

[v1.0.8...v1.0.9](https://github.com/open-runtime/cli_script/compare/v1.0.8...v1.0.9)
