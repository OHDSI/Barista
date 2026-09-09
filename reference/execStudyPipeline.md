# Production Study Pipeline Execution

Executes the full study pipeline in production mode with full
validation, version management, and reproducibility tracking. Creates a
release branch, runs the complete pipeline, provides PR instructions,
and saves reference to PENDING_PR.md.

## Usage

``` r
execStudyPipeline(
  configBlock,
  updateType,
  skipRenv = FALSE,
  skipConnectivityCheck = TRUE,
  ignoreUncommittedPaths = NULL,
  skipCodeStateCheck = FALSE,
  env = rlang::caller_env()
)
```

## Arguments

- configBlock:

  Character or character vector. Name(s) of config block(s) to use.

- updateType:

  Character. Type of version increment: 'major', 'minor', or 'patch'.

  - MAJOR: Breaking changes

  - MINOR: New features, backward compatible

  - PATCH: Bug fixes, no new features

- skipRenv:

  Logical. If TRUE, skips renv validation. Defaults to FALSE. Useful for
  testing issues. Default: FALSE

- skipConnectivityCheck:

  Logical. If TRUE (default), skips the optional database connectivity
  pre-flight check. Set to FALSE to attempt a test connection to each
  config block before execution begins.

- ignoreUncommittedPaths:

  Character vector or NULL. Repo-relative paths (e.g. `"inputs"`) whose
  uncommitted changes should not fail the code-state pre-flight check.
  Changes anywhere else — notably `analysis/` — still fail it. When NULL
  (default) the list is read from `ignoreUncommittedPaths` in the
  `default:` block of config.yml, which itself defaults to ignoring
  nothing, so behaviour is unchanged unless a study opts in. Pass
  `character(0)` to force strict checking regardless of config.yml.

- skipCodeStateCheck:

  Logical. If TRUE, skips the code-state check entirely — a last resort
  when `ignoreUncommittedPaths` cannot express the churn. The run
  proceeds, but the pre-flight checklist raises a warning and the run
  history records the tree as `"unverified-skipped"`. Defaults to FALSE.
  Deliberately not settable from config.yml, so it cannot be baked
  permanently into a study.

- env:

  The execution environment. Defaults to caller environment.

## Value

Invisibly returns task results list

## Examples

``` r
if (FALSE) { # \dontrun{
# Run production pipeline with patch version increment
execStudyPipeline(configBlock = "myConfig", updateType = "patch")

# Tolerate manifest/ATLAS churn under inputs/ for this run only
execStudyPipeline(
  configBlock = "myConfig",
  updateType = "patch",
  ignoreUncommittedPaths = "inputs"
)

# Last resort: do not check the working tree at all
execStudyPipeline(
  configBlock = "myConfig",
  updateType = "patch",
  skipCodeStateCheck = TRUE
)
} # }
```
