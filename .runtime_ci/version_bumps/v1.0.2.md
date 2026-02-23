# Version Bump Rationale

**Decision**: `patch`

The recent changes are strictly maintenance-related and do not introduce any new features or breaking changes. This warrants a patch release according to Semantic Versioning.

**Key Changes**:
* Suppressed 11 specific lint rules in `analysis_options.yaml` to accommodate intentional patterns in the codebase since it is a fork.
* Applied auto-fixes for the `omit_obvious_property_types` lint rule, changing explicit type annotations (`bool`) to `var` for initialized private/internal fields in `lib/src/script.dart`, `lib/src/util/sink_base.dart`, and `test/util/entangled_controllers_test.dart`.

**Breaking Changes**: None

**New Features**: None

**References**:
* `chore: suppress lint rules for forked third-party library and apply auto-fixes`