# Version Bump Rationale

**Decision**: patch
The only commit in this release is a `fix` commit that removes a committed `custom_lint.log` file from the repository tracking, which was inadvertently added before the `.gitignore` rule was in place. This does not change any public APIs or internal logic.

**Key Changes**:
* Removed untracked junk file `custom_lint.log`.

**Breaking Changes**:
None

**New Features**:
None

**References**:
* `fix: remove committed custom_lint.log junk file`
