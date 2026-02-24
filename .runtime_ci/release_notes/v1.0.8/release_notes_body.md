# cli_script v1.0.8

> Bug fix release — 2026-02-24

## Bug Fixes

- **Fix pipeline failure on release creation** — Updated the `runtime_ci_tooling` dependency to `^0.12.0` to resolve a `create-release pull --rebase` failure that occurred when previous pipeline steps left unstaged changes.

## Issues Addressed

No linked issues for this release.
## Upgrade

```bash
dart pub upgrade cli_script
```

## Contributors

Thanks to everyone who contributed to this release:
- @tsavo-at-pieces
## Full Changelog

[v1.0.7...v1.0.8](https://github.com/open-runtime/cli_script/compare/v1.0.7...v1.0.8)
