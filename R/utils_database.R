#' Database Utilities
#'
#' @description Functions for database connection and operations
#' @noRd

#' Create database connection pool
#'
#' @return A pool object
#' @export
create_db_pool <- function() {
  config <- config::get()

  pool::dbPool(
    drv = RPostgres::Postgres(),
    dbname = config$database$dbname,
    host = config$database$host,
    port = config$database$port,
    user = config$database$user,
    password = config$database$password,
    minSize = 1,
    maxSize = config$database$pool_size
  )
}

#' Close database pool
#'
#' @param pool Database pool object
#' @export
close_db_pool <- function(pool) {
  pool::poolClose(pool)
}

#' Dashboard Repository
#'
#' @description R6 class for dashboard data access
#' @export
DashboardRepository <- R6::R6Class(
  "DashboardRepository",
  private = list(
    pool = NULL
  ),

  public = list(
    #' @description Initialize repository
    #' @param pool Database pool
    initialize = function(pool) {
      private$pool <- pool
    },

    #' @description Get all dashboards
    #' @param filters Optional list of filters
    #' @return Data frame of dashboards
    get_all = function(filters = NULL) {
      query <- "SELECT * FROM vw_dashboard_overview WHERE 1=1"
      params <- list()

      if (!is.null(filters$status)) {
        query <- paste(query, "AND status = $1")
        params <- append(params, filters$status)
      }

      if (!is.null(filters$team)) {
        query <- paste(query, "AND team = $", length(params) + 1)
        params <- append(params, filters$team)
      }

      if (!is.null(filters$owner_id)) {
        query <- paste(query, "AND owner_id = $", length(params) + 1)
        params <- append(params, filters$owner_id)
      }

      query <- paste(query, "ORDER BY created_at DESC")

      pool::dbGetQuery(private$pool, query, params = params)
    },

    #' @description Get dashboard by ID
    #' @param dashboard_id Dashboard ID
    #' @return Data frame with single row
    get_by_id = function(dashboard_id) {
      pool::dbGetQuery(
        private$pool,
        "SELECT * FROM vw_dashboard_overview WHERE dashboard_id = $1",
        params = list(dashboard_id)
      )
    },

    #' @description Create dashboard
    #' @param dashboard_data List with dashboard fields
    #' @return Dashboard ID
    create = function(dashboard_data) {
      query <- "
        INSERT INTO dashboards (
          external_id, name, description, url, platform, type,
          owner_id, team, department, status, visibility,
          repository_url, documentation_url, tags, metadata
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
        ) RETURNING dashboard_id
      "

      result <- pool::dbGetQuery(
        private$pool,
        query,
        params = list(
          dashboard_data$external_id,
          dashboard_data$name,
          dashboard_data$description,
          dashboard_data$url,
          dashboard_data$platform,
          dashboard_data$type,
          dashboard_data$owner_id,
          dashboard_data$team,
          dashboard_data$department,
          dashboard_data$status %||% "draft",
          dashboard_data$visibility,
          dashboard_data$repository_url,
          dashboard_data$documentation_url,
          dashboard_data$tags,
          jsonlite::toJSON(dashboard_data$metadata, auto_unbox = TRUE)
        )
      )

      result$dashboard_id
    },

    #' @description Update dashboard
    #' @param dashboard_id Dashboard ID
    #' @param updates List of fields to update
    #' @return Number of rows updated
    update = function(dashboard_id, updates) {
      set_clause <- paste(
        names(updates),
        paste0("$", seq_along(updates)),
        sep = " = ",
        collapse = ", "
      )

      query <- glue::glue("
        UPDATE dashboards
        SET {set_clause}
        WHERE dashboard_id = ${length(updates) + 1}
      ")

      pool::dbExecute(
        private$pool,
        query,
        params = c(unname(updates), dashboard_id)
      )
    },

    #' @description Delete dashboard
    #' @param dashboard_id Dashboard ID
    #' @return Number of rows deleted
    delete = function(dashboard_id) {
      pool::dbExecute(
        private$pool,
        "DELETE FROM dashboards WHERE dashboard_id = $1",
        params = list(dashboard_id)
      )
    },

    #' @description Get team compliance summary
    #' @return Data frame with team compliance metrics
    get_team_compliance = function() {
      pool::dbGetQuery(private$pool, "SELECT * FROM vw_team_compliance ORDER BY team")
    }
  )
)

#' Approval Repository
#'
#' @description R6 class for approval workflow data access
#' @export
ApprovalRepository <- R6::R6Class(
  "ApprovalRepository",
  private = list(
    pool = NULL
  ),

  public = list(
    #' @description Initialize repository
    #' @param pool Database pool
    initialize = function(pool) {
      private$pool <- pool
    },

    #' @description Get all approvals
    #' @param filters Optional list of filters
    #' @return Data frame of approvals
    get_all = function(filters = NULL) {
      query <- "
        SELECT a.*, d.name as dashboard_name, u.full_name as submitted_by_name
        FROM approvals a
        JOIN dashboards d ON a.dashboard_id = d.dashboard_id
        JOIN users u ON a.submitted_by = u.user_id
        WHERE 1=1
      "
      params <- list()

      if (!is.null(filters$status)) {
        query <- paste(query, "AND a.status = $1")
        params <- append(params, filters$status)
      }

      if (!is.null(filters$submitted_by)) {
        query <- paste(query, "AND a.submitted_by = $", length(params) + 1)
        params <- append(params, filters$submitted_by)
      }

      query <- paste(query, "ORDER BY a.submitted_at DESC")

      pool::dbGetQuery(private$pool, query, params = params)
    },

    #' @description Create approval request
    #' @param approval_data List with approval fields
    #' @return Approval ID
    create = function(approval_data) {
      query <- "
        INSERT INTO approvals (
          dashboard_id, submitted_by, business_justification,
          target_audience, data_sources, update_schedule, support_plan,
          status, metadata
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9
        ) RETURNING approval_id
      "

      result <- pool::dbGetQuery(
        private$pool,
        query,
        params = list(
          approval_data$dashboard_id,
          approval_data$submitted_by,
          approval_data$business_justification,
          approval_data$target_audience,
          approval_data$data_sources,
          approval_data$update_schedule,
          approval_data$support_plan,
          approval_data$status %||% "pending",
          jsonlite::toJSON(approval_data$metadata %||% list(), auto_unbox = TRUE)
        )
      )

      result$approval_id
    },

    #' @description Update approval status
    #' @param approval_id Approval ID
    #' @param status New status
    #' @param reviewed_by User ID
    #' @param review_notes Optional notes
    #' @return Number of rows updated
    update_status = function(approval_id, status, reviewed_by, review_notes = NULL) {
      pool::dbExecute(
        private$pool,
        "
          UPDATE approvals
          SET status = $1, reviewed_by = $2, reviewed_at = CURRENT_TIMESTAMP,
              review_notes = $3
          WHERE approval_id = $4
        ",
        params = list(status, reviewed_by, review_notes, approval_id)
      )
    },

    #' @description Add sign-off
    #' @param approval_id Approval ID
    #' @param signoff_type Type (governance, technical, security)
    #' @param user_id User ID
    #' @return Number of rows updated
    add_signoff = function(approval_id, signoff_type, user_id) {
      field_name <- paste0(signoff_type, "_signoff")
      field_by <- paste0(signoff_type, "_signoff_by")
      field_at <- paste0(signoff_type, "_signoff_at")

      query <- glue::glue("
        UPDATE approvals
        SET {field_name} = TRUE,
            {field_by} = $1,
            {field_at} = CURRENT_TIMESTAMP
        WHERE approval_id = $2
      ")

      pool::dbExecute(private$pool, query, params = list(user_id, approval_id))
    }
  )
)

#' Compliance Repository
#'
#' @description R6 class for compliance data access
#' @export
ComplianceRepository <- R6::R6Class(
  "ComplianceRepository",
  private = list(
    pool = NULL
  ),

  public = list(
    #' @description Initialize repository
    #' @param pool Database pool
    initialize = function(pool) {
      private$pool <- pool
    },

    #' @description Get latest compliance check for dashboard
    #' @param dashboard_id Dashboard ID
    #' @return Data frame with compliance check
    get_latest = function(dashboard_id) {
      pool::dbGetQuery(
        private$pool,
        "
          SELECT * FROM compliance_checks
          WHERE dashboard_id = $1
          ORDER BY check_date DESC
          LIMIT 1
        ",
        params = list(dashboard_id)
      )
    },

    #' @description Get compliance history
    #' @param dashboard_id Dashboard ID
    #' @param limit Number of records
    #' @return Data frame with compliance checks
    get_history = function(dashboard_id, limit = 10) {
      pool::dbGetQuery(
        private$pool,
        "
          SELECT * FROM compliance_checks
          WHERE dashboard_id = $1
          ORDER BY check_date DESC
          LIMIT $2
        ",
        params = list(dashboard_id, limit)
      )
    },

    #' @description Create compliance check
    #' @param check_data List with compliance fields
    #' @return Check ID
    create = function(check_data) {
      query <- "
        INSERT INTO compliance_checks (
          dashboard_id, accessibility_score, accessibility_notes,
          documentation_score, documentation_notes,
          repository_score, repository_notes,
          testing_score, testing_notes,
          security_score, security_notes,
          overall_score, grade, compliant,
          checked_by, metadata
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16
        ) RETURNING check_id
      "

      result <- pool::dbGetQuery(
        private$pool,
        query,
        params = list(
          check_data$dashboard_id,
          check_data$accessibility_score,
          check_data$accessibility_notes,
          check_data$documentation_score,
          check_data$documentation_notes,
          check_data$repository_score,
          check_data$repository_notes,
          check_data$testing_score,
          check_data$testing_notes,
          check_data$security_score,
          check_data$security_notes,
          check_data$overall_score,
          check_data$grade,
          check_data$compliant,
          check_data$checked_by %||% "system",
          jsonlite::toJSON(check_data$metadata %||% list(), auto_unbox = TRUE)
        )
      )

      result$check_id
    }
  )
)
