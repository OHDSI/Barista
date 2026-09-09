# Test Study Pipeline

Executes the full study pipeline in test mode. The pipelineVersion value
is interpreted as the test namespace and is used for test cohort tables
and output folders. Test runs are allowed on development branches but
rejected on the main branch.

## Usage

``` r
testStudyPipeline(
  configBlock,
  pipelineVersion = "dev",
  env = rlang::caller_env()
)
```

## Arguments

- configBlock:

  Character or character vector. Name(s) of config block(s) to use.

- pipelineVersion:

  Character. Test namespace used for output folders and cohort table
  suffix. Defaults to `"dev"`. The value is normalized to lowercase
  snake_case; an over-long namespace is rejected rather than truncated.

- env:

  The execution environment. Defaults to caller environment.

## Value

Invisibly returns task results list

## Examples

``` r
if (FALSE) { # \dontrun{
# Test full pipeline on develop branch
testStudyPipeline(configBlock = "myConfig")
# Test full pipeline with a custom namespace
testStudyPipeline(configBlock = "myConfig", pipelineVersion = "feature_ml_test")
} # }
```
