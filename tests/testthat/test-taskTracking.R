# Testing: .getCohortManifestHash() summarises cohort definitions for task-rerun
# detection. It delegates to CohortManifest$getManifestHash() (a digest over each
# cohort's rendered SQL plus its identity and dependency structure). It must be a
# pure read, deterministic, and independent of where cohort files are stored on
# disk.

testthat::test_that(".getCohortManifestHash returns NA when there is no manifest", {
  setup <- cm_test_new_manifest("tt-hash-nodb")
  fs::file_delete(setup$paths$db_path)

  testthat::expect_true(is.na(.getCohortManifestHash(projectPath = setup$paths$root)))
})

testthat::test_that(".getCohortManifestHash hashes an empty manifest to a stable sentinel", {
  setup <- cm_test_new_manifest("tt-hash-empty")

  h <- .getCohortManifestHash(projectPath = setup$paths$root)

  testthat::expect_type(h, "character")
  testthat::expect_false(is.na(h))
  testthat::expect_identical(h, .getCohortManifestHash(projectPath = setup$paths$root))
})

testthat::test_that(".getCohortManifestHash changes when a cohort is added and is deterministic", {
  setup <- cm_test_new_manifest("tt-hash-add")
  root <- setup$manifest$getProjectRoot()

  cm_test_add_circe_cohort(setup$manifest, setup$paths, label = "CKD", category = "Target",
                           fixture_name = "ckd.json")
  h1 <- .getCohortManifestHash(projectPath = root)
  cm_test_add_circe_cohort(setup$manifest, setup$paths, label = "T2D", category = "Target",
                           fixture_name = "t2d.json")
  h2 <- .getCohortManifestHash(projectPath = root)

  testthat::expect_false(identical(h1, h2))
  testthat::expect_identical(h2, .getCohortManifestHash(projectPath = root))

  # deterministic from an unrelated working directory
  withr::with_dir(withr::local_tempdir(), {
    testthat::expect_identical(.getCohortManifestHash(projectPath = root), h2)
  })
})

testthat::test_that(".getCohortManifestHash is unaffected by a stored path-convention change", {
  setup <- cm_test_seed_manifest_for_queries("tt-hash-pathonly")
  manifest <- setup$manifest
  root <- manifest$getProjectRoot()
  before <- .getCohortManifestHash(projectPath = root)

  rows <- cm_test_all_rows(manifest)
  circe_id <- rows$id[rows$cohort_type == "circe"][1]
  cm_test_set_stored_path(manifest, circe_id,
                          sub("^inputs/cohorts/", "", rows$file_path[rows$id == circe_id]))

  testthat::expect_identical(.getCohortManifestHash(projectPath = root), before)
})

testthat::test_that(".getCohortManifestHash changes when a cohort's definition changes", {
  setup <- cm_test_seed_manifest_for_queries("tt-hash-content")
  manifest <- setup$manifest
  root <- manifest$getProjectRoot()
  before <- .getCohortManifestHash(projectPath = root)

  # Overwrite one cohort's JSON on disk with a different (valid CIRCE)
  # definition, so its rendered SQL — what getManifestHash() keys on — changes.
  rows <- cm_test_all_rows(manifest)
  target <- rows[rows$label == "Chronic Kidney Disease", ]
  fs::file_copy(
    testthat::test_path("test_files", "t2d.json"),
    cm_test_resolve_path(manifest, target$file_path),
    overwrite = TRUE
  )

  testthat::expect_false(identical(.getCohortManifestHash(projectPath = root), before))
})

testthat::test_that("legacy task history gets an empty pipeline version", {
  legacy_history <- data.frame(
    task_name = "01_task.R",
    config_block = "db",
    last_run_time = "2026-01-01 00:00:00",
    task_file_hash = "hash",
    cohort_manifest_hash = "manifest",
    status = "success",
    error_message = "",
    commit_sha = "",
    code_state = "unrecorded",
    stringsAsFactors = FALSE
  )

  history <- .ensureHistoryColumns(legacy_history)

  testthat::expect_true("pipeline_version" %in% names(history))
  testthat::expect_identical(history$pipeline_version[[1]], "")
})

testthat::test_that("task history namespaces are distinct lookup keys", {
  history <- .ensureHistoryColumns(data.frame(
    task_name = c("01_task.R", "01_task.R"),
    config_block = c("db", "db"),
    pipeline_version = c("develop_ml", "develop_ks"),
    last_run_time = c("2026-01-01 00:00:00", "2026-01-02 00:00:00"),
    task_file_hash = c("hash_ml", "hash_ks"),
    cohort_manifest_hash = c("manifest", "manifest"),
    status = c("success", "success"),
    error_message = c("", ""),
    commit_sha = c("", ""),
    code_state = c("unrecorded", "unrecorded"),
    stringsAsFactors = FALSE
  ))

  selected <- history[
    history$task_name == "01_task.R" &
      history$config_block == "db" &
      history$pipeline_version == "develop_ks",
    , drop = FALSE
  ]

  testthat::expect_equal(nrow(selected), 1L)
  testthat::expect_identical(selected$task_file_hash[[1]], "hash_ks")
})
