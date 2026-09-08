testthat::test_that("ExecutionContext derives an isolated test pipelineVersion", {
  context <- ExecutionContext$new(
    mode = "test",
    pipelineVersion = "Develop ML",
    baseCohortTable = "cohort_table",
    databaseName = "My Database",
    execPath = fs::path(tempdir(), "exec", "results")
  )

  testthat::expect_equal(context$getMode(), "test")
  testthat::expect_equal(context$getPipelineVersion(), "develop_ml")
  testthat::expect_equal(context$getCohortTable(), "cohort_table_develop_ml")
  testthat::expect_equal(
    context$getResultsPath("01_task"),
    fs::path(tempdir(), "exec", "results", "my_database", "develop_ml", "01_task")
  )
})

testthat::test_that("ExecutionContext keeps production cohort tables unsuffixed", {
  context <- ExecutionContext$new(
    mode = "production",
    pipelineVersion = "1.2.3",
    studyVersion = "1.2.3",
    baseCohortTable = "cohort_table",
    databaseName = "My Database",
    execPath = fs::path(tempdir(), "exec", "results")
  )

  testthat::expect_equal(context$getPipelineVersion(), "1.2.3")
  testthat::expect_equal(context$getStudyVersion(), "1.2.3")
  testthat::expect_equal(context$getCohortTable(), "cohort_table")
  testthat::expect_equal(
    context$getResultsPath(),
    fs::path(tempdir(), "exec", "results", "my_database", "1.2.3")
  )
})

testthat::test_that("ExecutionContext rejects inconsistent production versions", {
  testthat::expect_error(
    ExecutionContext$new(
      mode = "production",
      pipelineVersion = "develop_ml",
      studyVersion = "1.2.3",
      baseCohortTable = "cohort_table",
      databaseName = "My Database"
    ),
    "Production pipelineVersion must match studyVersion"
  )
})

testthat::test_that("ExecutionContext rejects oversized cohort table names", {
  testthat::expect_error(
    ExecutionContext$new(
      mode = "test",
      pipelineVersion = "develop_ml",
      baseCohortTable = "cohort_table",
      databaseName = "My Database",
      maxTableNameLength = 10L
    ),
    "Derived cohort table name is too long"
  )
})

testthat::test_that("ExecutionContext default table-length ceiling is the shared constant", {
  base <- paste(rep("x", MAX_TEST_COHORT_TABLE_NAME_LENGTH), collapse = "")

  testthat::expect_error(
    ExecutionContext$new(
      mode = "test",
      pipelineVersion = "develop_ml",
      baseCohortTable = base,
      databaseName = "My Database"
    ),
    "Derived cohort table name is too long"
  )
})

testthat::test_that("ExecutionContext does not revalidate production table length", {
  context <- ExecutionContext$new(
    mode = "production",
    pipelineVersion = "1.2.3",
    studyVersion = "1.2.3",
    baseCohortTable = "an_existing_production_cohort_table_name",
    databaseName = "My Database",
    maxTableNameLength = 10L
  )

  testthat::expect_equal(
    context$getCohortTable(),
    "an_existing_production_cohort_table_name"
  )
})

testthat::test_that("ExecutionContext supports a run shared by multiple databases", {
  context <- ExecutionContext$new(
    mode = "test",
    pipelineVersion = "develop_ml",
    execPath = fs::path(tempdir(), "exec", "results")
  )

  testthat::expect_null(context$getCohortTable())
  testthat::expect_equal(
    context$getResultsPath(databaseName = "Database One", taskName = "01_task"),
    fs::path(
      tempdir(), "exec", "results", "database_one", "develop_ml", "01_task"
    )
  )

  # A run-scoped context derives each database's cohort table on demand.
  testthat::expect_equal(context$deriveCohortTable("db_one_cohort"), "db_one_cohort_develop_ml")
  testthat::expect_equal(context$deriveCohortTable("db_two_cohort"), "db_two_cohort_develop_ml")
})

testthat::test_that("ExecutionContext$deriveCohortTable applies the mode rule and length ceiling", {
  test_ctx <- ExecutionContext$new(mode = "test", pipelineVersion = "develop_ml")
  testthat::expect_equal(test_ctx$deriveCohortTable("cohort"), "cohort_develop_ml")

  prod_ctx <- ExecutionContext$new(
    mode = "production", pipelineVersion = "1.2.3", studyVersion = "1.2.3"
  )
  testthat::expect_equal(prod_ctx$deriveCohortTable("cohort"), "cohort")

  # Production tables are never re-validated for length.
  long_base <- paste(rep("x", MAX_TEST_COHORT_TABLE_NAME_LENGTH), collapse = "")
  testthat::expect_equal(prod_ctx$deriveCohortTable(long_base), long_base)
  testthat::expect_error(
    test_ctx$deriveCohortTable(long_base),
    "Derived cohort table name is too long"
  )
})

testthat::test_that("ExecutionContext defaults test pipelineVersion to dev", {
  context <- ExecutionContext$new(
    mode = "test",
    baseCohortTable = "cohort_table",
    databaseName = "My Database",
    execPath = fs::path(tempdir(), "exec", "results")
  )

  testthat::expect_equal(context$getPipelineVersion(), "dev")
  testthat::expect_equal(context$getCohortTable(), "cohort_table_dev")
})

testthat::test_that("normalizePipelineVersion lowercases and snake-cases without truncating", {
  testthat::expect_equal(normalizePipelineVersion("Develop ML"), "develop_ml")
  testthat::expect_equal(normalizePipelineVersion("  feature/ABC-123  "), "feature_abc_123")
  testthat::expect_equal(normalizePipelineVersion("__dev__"), "dev")

  long <- paste(rep("namespace", 6), collapse = "_")
  testthat::expect_equal(normalizePipelineVersion(long), long)

  testthat::expect_error(normalizePipelineVersion("---"), "at least one letter or number")
})

testthat::test_that("resolveResultsPath derives one path from ExecutionSettings or a context", {
  es <- ExecutionSettings$new(
    connectionDetails = DatabaseConnector::createConnectionDetails(
      dbms = "sqlite",
      server = ":memory:"
    ),
    cdmDatabaseSchema = "main",
    workDatabaseSchema = "main",
    cohortTable = "cohort_table",
    databaseName = "My Database"
  )
  execPath <- fs::path(withr::local_tempdir(), "exec", "results")

  # No context: derived from executionSettings + pipelineVersion, normalized.
  testthat::expect_equal(
    as.character(resolveResultsPath(es, "Develop ML", "00_buildCohorts", execPath = execPath)),
    as.character(fs::path(execPath, "my_database", "develop_ml", "00_buildCohorts"))
  )

  # Semantic version passes through unchanged.
  testthat::expect_equal(
    as.character(resolveResultsPath(es, "1.2.3", execPath = execPath)),
    as.character(fs::path(execPath, "my_database", "1.2.3"))
  )

  # A run-scoped context (no databaseName of its own) still resolves via the
  # database name from executionSettings.
  ctx <- ExecutionContext$new(
    mode = "test",
    pipelineVersion = "develop_ml",
    execPath = execPath
  )
  testthat::expect_equal(
    as.character(resolveResultsPath(es, "ignored", "00_buildCohorts", executionContext = ctx)),
    as.character(fs::path(execPath, "my_database", "develop_ml", "00_buildCohorts"))
  )
})
