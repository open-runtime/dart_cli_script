# dart_cli_script v1.0.14

> Bug fix release — 2026-03-25

## Bug Fixes & Improvements

- **Fixed Standalone CI** — Removed an accidental `resolution: workspace` entry from `pubspec.yaml` that was breaking standalone CI environments.
- **Cross-Repo Git Dependencies** — Updated GitHub Actions workflows to use `TSAVO_AT_PIECES_PERSONAL_ACCESS_TOKEN` instead of the default `GITHUB_TOKEN`, ensuring proper access when cloning cross-repo Git dependencies.
- **Repository Naming** — Corrected the repository name from `cli_script` to `dart_cli_script` in the CI configuration (`.runtime_ci/config.json`).
- **CI Tooling Enhancements** — Upgraded CI workflow templates to `runtime_ci_tooling` v0.23.11, removing it as a `dev_dependency` in favor of global tool activation, and bumped the `setup-dart` action to v1.7.2.
- **Autodoc Enhancements** — Enabled the autodoc feature flag, introduced a new autodoc safety policy, and configured `gemini-3-flash-preview` as the default review model for automated documentation runs.

## Install / Upgrade

**Existing consumers:**
```bash
dart pub upgrade dart_cli_script
```

**New consumers — add to your `pubspec.yaml`:**
```yaml
dependencies:
  dart_cli_script:
    git:
      url: git@github.com:open-runtime/dart_cli_script.git
      tag_pattern: v{{version}}
```

Then run `dart pub get` to install.

> View on [GitHub](https://github.com/open-runtime/dart_cli_script/releases/tag/v1.0.14)

## Contributors

Thanks to everyone who contributed to this release:
- @tsavo-at-pieces
## Issues Addressed

No linked issues for this release.
## Full Changelog

[v1.0.13...v1.0.14](https://github.com/open-runtime/dart_cli_script/compare/v1.0.13...v1.0.14)