# Check if Task Needs to be Rerun

Determines whether a task needs to be rerun by checking:

1.  Task file modifications (file hash comparison)

2.  Dependency file modifications (extracted from source() calls)

3.  Cohort manifest changes — compares
    [CohortManifest\$getManifestHash()](https://ohdsi.github.io/Picard/reference/CohortManifest.md)
    against the hash recorded on the previous run. A rerun is forced
    when the hash differs, when no hash was recorded (first run, or a
    legacy history row), or when the current hash cannot be computed at
    all.

4.  Previous run errors (checked in logs and history)

5.  Version changes. History is scoped by task, config block, and
    `pipeline_version`, so separate test namespaces do not reuse one
    another's run state.

## Usage

``` r
shouldRerunTask(
  taskFile,
  configBlock,
  executionSettings,
  pipelineVersion,
  tasksFolderPath = here::here("analysis/tasks"),
  cohortManifestHash = NULL
)
```

## Arguments

- taskFile:

  Character. Name or path of the task file (e.g., "task1.R")

- configBlock:

  Character. The config block name (e.g., "optum_dod")

- executionSettings:

  ExecutionSettings object

- pipelineVersion:

  Character. Current pipeline version (e.g., "1.0.0")

- tasksFolderPath:

  Character. Path to tasks folder (default:
  here::here("analysis/tasks"))

- cohortManifestHash:

  Character or NULL. A pre-computed cohort manifest hash (see
  [`.getCohortManifestHash()`](https://ohdsi.github.io/Picard/reference/dot-getCohortManifestHash.md)).
  When NULL (default) it is computed here; callers that check many tasks
  in one run pass it in to avoid re-loading the manifest per task.

## Value

List with elements:

- should_rerun: Logical. TRUE if task should be rerun

- reasons: Character vector. Why task should be rerun

- last_run_info: List with previous run details (time, version, status)

- task_file_hash: Current hash of task file

- cohort_manifest_hash: Current hash of cohort manifest definitions

## Details

Creates/updates exec/logs/task_run_history.csv tracking:

- task_name, config_block, last_run_time, pipeline_version

- task_file_hash, cohort_manifest_hash, status, error_message
