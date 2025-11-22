#' Run the PHS Governance Dashboard Application
#'
#' @description Launch the Shiny application
#'
#' @param ... Additional arguments passed to \code{\link[shiny]{shinyApp}}
#' @param options List of options to pass to \code{\link[shiny]{runApp}}
#'
#' @return A Shiny app object
#'
#' @examples
#' \dontrun{
#' run_app()
#' }
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(..., options = list()) {
  # Set golem options
  golem_opts <- list(...)

  # Load configuration
  config_env <- Sys.getenv("R_CONFIG_ACTIVE", "default")
  message(sprintf("Loading configuration for environment: %s", config_env))

  # Check for required environment variables
  required_env_vars <- c(
    "DB_PASSWORD"
  )

  missing_vars <- required_env_vars[!nzchar(Sys.getenv(required_env_vars))]

  if (length(missing_vars) > 0) {
    warning(
      sprintf(
        "Missing environment variables: %s\nApplication may not function correctly.",
        paste(missing_vars, collapse = ", ")
      )
    )
  }

  # Create Shiny app
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = options,
      enableBookmarking = "url"
    ),
    golem_opts = golem_opts
  )
}
