testthat::test_that("testStudyPipeline uses pipelineVersion as its namespace", {
  pipeline_formals <- names(formals(testStudyPipeline))

  testthat::expect_equal(
    pipeline_formals[seq_len(3)],
    c("configBlock", "pipelineVersion", "env")
  )
  testthat::expect_false("testLabel" %in% pipeline_formals)
  testthat::expect_equal(
    formals(testStudyPipeline)$pipelineVersion,
    "dev"
  )
})

testthat::test_that("testStudyTask accepts the shared pipelineVersion namespace", {
  task_formals <- names(formals(testStudyTask))

  testthat::expect_true("pipelineVersion" %in% task_formals)
  testthat::expect_equal(
    formals(testStudyTask)$pipelineVersion,
    "dev"
  )
})

testthat::test_that("pipeline execution functions accept an ExecutionContext", {
  testthat::expect_true("executionContext" %in% names(formals(execute_task)))
  testthat::expect_true("executionContext" %in% names(formals(generateCohorts)))
  testthat::expect_true(
    "executionContext" %in% names(formals(createExecutionSettingsFromConfig))
  )
})
