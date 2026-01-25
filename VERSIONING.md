# Versioning Specification

This document defines a versioning standard for build artifacts.

## Version Format

Versions follow the pattern:

```
<branch>-<timestamp>[-<commit>]
```

| Component   | Format              | Required | Example            |
|-------------|---------------------|----------|--------------------|
| `branch`    | Sanitized branch name (alphanumeric + hyphens) | Yes | `main`, `feature-login` |
| `timestamp` | `YYYYMMDD-HHmmss` (UTC) | Yes | `20260125-143022` |
| `commit`    | 7-character git SHA | No | `a1b2c3d` |

**Standard example:** `main-20260125-143022`

**With commit (optional):** `main-20260125-143022-a1b2c3d`

### Why This Format?

- **Branch**: Identifies source branch for traceability
- **Timestamp**: Provides chronological ordering and human-readable build time
- **Commit** (optional): Links to exact source code state for debugging and audits; include when additional traceability is needed

This format is preferred over pure [Semantic Versioning](https://semver.org/) for internal/continuous deployment scenarios because:
- No manual version bumping required
- Every build is uniquely identifiable
- Supports multiple concurrent branches

For public releases or libraries, consider using SemVer (`MAJOR.MINOR.PATCH`) with this format as build metadata: `1.2.3+main-20260125-143022`

## Generation Rules

### Rule 1: Never Committed

Version strings **MUST NOT** be committed to source control. They are generated at build time.

**Rationale**: Committed versions cause merge conflicts, become stale, and break the single-source-of-truth principle where git itself is the authority.

### Rule 2: Build-Time Generation

Versions are generated during the build/deploy process:

1. **CI/CD Pipeline** (preferred): The pipeline generates the version and injects it into the build artifact
2. **Local Build**: Developer tools generate the version when building locally

### Rule 3: Fallback Calculation

When the version is not injected by CI/CD, calculate it from git:

```bash
# Get sanitized branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/-/g')

# Get UTC timestamp
TZ=UTC TIMESTAMP=$(git show -s --format=%cd --date=format:'%Y%m%d-%H%M%S' HEAD)

# Combine (standard)
VERSION="${BRANCH}-${TIMESTAMP}"

# Optional: include commit hash for additional traceability
COMMIT=$(git rev-parse --short=7 HEAD)
VERSION="${BRANCH}-${TIMESTAMP}-${COMMIT}"
```

### Rule 4: Dirty Working Directory

If the working directory has uncommitted changes, append `-dirty`:

```
main-20260125-143022-dirty
main-20260125-143022-a1b2c3d-dirty  (with optional commit)
```

This clearly indicates the build does not match any committed state.

## Environment Variables

CI/CD systems should set these environment variables:

| Variable       | Description                    | Required | Example                         |
|----------------|--------------------------------|----------|---------------------------------|
| `BUILD_VERSION`| Full version string            | Yes      | `main-20260125-143022`          |
| `BUILD_BRANCH` | Source branch                  | Yes      | `main`                          |
| `BUILD_TIME`   | ISO 8601 timestamp             | Yes      | `2026-01-25T14:30:22Z`          |
| `BUILD_COMMIT` | Full commit SHA                | No       | `a1b2c3d4e5f6...`               |

## Language Examples

Each example separates the **version loader** (minimal, lives in main code) from the **git fallback script** (dedicated file, only needed for local dev).

### Python

**version.py** (version loader):
```python
import os

__version__ = os.environ.get("BUILD_VERSION", "development")
```

**scripts/git_version.py** (fallback script):
```python
#!/usr/bin/env python3
"""Generate version from git and set BUILD_VERSION environment variable."""
import subprocess
import sys

def get_version():
    try:
        branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            stderr=subprocess.DEVNULL,
            text=True
        ).strip().replace("/", "-")

        timestamp = subprocess.check_output(
            ["git", "show", "-s", "--format=%cd", "--date=format:%Y%m%d-%H%M%S", "HEAD"],
            stderr=subprocess.DEVNULL,
            text=True
        ).strip()

        dirty = subprocess.call(
            ["git", "diff", "--quiet", "HEAD"],
            stderr=subprocess.DEVNULL
        ) != 0

        version = f"{branch}-{timestamp}"
        if dirty:
            version += "-dirty"
        return version
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"

if __name__ == "__main__":
    print(get_version())
```

**Usage:**
```bash
# CI/CD: BUILD_VERSION is set by pipeline
python app.py

# Local dev with fallback:
BUILD_VERSION=$(python scripts/git_version.py) python app.py
```

### JavaScript / TypeScript

**src/version.js** (version loader):
```javascript
export const VERSION = process.env.BUILD_VERSION || 'development';
```

**scripts/git-version.js** (fallback script):
```javascript
#!/usr/bin/env node
const { execSync } = require('child_process');

function exec(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] }).trim();
  } catch {
    return null;
  }
}

const branch = exec('git rev-parse --abbrev-ref HEAD')?.replace(/\//g, '-') || 'unknown';
const timestamp = exec('git show -s --format=%cd --date=format:%Y%m%d-%H%M%S HEAD') || 'unknown';
const isDirty = exec('git diff --quiet HEAD; echo $?') === '1';

const version = `${branch}-${timestamp}${isDirty ? '-dirty' : ''}`;
console.log(version);
```

**package.json:**
```json
{
  "scripts": {
    "start": "node app.js",
    "start:local": "BUILD_VERSION=$(node scripts/git-version.js) npm start"
  }
}
```

### C# / .NET

**Version.cs** (version loader):
```csharp
namespace MyApp;

public static class Version
{
    public static string Current =>
        Environment.GetEnvironmentVariable("BUILD_VERSION") ?? "development";
}
```

**scripts/git-version.sh** (fallback script):
```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/-/g')
TIMESTAMP=$(TZ=UTC git show -s --format=%cd --date=format:'%Y%m%d-%H%M%S' HEAD)

if ! git diff --quiet HEAD 2>/dev/null; then
    echo "${BRANCH}-${TIMESTAMP}-dirty"
else
    echo "${BRANCH}-${TIMESTAMP}"
fi
```

**Usage:**
```bash
# CI/CD: BUILD_VERSION is set by pipeline
dotnet run

# Local dev with fallback:
BUILD_VERSION=$(./scripts/git-version.sh) dotnet run
```

### Go

**version/version.go** (version loader):
```go
package version

import "os"

func Get() string {
    if v := os.Getenv("BUILD_VERSION"); v != "" {
        return v
    }
    return "development"
}
```

**scripts/git-version.sh** (fallback script):
```bash
#!/bin/bash
BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9]/-/g')
TIMESTAMP=$(TZ=UTC git show -s --format=%cd --date=format:'%Y%m%d-%H%M%S' HEAD)

if ! git diff --quiet HEAD 2>/dev/null; then
    echo "${BRANCH}-${TIMESTAMP}-dirty"
else
    echo "${BRANCH}-${TIMESTAMP}"
fi
```

**Usage:**
```bash
# CI/CD: BUILD_VERSION is set by pipeline
go run ./cmd/myapp

# Local dev with fallback:
BUILD_VERSION=$(./scripts/git-version.sh) go run ./cmd/myapp
```

## CI/CD Integration Examples

### GitHub Actions

```yaml
- name: Set version
  run: |
    BRANCH=${GITHUB_REF_NAME//\//-}
    TIMESTAMP=$(TZ=UTC git show -s --format=%cd --date=format:'%Y%m%d-%H%M%S' HEAD)
    echo "BUILD_VERSION=${BRANCH}-${TIMESTAMP}" >> $GITHUB_ENV

- name: Build
  run: <build-command>
  env:
    BUILD_VERSION: ${{ env.BUILD_VERSION }}
```

### GitLab CI

```yaml
variables:
  BUILD_VERSION: "${CI_COMMIT_REF_SLUG}-${CI_PIPELINE_CREATED_AT}"
```

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [git-describe Documentation](https://git-scm.com/docs/git-describe)
- [Version Numbers for Continuous Delivery](https://phauer.com/2016/version-numbers-continuous-delivery-maven-docker/)
