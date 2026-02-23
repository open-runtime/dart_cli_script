# cli_script v1.0.2

> Maintenance release — 2026-02-23

## Maintenance & Chores

- **Linting rule updates and auto-fixes** — Suppressed 11 specific lint rules in `analysis_options.yaml` to accommodate intentional patterns in this forked library. Applied auto-fixes for the `omit_obvious_property_types` lint rule, converting explicit type annotations (e.g., `bool`) to `var` for initialized internal fields.

## Contributors

Thanks to everyone who contributed to this release:
- @tsavo-at-pieces
## Issues Addressed

No linked issues for this release.
## Upgrade

```bash
dart pub upgrade cli_script
```

## Full Changelog

[v1.0.1...v1.0.2](https://github.com/open-runtime/dart_cli_script/compare/v1.0.1...v1.0.2)
