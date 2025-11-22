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

  # Check if running in demo mode
  demo_mode <- is_demo_mode()

  if (demo_mode) {
    log_message("Running in DEMO MODE with sample data", "INFO")
    shiny::showNotification(
      "Running in demo mode with sample data. No database required.",
      type = "message",
      duration = 10,
      id = "demo_mode_notification"
    )
  }

  # Initialize database connection pool (skip in demo mode)
  pool <- if (!demo_mode) {
    tryCatch(
      {
        create_db_pool()
      },
      error = function(e) {
        log_message(paste("Database connection error:", e$message), "WARNING")
        NULL
      }
    )
  } else {
    NULL
  }

  # Initialize repositories (use mock repos in demo mode)
  dashboard_repo <- if (demo_mode) {
    tryCatch({
      repo <- MockDashboardRepository$new()
      log_message(paste("Created MockDashboardRepository with", nrow(repo$get_all()), "dashboards"), "INFO")
      repo
    }, error = function(e) {
      log_message(paste("Error creating MockDashboardRepository:", e$message), "ERROR")
      showNotification(paste("Error loading demo data:", e$message), type = "error", duration = 10)
      NULL
    })
  } else if (!is.null(pool)) {
    DashboardRepository$new(pool)
  } else {
    NULL
  }

  approval_repo <- if (demo_mode) {
    tryCatch({
      repo <- MockApprovalRepository$new()
      log_message(paste("Created MockApprovalRepository with", nrow(repo$get_all()), "approvals"), "INFO")
      repo
    }, error = function(e) {
      log_message(paste("Error creating MockApprovalRepository:", e$message), "ERROR")
      NULL
    })
  } else if (!is.null(pool)) {
    ApprovalRepository$new(pool)
  } else {
    NULL
  }

  compliance_repo <- if (demo_mode) {
    tryCatch({
      MockComplianceRepository$new()
    }, error = function(e) {
      log_message(paste("Error creating MockComplianceRepository:", e$message), "ERROR")
      NULL
    })
  } else if (!is.null(pool)) {
    ComplianceRepository$new(pool)
  } else {
    NULL
  }

  # Initialize API services (wrapped for safety in demo mode)
  connect_service <- tryCatch(
    {
      svc <- PositConnectService$new()
      # Verify it's a proper R6 object with required methods
      if (!is.null(svc) && "clear_cache" %in% names(svc)) {
        svc
      } else {
        NULL
      }
    },
    error = function(e) {
      log_message(paste("Posit Connect service error:", e$message), "WARNING")
      NULL
    },
    warning = function(w) {
      log_message(paste("Posit Connect service warning:", w$message), "INFO")
      # Continue despite warnings
      invokeRestart("muffleWarning")
    }
  )

  shinyapps_service <- tryCatch(
    {
      svc <- ShinyAppsService$new()
      if (!is.null(svc) && "clear_cache" %in% names(svc)) {
        svc
      } else {
        NULL
      }
    },
    error = function(e) {
      log_message(paste("ShinyApps.io service error:", e$message), "WARNING")
      NULL
    },
    warning = function(w) {
      log_message(paste("ShinyApps.io service warning:", w$message), "INFO")
      invokeRestart("muffleWarning")
    }
  )

  github_service <- tryCatch(
    {
      svc <- GitHubService$new()
      if (!is.null(svc) && "clear_cache" %in% names(svc)) {
        svc
      } else {
        NULL
      }
    },
    error = function(e) {
      log_message(paste("GitHub service error:", e$message), "WARNING")
      NULL
    },
    warning = function(w) {
      log_message(paste("GitHub service warning:", w$message), "INFO")
      invokeRestart("muffleWarning")
    }
  )

  # Initialize compliance service
  compliance_service <- if (!is.null(github_service)) {
    ComplianceService$new(github_service)
  } else {
    NULL
  }

  # Show appropriate notification based on mode
  if (demo_mode) {
    shiny::showNotification(
      HTML(paste0(
        "📊 <strong>Demo Mode Active</strong><br/>",
        "Using sample data. No database required.<br/>",
        if (!is.null(dashboard_repo)) paste0(nrow(dashboard_repo$get_all()), " sample dashboards loaded.") else "Error loading demo data."
      )),
      type = "message",
      duration = NULL,
      id = "demo_mode_info"
    )
  } else if (is.null(pool) && !demo_mode) {
    shiny::showNotification(
      "Database connection not available. Set DEMO_MODE=true to use sample data.",
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
