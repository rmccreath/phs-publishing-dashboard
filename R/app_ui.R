#' Application UI
#'
#' @description The user interface definition for the Shiny application
#' @param request Shiny request object
#' @return A Shiny UI
#' @noRd
app_ui <- function(request) {
  # Custom theme based on NHS/PHS branding
  phs_theme <- bslib::bs_theme(
    version = 5,
    preset = "bootstrap",

    # NHS/PHS colors
    primary = "#005EB8",      # NHS Blue
    secondary = "#768692",     # Dark Grey
    success = "#007F3B",      # Green
    info = "#0072CE",         # Bright Blue
    warning = "#FFB81C",      # Yellow
    danger = "#DA291C",       # Emergency Red

    # Typography
    base_font = bslib::font_google("Public Sans"),
    heading_font = bslib::font_google("Public Sans", wght = c(600, 700)),
    code_font = bslib::font_google("Fira Code"),

    # Spacing
    "spacer" = "1rem",

    # Custom CSS variables
    "navbar-bg" = "#005EB8",
    "navbar-fg" = "#FFFFFF"
  )

  # Add custom CSS
  phs_theme <- bslib::bs_add_rules(
    phs_theme,
    sass::sass_file(system.file("app/www/custom.css", package = "phsgovernance"))
  )

  bslib::page_navbar(
    title = "PHS Dashboard Governance Hub",
    theme = phs_theme,
    id = "main_navbar",
    fillable = TRUE,
    window_title = "PHS Governance Dashboard",

    # Header
    header = shiny::tags$head(
      shiny::tags$link(
        rel = "stylesheet",
        href = "https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css"
      ),
      shinyjs::useShinyjs(),
      waiter::useWaiter()
    ),

    # Dashboard Registry Tab
    bslib::nav_panel(
      title = "Registry",
      icon = bsicons::bs_icon("grid"),
      value = "registry",
      mod_dashboard_registry_ui("registry")
    ),

    # Approval Workflow Tab
    bslib::nav_panel(
      title = "Approvals",
      icon = bsicons::bs_icon("clipboard-check"),
      value = "approvals",
      mod_approval_workflow_ui("approvals")
    ),

    # Compliance Tab
    bslib::nav_panel(
      title = "Compliance",
      icon = bsicons::bs_icon("shield-check"),
      value = "compliance",
      mod_compliance_tracker_ui("compliance")
    ),

    # Analytics Tab
    bslib::nav_panel(
      title = "Analytics",
      icon = bsicons::bs_icon("bar-chart"),
      value = "analytics",
      mod_analytics_reporting_ui("analytics")
    ),

    # Spacer
    bslib::nav_spacer(),

    # User menu
    bslib::nav_menu(
      title = shiny::textOutput("user_display", inline = TRUE),
      icon = bsicons::bs_icon("person-circle"),
      align = "right",

      bslib::nav_item(
        shiny::tags$div(
          class = "px-3 py-2",
          shiny::tags$strong("Role: "),
          shiny::textOutput("user_role", inline = TRUE)
        )
      ),

      bslib::nav_item(
        shiny::tags$div(
          class = "px-3 py-2",
          shiny::tags$strong("Team: "),
          shiny::textOutput("user_team", inline = TRUE)
        )
      ),

      "----",

      bslib::nav_item(
        shiny::tags$a(
          href = "#",
          onclick = "location.reload();",
          class = "dropdown-item",
          bsicons::bs_icon("arrow-clockwise"),
          " Refresh"
        )
      ),

      bslib::nav_item(
        shiny::tags$a(
          href = "https://github.com/Public-Health-Scotland/phs-governance-docs",
          target = "_blank",
          class = "dropdown-item",
          bsicons::bs_icon("book"),
          " Documentation"
        )
      )
    ),

    # Footer
    footer = shiny::tags$footer(
      class = "border-top mt-auto py-3 text-center text-muted",
      shiny::tags$small(
        "PHS Dashboard Governance Hub v0.1.0 | ",
        "© Public Health Scotland ", format(Sys.Date(), "%Y")
      )
    )
  )
}
