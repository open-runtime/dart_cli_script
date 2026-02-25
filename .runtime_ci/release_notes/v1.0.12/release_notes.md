# cli_script v1.0.12

> Bug fix release — 2026-02-25

## Bug Fixes

- **Windows Subprocess Environment Stabilization** — Addressed an issue where spawning subprocesses with `includeParentEnvironment: false` would crash on Windows. The `Script` class now automatically injects `SystemRoot` and `WINDIR` into the isolated environment, which are required for the Dart executable to spawn reliably. ([#5](https://github.com/open-runtime/cli_script/pull/5))
- **Windows Absolute Glob Pattern Normalization** — Fixed an issue where absolute Windows paths with globs (e.g., `C:\path\*.txt`) failed to expand. `CliArguments` now correctly normalizes drive prefixes and backslashes to POSIX separators (`/`) for `package:glob` compatibility before resolving them. ([#5](https://github.com/open-runtime/cli_script/pull/5))
- **Escaped Glob Syntax Preservation** — Handled edge cases with escaped Windows absolute glob patterns to ensure UNC paths and explicitly escaped glob characters (like `\\*.txt`) are preserved and not corrupted during argument parsing. ([#5](https://github.com/open-runtime/cli_script/pull/5))

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

[v1.0.11...v1.0.12](https://github.com/open-runtime/cli_script/compare/v1.0.11...v1.0.12)
