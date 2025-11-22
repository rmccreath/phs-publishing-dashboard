#' Application Server
#'
#' @description The server logic for the Shiny application
#' @param input Shiny input
#' @param output Shiny output
#' @param session Shiny session
#' @noRd
app_server <- function(input, output, session) {
  # Get current user
  current_user <- reactive({
    get_current_user(session)
  })

  # Display user information in navbar
  output$user_display <- renderText({
    req(current_user())
    current_user()$full_name %||% current_user()$username
  })

  output$user_role <- renderText({
    req(current_user())
    tools::toTitleCase(gsub("_", " ", current_user()$role))
  })

  output$user_team <- renderText({
    req(current_user())
    current_user()$team
  })

  # Initialize database connection pool
  pool <- tryCatch(
    {
      create_db_pool()
    },
    error = function(e) {
      log_message(paste("Database connection error:", e$message), "WARNING")
      NULL
    }
  )

  # Initialize repositories
  dashboard_repo <- if (!is.null(pool)) {
    DashboardRepository$new(pool)
  } else {
    NULL
  }

  approval_repo <- if (!is.null(pool)) {
    ApprovalRepository$new(pool)
  } else {
    NULL
  }

  compliance_repo <- if (!is.null(pool)) {
    ComplianceRepository$new(pool)
  } else {
    NULL
  }

  # Initialize API services
  connect_service <- tryCatch(
    {
      PositConnectService$new()
    },
    error = function(e) {
      log_message(paste("Posit Connect service error:", e$message), "WARNING")
      NULL
    }
  )

  shinyapps_service <- tryCatch(
    {
      ShinyAppsService$new()
    },
    error = function(e) {
      log_message(paste("ShinyApps.io service error:", e$message), "WARNING")
      NULL
    }
  )

  github_service <- tryCatch(
    {
      GitHubService$new()
    },
    error = function(e) {
      log_message(paste("GitHub service error:", e$message), "WARNING")
      NULL
    }
  )

  # Initialize compliance service
  compliance_service <- if (!is.null(github_service)) {
    ComplianceService$new(github_service)
  } else {
    NULL
  }

  # Show warning if services are not available
  if (is.null(pool)) {
    shiny::showNotification(
      "Database connection not available. Running in demo mode.",
      type = "warning",
      duration = NULL,
      id = "db_warning"
    )
  }

  # Initialize modules
  if (!is.null(dashboard_repo)) {
    # Dashboard Registry Module
    mod_dashboard_registry_server(
      "registry",
      dashboard_repo = dashboard_repo,
      connect_service = connect_service,
      shinyapps_service = shinyapps_service,
      user = current_user
    )

    # Approval Workflow Module
    if (!is.null(approval_repo)) {
      mod_approval_workflow_server(
        "approvals",
        approval_repo = approval_repo,
        dashboard_repo = dashboard_repo,
        user = current_user
      )
    }

    # Compliance Tracker Module
    if (!is.null(compliance_repo) && !is.null(compliance_service)) {
      mod_compliance_tracker_server(
        "compliance",
        compliance_repo = compliance_repo,
        dashboard_repo = dashboard_repo,
        compliance_service = compliance_service,
        user = current_user
      )
    }

    # Analytics & Reporting Module
    mod_analytics_reporting_server(
      "analytics",
      dashboard_repo = dashboard_repo,
      user = current_user
    )
  }

  # Cleanup on session end
  session$onSessionEnded(function() {
    if (!is.null(pool)) {
      log_message("Closing database pool", "INFO")
      close_db_pool(pool)
    }

    # Clear API caches
    if (!is.null(connect_service)) {
      connect_service$clear_cache()
    }
    if (!is.null(shinyapps_service)) {
      shinyapps_service$clear_cache()
    }
    if (!is.null(github_service)) {
      github_service$clear_cache()
    }

    log_message("Session ended", "INFO")
  })
}
