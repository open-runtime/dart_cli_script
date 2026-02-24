# cli_script v1.0.6

> Patch release — 2026-02-24

## Improvements

- **Automated formatting in CI** — The GitHub Actions workflow has been updated (via `runtime_ci_tooling` v0.11.3) to include an `auto-format` job. Instead of simply failing when code is unformatted, the CI will now automatically apply `dart format --line-length 120 lib/` and push the formatting changes back to the branch.

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

[v1.0.5...v1.0.6](https://github.com/open-runtime/dart_cli_script/compare/v1.0.5...v1.0.6)
