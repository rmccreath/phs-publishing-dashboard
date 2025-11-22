#' Configuration Utilities
#'
#' @description Safe config loading with defaults for demo mode
#' @noRd

#' Get default configuration
#'
#' @return List with default config values
#' @noRd
get_default_config <- function() {
  list(
    app = list(
      name = "PHS Dashboard Governance Hub",
      version = "0.1.0",
      port = 3838
    ),

    database = list(
      driver = "PostgreSQL",
      host = "localhost",
      port = 5432,
      dbname = "phs_governance",
      user = "phs_user",
      password = "",
      pool_size = 5
    ),

    apis = list(
      posit_connect = list(
        base_url = "",
        api_key = "",
        rate_limit = 1000,
        cache_ttl = 3600
      ),
      shinyapps_io = list(
        base_url = "https://api.shinyapps.io/v1",
        api_key = "",
        api_secret = "",
        rate_limit = 5000,
        cache_ttl = 3600
      ),
      github = list(
        base_url = "https://api.github.com",
        token = "",
        org = "Public-Health-Scotland",
        rate_limit = 5000,
        cache_ttl = 3600
      )
    ),

    rbac = list(
      roles = c("admin", "governance", "team_lead", "owner", "viewer"),
      permissions = list(
        admin = c("view_all", "edit_all", "approve", "configure_system"),
        governance = c("view_all", "approve", "manage_compliance"),
        team_lead = c("view_team", "submit", "approve_team"),
        owner = c("view_own", "submit", "edit_own"),
        viewer = c("view_summary")
      )
    ),

    compliance = list(
      metrics = list(
        accessibility = list(weight = 0.25, required = TRUE),
        documentation = list(weight = 0.20, required = TRUE),
        repository = list(weight = 0.15, required = TRUE),
        testing = list(weight = 0.15, required = FALSE),
        security = list(weight = 0.25, required = TRUE)
      ),
      thresholds = list(
        excellent = 90,
        good = 75,
        acceptable = 60,
        poor = 0
      )
    )
  )
}

#' Safe config getter with fallback to defaults
#'
#' @param value Optional specific config value to retrieve
#' @param config Optional config environment
#' @param default Optional default value if config not found
#' @return Config value or default
#' @export
safe_get_config <- function(value = NULL, config = Sys.getenv("R_CONFIG_ACTIVE", "default"), default = NULL) {
  tryCatch({
    # Try to find config file
    config_file <- NULL

    # Check inst/config/config.yml (during development)
    if (file.exists("inst/config/config.yml")) {
      config_file <- "inst/config/config.yml"
    }

    # Check if in package (system.file)
    pkg_config <- system.file("config", "config.yml", package = "phsgovernance")
    if (nchar(pkg_config) > 0 && file.exists(pkg_config)) {
      config_file <- pkg_config
    }

    # Try to load config
    if (!is.null(config_file)) {
      cfg <- config::get(file = config_file, config = config)

      if (!is.null(value)) {
        # Navigate to specific value (e.g., "rbac.permissions.admin")
        value_parts <- strsplit(value, "\\.")[[1]]
        result <- cfg
        for (part in value_parts) {
          result <- result[[part]]
          if (is.null(result)) break
        }
        return(if (!is.null(result)) result else default)
      }

      return(cfg)
    }

    # No config file found, use defaults
    message("Config file not found, using defaults")
    cfg <- get_default_config()

    if (!is.null(value)) {
      value_parts <- strsplit(value, "\\.")[[1]]
      result <- cfg
      for (part in value_parts) {
        result <- result[[part]]
        if (is.null(result)) break
      }
      return(if (!is.null(result)) result else default)
    }

    return(cfg)

  }, error = function(e) {
    message("Error loading config: ", e$message, " - using defaults")
    cfg <- get_default_config()

    if (!is.null(value)) {
      value_parts <- strsplit(value, "\\.")[[1]]
      result <- cfg
      for (part in value_parts) {
        result <- result[[part]]
        if (is.null(result)) break
      }
      return(if (!is.null(result)) result else default)
    }

    return(cfg)
  })
}
