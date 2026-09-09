# The public pipeline entry points each apply an early main-branch guard —
# `branch <- get_current_branch(); if (branch == "main") cli::cli_abort(...)` —
# that runs before any config, secrets, or database access. `get_current_branch()`
# is an internal bare call, so it can be mocked without a real git repository.
#
# These guards are independent of the pipeline-namespace handling: the namespace
# comes from `pipelineVersion`, never from the branch (see the "Unified Test-Mode
# Namespaces" work).

testthat::test_that("test and production entry points refuse to run on main", {
  testthat::local_mocked_bindings(get_current_branch = function() "main")

  testthat::expect_error(
    suppressMessages(
      testStudyPipeline(configBlock = "any_block", pipelineVersion = "dev")
    ),
    "Cannot run test pipeline on main branch"
  )

  testthat::expect_error(
    suppressMessages(
      testStudyTask(taskFile = "01_task.R", configBlock = "any_block")
    ),
    "Cannot run test task on main branch"
  )

  testthat::expect_error(
    suppressMessages(
      execStudyPipeline(configBlock = "any_block", updateType = "patch")
    ),
    "Cannot run production pipeline on main branch"
  )
})

testthat::test_that("a non-main branch clears the guard (later failures are downstream)", {
  testthat::local_mocked_bindings(get_current_branch = function() "feature_x")

  # No study repo here, so each call still fails downstream (missing config.yml
  # etc.) — but past the guard, so never with the main-branch message. This
  # proves the guard is an equality check on "main" and not, e.g., "anything
  # that is not develop". Downstream warnings/messages are expected and muffled.
  run <- function(expr) {
    tryCatch(
      suppressWarnings(suppressMessages(expr)),
      error = conditionMessage
    )
  }

  pipeline_msg <- run(
    testStudyPipeline(configBlock = "no_such_block", pipelineVersion = "dev")
  )
  testthat::expect_false(
    grepl("Cannot run test pipeline on main branch", pipeline_msg, fixed = TRUE)
  )

  task_msg <- run(
    testStudyTask(taskFile = "01_task.R", configBlock = "no_such_block")
  )
  testthat::expect_false(
    grepl("Cannot run test task on main branch", task_msg, fixed = TRUE)
  )
})
