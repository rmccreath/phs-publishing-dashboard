#' Demo Data Utilities
#'
#' @description Functions to generate sample data for demo mode
#' @noRd

#' Generate sample products (new workflow)
#'
#' @return Data frame of sample products
#' @export
generate_sample_dashboards <- function() {
  n <- 25

  # Generate lifecycle stages with realistic distribution
  lifecycle_stages <- sample(
    c("approved", "in_development", "in_audit", "deployed", "archived"),
    n,
    replace = TRUE,
    prob = c(0.1, 0.1, 0.15, 0.6, 0.05)
  )

  # Generate status based on lifecycle stage
  current_status <- sapply(lifecycle_stages, function(stage) {
    switch(stage,
      approved = "awaiting_development",
      in_development = "in_progress",
      in_audit = sample(c("audit_in_progress", "audit_review"), 1),
      deployed = sample(c("active", "review_due", "flagged"), 1, prob = c(0.7, 0.2, 0.1)),
      archived = "archived"
    )
  })

  tibble::tibble(
    product_id = paste0("prod-", 1:n),
    dashboard_id = paste0("prod-", 1:n),  # Alias for compatibility
    external_id = paste0("ext-", 1:n),
    name = c(
      "COVID-19 Weekly Dashboard",
      "Hospital Admissions Monitor",
      "Vaccination Progress Tracker",
      "Mental Health Services Report",
      "Cancer Waiting Times Dashboard",
      "GP Practice Performance",
      "Emergency Department Monitor",
      "Prescription Analytics Portal",
      "Population Health Trends",
      "Staff Wellbeing Dashboard",
      "Quality Improvement Tracker",
      "Patient Experience Survey Dashboard",
      "Mortality Statistics Report",
      "Dental Services Overview",
      "Community Care Monitor",
      "Health Inequalities Report",
      "Maternal Health Dashboard",
      "Chronic Disease Management Portal",
      "Primary Care Access Dashboard",
      "Public Health Campaigns Tracker",
      "Infection Prevention Dashboard",
      "Winter Pressures Monitor",
      "Workforce Planning Tool",
      "Resource Allocation Dashboard",
      "Clinical Outcomes Tracker"
    ),
    description = c(
      "Weekly tracking of COVID-19 metrics across Scotland",
      "Real-time monitoring of hospital admission capacity",
      "Comprehensive vaccine rollout progress tracking",
      "Utilization patterns of mental health services",
      "Monitoring cancer treatment pathways and waiting times",
      "Quality metrics for primary care practices",
      "A&E department performance and wait times",
      "Analysis of medication usage patterns",
      "Long-term population health indicator trends",
      "Staff satisfaction and retention metrics",
      "Tracking quality improvement initiatives",
      "Patient feedback and experience analysis",
      "Mortality trend analysis by demographic",
      "Dental service delivery and accessibility",
      "Community care outcomes and capacity",
      "Health equity metrics across populations",
      "Maternal and child health indicators",
      "Long-term condition management outcomes",
      "GP access metrics and waiting time analysis",
      "Health promotion campaign effectiveness",
      "Hospital infection prevention metrics",
      "Winter demand and capacity planning",
      "NHS workforce planning and projections",
      "Resource allocation optimization tool",
      "Clinical outcomes across specialties"
    ),
    # Product type using new schema values
    type = sample(
      c("shiny_dashboard", "quarto_report", "dash_app", "api_service"),
      n,
      replace = TRUE,
      prob = c(0.5, 0.3, 0.15, 0.05)
    ),
    department = sample(
      c("Digital & Technology", "Public Health", "Healthcare Quality & Strategy", "Intelligence"),
      n,
      replace = TRUE
    ),
    team = sample(
      c("Analytics", "Intelligence", "Data Science", "Operations", "Quality", "Digital Services"),
      n,
      replace = TRUE
    ),

    # New workflow fields
    lifecycle_stage = lifecycle_stages,
    current_status = current_status,

    # User/ownership
    created_by = sample(c("alice.smith", "bob.jones", "carol.white", "david.brown", "eve.wilson"), n, replace = TRUE),
    owner_id = paste0("user-", sample(1:5, n, replace = TRUE)),
    owner_name = sample(c("Alice Smith", "Bob Jones", "Carol White", "David Brown", "Eve Wilson"), n, replace = TRUE),
    owner_email = paste0("user", sample(1:5, n, replace = TRUE), "@phs.scot"),

    # Legacy fields for compatibility
    url = ifelse(lifecycle_stages == "deployed",
      paste0("https://connect.phs.scot/dashboard-", 1:n),
      NA_character_
    ),
    platform = sample(c("posit_connect", "shinyapps_io", "other"), n, replace = TRUE),
    status = current_status,  # Alias for compatibility
    visibility = sample(c("public", "internal", "restricted"), n, replace = TRUE),
    deployment_date = as.POSIXct(ifelse(
      lifecycle_stages == "deployed",
      Sys.Date() - sample(1:365, n, replace = TRUE),
      NA
    )),
    last_updated = as.POSIXct(Sys.Date() - sample(1:30, n, replace = TRUE)),
    update_frequency = sample(c("daily", "weekly", "monthly", "quarterly"), n, replace = TRUE),

    # URLs
    repository_url = ifelse(
      runif(n) > 0.2,
      paste0("https://github.com/PHS/product-", 1:n),
      NA_character_
    ),
    documentation_url = ifelse(
      runif(n) > 0.3,
      paste0("https://docs.phs.scot/product-", 1:n),
      NA_character_
    ),

    # Metadata
    tags = I(lapply(1:n, function(x) {
      as.vector(sample(c("covid", "hospital", "vaccine", "gp", "mental-health", "quality", "performance"),
        sample(2:4, 1)))
    })),
    keywords = I(lapply(1:n, function(x) {
      as.vector(sample(c("analytics", "monitoring", "reporting", "dashboard", "tracker"),
        sample(2:3, 1)))
    })),
    metadata = I(lapply(1:n, function(x) list())),

    # Compliance scores (only for deployed products)
    overall_score = ifelse(lifecycle_stages == "deployed",
      round(runif(n, 55, 98), 1),
      NA_real_
    ),
    grade = ifelse(lifecycle_stages == "deployed",
      sample(c("excellent", "good", "acceptable", "poor"), n, replace = TRUE, prob = c(0.3, 0.4, 0.25, 0.05)),
      NA_character_
    ),
    compliant = ifelse(!is.na(overall_score), overall_score >= 60, NA),
    last_compliance_check = as.POSIXct(ifelse(
      lifecycle_stages == "deployed",
      Sys.Date() - sample(1:30, n, replace = TRUE),
      NA
    )),
    accessibility_score = ifelse(lifecycle_stages == "deployed", round(runif(n, 60, 100), 1), NA_real_),
    documentation_score = ifelse(lifecycle_stages == "deployed", round(runif(n, 50, 100), 1), NA_real_),
    repository_score = ifelse(lifecycle_stages == "deployed", round(runif(n, 40, 100), 1), NA_real_),
    security_score = ifelse(lifecycle_stages == "deployed", round(runif(n, 70, 100), 1), NA_real_),

    # Timestamps
    created_at = as.POSIXct(Sys.Date() - sample(30:730, n, replace = TRUE)),
    updated_at = as.POSIXct(Sys.Date() - sample(1:30, n, replace = TRUE))
  )
}

#' Generate sample approvals
#'
#' @return Data frame of sample approvals
#' @export
generate_sample_approvals <- function() {
  tibble::tibble(
    approval_id = paste0("approval-", 1:10),
    dashboard_id = paste0("demo-", sample(15:20, 10, replace = TRUE)),
    dashboard_name = paste("Dashboard", sample(15:20, 10, replace = TRUE)),
    submitted_by = paste0("user-", sample(1:5, 10, replace = TRUE)),
    submitted_by_name = sample(c("Alice Smith", "Bob Jones", "Carol White"), 10, replace = TRUE),
    submitted_at = as.POSIXct(Sys.Date() - sample(1:30, 10, replace = TRUE)),
    business_justification = paste(
      "This dashboard is needed to provide stakeholders with timely insights into",
      sample(c("service performance", "patient outcomes", "operational efficiency"), 10, replace = TRUE)
    ),
    target_audience = sample(c("Senior Management", "Clinical Teams", "Public", "Commissioners"), 10, replace = TRUE),
    data_sources = "NHS Scotland data warehouse, Public Health Scotland datasets",
    update_schedule = sample(c("daily", "weekly", "monthly"), 10, replace = TRUE),
    support_plan = "Maintained by the Analytics team with on-call support",
    status = sample(c("pending", "under_review", "approved", "rejected", "requires_changes"), 10, replace = TRUE, prob = c(0.3, 0.2, 0.3, 0.1, 0.1)),
    reviewed_by = ifelse(runif(10) > 0.5, paste0("user-", sample(1:2, 10, replace = TRUE)), NA_character_),
    reviewed_at = as.POSIXct(ifelse(runif(10) > 0.5, Sys.Date() - sample(1:15, 10, replace = TRUE), NA)),
    review_notes = ifelse(runif(10) > 0.7, "Please update documentation", NA_character_),
    governance_signoff = runif(10) > 0.6,
    governance_signoff_by = NA_character_,
    governance_signoff_at = as.POSIXct(NA),
    technical_signoff = runif(10) > 0.7,
    technical_signoff_by = NA_character_,
    technical_signoff_at = as.POSIXct(NA),
    security_signoff = runif(10) > 0.8,
    security_signoff_by = NA_character_,
    security_signoff_at = as.POSIXct(NA),
    metadata = I(lapply(1:10, function(x) list())),
    created_at = as.POSIXct(Sys.Date() - sample(30:60, 10, replace = TRUE)),
    updated_at = as.POSIXct(Sys.Date() - sample(1:30, 10, replace = TRUE))
  )
}

#' Load demo data from file
#'
#' @param file_name File name (dashboards.rds or approvals.rds)
#' @return Data frame or NULL if file doesn't exist
#' @noRd
load_demo_data <- function(file_name) {
  # Try to load from inst/demo_data
  demo_file <- system.file("demo_data", file_name, package = "phsgovernance")

  if (file.exists(demo_file)) {
    message("Loading demo data from: ", demo_file)
    return(readRDS(demo_file))
  }

  # Try local path (for development)
  local_file <- file.path("inst/demo_data", file_name)
  if (file.exists(local_file)) {
    message("Loading demo data from: ", local_file)
    return(readRDS(local_file))
  }

  message("No saved demo data found, generating fresh data")
  NULL
}

#' Mock Dashboard Repository for Demo Mode
#'
#' @description In-memory repository that doesn't require a database
#' @export
MockDashboardRepository <- R6::R6Class(
  "MockDashboardRepository",
  private = list(
    data = NULL
  ),

  public = list(
    initialize = function() {
      # Try to load saved demo data first
      saved_data <- load_demo_data("dashboards.rds")

      if (!is.null(saved_data)) {
        private$data <- saved_data
        message("Loaded ", nrow(saved_data), " dashboards from demo data file")
      } else {
        private$data <- generate_sample_dashboards()
        message("Generated ", nrow(private$data), " sample dashboards")
      }
    },

    get_all = function(filters = NULL) {
      data <- private$data

      if (!is.null(filters$status)) {
        data <- dplyr::filter(data, status == filters$status)
      }

      if (!is.null(filters$team)) {
        data <- dplyr::filter(data, team == filters$team)
      }

      if (!is.null(filters$owner_id)) {
        data <- dplyr::filter(data, owner_id == filters$owner_id)
      }

      data
    },

    get_by_id = function(dashboard_id) {
      dplyr::filter(private$data, dashboard_id == !!dashboard_id)
    },

    create = function(dashboard_data) {
      new_id <- paste0("demo-", nrow(private$data) + 1)

      new_row <- tibble::tibble(
        dashboard_id = new_id,
        external_id = dashboard_data$external_id %||% new_id,
        name = dashboard_data$name,
        description = dashboard_data$description %||% "",
        url = dashboard_data$url,
        platform = dashboard_data$platform,
        type = dashboard_data$type %||% "shiny",
        owner_id = dashboard_data$owner_id,
        owner_name = "Demo User",
        owner_email = "demo@phs.scot",
        team = dashboard_data$team,
        department = dashboard_data$department,
        status = dashboard_data$status %||% "draft",
        visibility = dashboard_data$visibility %||% "internal",
        deployment_date = as.POSIXct(Sys.time()),
        last_updated = as.POSIXct(Sys.time()),
        update_frequency = NA_character_,
        repository_url = dashboard_data$repository_url,
        documentation_url = dashboard_data$documentation_url,
        tags = I(list(dashboard_data$tags %||% character())),
        keywords = I(list(character())),
        metadata = I(list(list())),
        overall_score = NA_real_,
        grade = NA_character_,
        compliant = NA,
        last_compliance_check = as.POSIXct(NA),
        accessibility_score = NA_real_,
        documentation_score = NA_real_,
        repository_score = NA_real_,
        security_score = NA_real_,
        created_at = as.POSIXct(Sys.time()),
        updated_at = as.POSIXct(Sys.time())
      )

      private$data <- dplyr::bind_rows(private$data, new_row)
      new_id
    },

    update = function(dashboard_id, updates) {
      # In demo mode, just log the update
      message("Demo mode: Update logged for dashboard ", dashboard_id)
      1
    },

    delete = function(dashboard_id) {
      private$data <- dplyr::filter(private$data, dashboard_id != !!dashboard_id)
      1
    },

    get_team_compliance = function() {
      private$data %>%
        dplyr::filter(!is.na(overall_score)) %>%
        dplyr::group_by(team) %>%
        dplyr::summarise(
          total_dashboards = dplyr::n(),
          compliant_dashboards = sum(compliant, na.rm = TRUE),
          avg_compliance_score = round(mean(overall_score, na.rm = TRUE), 2),
          excellent_count = sum(grade == "excellent", na.rm = TRUE),
          good_count = sum(grade == "good", na.rm = TRUE),
          acceptable_count = sum(grade == "acceptable", na.rm = TRUE),
          poor_count = sum(grade == "poor", na.rm = TRUE),
          .groups = "drop"
        )
    }
  )
)

#' Mock Approval Repository for Demo Mode
#'
#' @export
MockApprovalRepository <- R6::R6Class(
  "MockApprovalRepository",
  private = list(
    data = NULL
  ),

  public = list(
    initialize = function() {
      # Try to load saved demo data first
      saved_data <- load_demo_data("approvals.rds")

      if (!is.null(saved_data)) {
        private$data <- saved_data
        message("Loaded ", nrow(saved_data), " approvals from demo data file")
      } else {
        private$data <- generate_sample_approvals()
        message("Generated ", nrow(private$data), " sample approvals")
      }
    },

    get_all = function(filters = NULL) {
      data <- private$data

      if (!is.null(filters$status)) {
        data <- dplyr::filter(data, status == filters$status)
      }

      data
    },

    get_by_product_id = function(product_id) {
      data <- dplyr::filter(private$data, dashboard_id == !!product_id)
      if (nrow(data) > 0) {
        return(data[1, ])  # Return first match
      }
      NULL
    },

    create = function(approval_data) {
      message("Demo mode: Approval created")
      paste0("approval-", nrow(private$data) + 1)
    },

    update_status = function(approval_id, status, reviewed_by, review_notes = NULL) {
      message("Demo mode: Approval status updated to ", status)
      1
    },

    add_signoff = function(approval_id, signoff_type, user_id) {
      message("Demo mode: Sign-off added for ", signoff_type)
      1
    }
  )
)

#' Mock Compliance Repository for Demo Mode
#'
#' @export
MockComplianceRepository <- R6::R6Class(
  "MockComplianceRepository",
  private = list(
    data = NULL
  ),

  public = list(
    initialize = function() {
      private$data <- tibble::tibble()
    },

    get_latest = function(dashboard_id) {
      tibble::tibble()
    },

    get_history = function(dashboard_id, limit = 10) {
      tibble::tibble()
    },

    create = function(check_data) {
      message("Demo mode: Compliance check logged")
      paste0("check-", nrow(private$data) + 1)
    }
  )
)

#' Check if running in demo mode
#'
#' @return Boolean
#' @export
is_demo_mode <- function() {
  demo_mode <- Sys.getenv("DEMO_MODE", "false")
  tolower(demo_mode) %in% c("true", "1", "yes")
}
