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
    "
    .product-timeline {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 1rem;
      background: #f8f9fa;
      border-radius: 0.5rem;
    }
    .product-timeline .timeline-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 0.5rem;
      flex: 1;
    }
    .product-timeline .timeline-item i {
      font-size: 1.5rem;
    }
    "
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

    # Navigation links (using custom nav items that trigger routing)
    bslib::nav_item(
      shiny::tags$a(
        href = shiny.router::route_link("products"),
        class = "nav-link",
        bsicons::bs_icon("grid"),
        " Products"
      )
    ),

    bslib::nav_item(
      shiny::tags$a(
        href = shiny.router::route_link("approvals"),
        class = "nav-link",
        bsicons::bs_icon("clipboard-check"),
        " Approvals"
      )
    ),

    bslib::nav_item(
      shiny::tags$a(
        href = shiny.router::route_link("audits"),
        class = "nav-link",
        bsicons::bs_icon("search"),
        " Audits"
      )
    ),

    bslib::nav_item(
      shiny::tags$a(
        href = shiny.router::route_link("reviews"),
        class = "nav-link",
        bsicons::bs_icon("clock-history"),
        " Reviews"
      )
    ),

    bslib::nav_item(
      shiny::tags$a(
        href = shiny.router::route_link("analytics"),
        class = "nav-link",
        bsicons::bs_icon("bar-chart"),
        " Analytics"
      )
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

    # Main content area with router
    bslib::nav_panel(
      title = NULL,  # No title for the main panel
      value = "main_content",
      shiny.router::router_ui(
        # Products list page (default)
        shiny.router::route("products", mod_product_list_ui("product_list")),

        # Product detail page
        shiny.router::route("product", mod_product_detail_ui("product_detail")),

        # Approvals
        shiny.router::route("approvals", mod_approval_workflow_ui("approvals")),

        # Audits
        shiny.router::route("audits", mod_audit_management_ui("audits")),

        # Reviews
        shiny.router::route("reviews", mod_review_management_ui("reviews")),

        # Analytics
        shiny.router::route("analytics", mod_analytics_reporting_ui("analytics")),

        # Default route (redirect to products)
        shiny.router::route("/", mod_product_list_ui("product_list_default"))
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
