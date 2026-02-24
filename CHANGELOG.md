# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.11] - 2026-02-24

### Fixed
- Removed the custom_lint.log junk file that was accidentally committed before the .gitignore rule was added

## [1.0.10] - 2026-02-24

### Changed
- Updated .gitignore to ignore custom_lint.log and .claude/ directories.

## [1.0.9] - 2026-02-24

### Security
- Added shell-level org guards and `--repo` requirements to `triage.toml` to prevent upstream leakage when triaging issues in fork contexts

## [1.0.8] - 2026-02-24

### Changed
- Bumped runtime_ci_tooling dependency to ^0.12.0

### Fixed
- Fixed create-release pull --rebase failure when previous pipeline steps leave unstaged changes (by updating runtime_ci_tooling)

## [1.0.7] - 2026-02-24

### Changed
- Updated CI workflow templates and enhanced autodoc coverage (added api_reference and examples generate types)

## [1.0.6] - 2026-02-24

### Changed
- Regenerated CI workflow to include an auto-format job and updated runtime_ci_tooling to v0.11.3

## [1.0.5] - 2026-02-24

### Changed
- Sync runtime_ci templates and dependency metadata for enterprise BYOK prep

## [1.0.4] - 2026-02-23

### Changed
- Updated CI tooling configuration to v0.11.2

## [1.0.3] - 2026-02-23

### Changed
- Aligned runtime_ci_tooling dependency for workspace enablement

## [1.0.2] - 2026-02-22

### Changed
- Suppressed 11 lint rules in analysis_options.yaml that flag intentional patterns in this forked library, and applied dart auto-fixes for omit_obvious_property_types.

## [1.0.1] - 2026-02-22

### Breaking Changes
- **BREAKING**: Updated the minimum Dart SDK requirement from 3.3.0 to 3.9.0.
  - Migration: Ensure your project uses Dart SDK version 3.9.0 or higher. Update the `environment: sdk` constraint in your pubspec.yaml to be compatible with `^3.9.0`.

### Added
- Added runtime_ci_tooling for version bumping, changelog generation, and automated release management.
- Added GitHub Actions workflows for release management (release.yaml) and issue triage (issue-triage.yaml).

### Changed
- Formatted all files at line-length 120.
- Updated Dart SDK requirement to ^3.9.0.
- Replaced ci.yml with ci.yaml and updated its content.

### Removed
- Removed workspace-only pubspec settings (sass_analysis dev_dependency) for cli_script.

### Fixed
- Stabilized cli_script standalone mode and subprocess env tests by pointing test subprocess spawning at the resolved Dart executable.
- Suppressed included-file analyzer warning noise so local test and analysis workflows run reliably.

## 1.0.0

* Stable release.

* Expose the `args()` function, which shell-escapes multiple arguments at once.

* Update internal type annotations for compatibility with [dart-lang/sdk#52801].

  [dart-lang/sdk#52801]: https://github.com/dart-lang/sdk/issues/52801

## 0.3.2

* Declare support for Dart 3.

## 0.3.1

* Add `Script.outputBytes`, which works like `Script.output` but returns the raw
  bytes instead of a string representation.

## 0.3.0

* Add `Script.kill()` to send a `ProcessSignal` such as `SIGKILL` or `SIGTERM`
  to terminate a script or stream. Defaults to `SIGTERM`. Capturing functions
  like `Script.capture` or `silenceUntilFailure` can't terminate their callbacks
  but the `ProcessSignal` can be reacted to via their new `onSignal` handler.

## 0.2.7

* Ensure that `Script`s always cancel streams piped to their `stdin` sinks after
  exiting. This prevents rare cases where programs could deadlock waiting for
  events to be processed.

## 0.2.6

* Add a `stderrOnly` parameter to `BufferedScript.capture()` and
  `silenceUntilFailure()`. If this parameter is `true`, only the `stderr` from
  the callbacks will be buffered or silenced, and the `stdout` will be emitted
  normally.

## 0.2.5

* Add `LineStreamExtensions.withSpans()`, which adds `SourceSpanWithContext`s to
  a stream's lines for better error messaging and debugging.

* Add `readWithSpans()`, which adds `SourceSpanWithContext`s to a file's lines
  for better error messaging and debugging.

* Add `LineAndSpanStreamExtensions`, which provides various extension methods
  that preserve source spans.

## 0.2.4

* Add a `silenceUntilFailure()` function that suppresses output for a block of
  code until it emits an error.

## 0.2.3+2

* Documentation improvements only.

## 0.2.3+1

* Properly respect `onlyMatching` in the top-level `grep()` method.

## 0.2.3

* Add an `onlyMatching` flag to `grep()` which prints the sections of input
  lines that match the given regular expression.

* Add a `teeToStderr` transformer and extension method on
  `Stream<List<String>>`. This passes a stream to stderr without modifying it,
  which is useful for debugging.

* Add a `Script.mapLines` constructor that returns a script that maps stdin
  lines according to a `String Function(String)`.

* Add support for passing a `String Function(String)` to `Script.pipeline` and
  `Script.operator |` to map stdin lines.

* Fold stack frames for a few more packages used internally.

## 0.2.2

* Add a `BufferedScript` class that buffers output from a Script until it's
  explicitly released, making it easier to run multiple script in parallel
  without having their outputs collide with one another.

* If the same `capture()` block both calls `print()` and writes to
  `currentStdout`, ensure that the order of prints is preserved.

* If the same `capture()` block writes to both `currentStdout` and
  `currentStderr`, ensure that the relative order of those writes is preserved
  when collected with `combineOutput()`.

## 0.2.1

* Give the stream transformers exposed by this package human-readable
  `toString()`s.

## 0.2.0

* Add a `debug` option to `wrapMain()` to print extra diagnostic information.

* Add a `runInShell` argument for subprocesses.

* Accept `Iterable<String>` instead of `List<String>` for subprocess arguments.

* Use 257 rather than 256 as the sentinel value for `ScriptException`s caused by
  Dart exceptions.

* Fix a bug where Dart exceptions could cause the script to exit before their
  debug information was printed to stderr.

## 0.1.0

* Initial release.

[1.0.11]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.10...v1.0.11
[1.0.10]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/open-runtime/dart_cli_script/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/open-runtime/dart_cli_script/releases/tag/v1.0.1
