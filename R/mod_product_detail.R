#' Product Detail Module
#'
#' @description Product detail page showing complete history and information
#' @name mod_product_detail
NULL

#' Product Detail UI
#'
#' @param id Module ID
#' @export
mod_product_detail_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    # Breadcrumbs
    shiny::uiOutput(ns("breadcrumbs")),

    # Product header
    bslib::card(
      bslib::card_header(
        shiny::div(
          class = "d-flex justify-content-between align-items-start",
          shiny::div(
            shiny::h3(shiny::textOutput(ns("product_name"), inline = TRUE), class = "mb-1"),
            shiny::p(shiny::textOutput(ns("product_description")), class = "text-muted mb-0")
          ),
          shiny::div(
            class = "btn-group",
            shiny::uiOutput(ns("action_buttons"))
          )
        )
      ),
      bslib::card_body(
        bslib::layout_column_wrap(
          width = 1/4,

          shiny::div(
            shiny::strong("Type:"),
            shiny::br(),
            shiny::textOutput(ns("product_type"))
          ),

          shiny::div(
            shiny::strong("Department:"),
            shiny::br(),
            shiny::textOutput(ns("product_department"))
          ),

          shiny::div(
            shiny::strong("Team:"),
            shiny::br(),
            shiny::textOutput(ns("product_team"))
          ),

          shiny::div(
            shiny::strong("Stage:"),
            shiny::br(),
            shiny::uiOutput(ns("product_stage_badge"))
          )
        )
      )
    ),

    # Timeline visualization
    bslib::card(
      bslib::card_header("Product Timeline"),
      bslib::card_body(
        shiny::uiOutput(ns("timeline"))
      )
    ),

    # Tabbed content
    bslib::navset_card_tab(
      id = ns("detail_tabs"),
      full_screen = TRUE,

      # Overview tab
      bslib::nav_panel(
        title = "Overview",
        icon = bsicons::bs_icon("info-circle"),

        bslib::layout_columns(
          col_widths = c(6, 6),

          bslib::card(
            bslib::card_header("Details"),
            bslib::card_body(
              shiny::uiOutput(ns("overview_details"))
            )
          ),

          bslib::card(
            bslib::card_header("Key Metrics"),
            bslib::card_body(
              shiny::uiOutput(ns("overview_metrics"))
            )
          )
        )
      ),

      # Approval tab
      bslib::nav_panel(
        title = "Approval",
        icon = bsicons::bs_icon("clipboard-check"),
        shiny::uiOutput(ns("approval_content"))
      ),

      # Audit tab
      bslib::nav_panel(
        title = "Audit",
        icon = bsicons::bs_icon("search"),
        shiny::uiOutput(ns("audit_content"))
      ),

      # Deployment tab
      bslib::nav_panel(
        title = "Deployment",
        icon = bsicons::bs_icon("cloud-upload"),
        shiny::uiOutput(ns("deployment_content"))
      ),

      # Reviews tab
      bslib::nav_panel(
        title = "Reviews",
        icon = bsicons::bs_icon("clock-history"),
        shiny::uiOutput(ns("reviews_content"))
      ),

      # Analytics tab (if GA linked)
      bslib::nav_panel(
        title = "Analytics",
        icon = bsicons::bs_icon("graph-up"),
        shiny::uiOutput(ns("analytics_content"))
      )
    )
  )
}

#' Product Detail Server
#'
#' @param id Module ID
#' @param product_repo Product repository instance
#' @param approval_repo Approval repository instance
#' @param audit_repo Audit repository instance (future)
#' @param user Reactive user object
#' @export
mod_product_detail_server <- function(id, product_repo, approval_repo, audit_repo = NULL, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Get product ID from URL
    product_id <- reactive({
      query <- shiny.router::get_query_param()
      if (!is.null(query) && "id" %in% names(query)) {
        return(query[["id"]])
      }
      NULL
    })

    # Load product data
    product <- reactive({
      req(product_id())
      product_repo$get_by_id(product_id())
    })

    # Load approval data
    approval <- reactive({
      req(product_id())
      approval_repo$get_by_product_id(product_id())
    })

    # Breadcrumbs
    output$breadcrumbs <- renderUI({
      req(product())
      product_breadcrumbs(product()$name)
    })

    # Action buttons (conditional on permissions)
    output$action_buttons <- renderUI({
      buttons <- list()

      # Flag for review - only admins can flag products
      if (has_permission(user(), "approve")) {  # Admin permission
        buttons[[length(buttons) + 1]] <- shiny::actionButton(
          ns("btn_flag_review"),
          "Flag for Review",
          icon = shiny::icon("flag"),
          class = "btn-warning"
        )
      }

      # Edit button - admins and product owners
      if (has_permission(user(), "approve") ||
          (has_permission(user(), "submit") && !is.null(product()) &&
           product()$owner_id == user()$user_id)) {
        buttons[[length(buttons) + 1]] <- shiny::actionButton(
          ns("btn_edit"),
          "Edit",
          icon = shiny::icon("pencil"),
          class = "btn-outline-primary"
        )
      }

      if (length(buttons) > 0) {
        shiny::tagList(buttons)
      } else {
        NULL
      }
    })

    # Product header outputs
    output$product_name <- renderText({
      req(product())
      as.character(product()$name %||% "Unknown Product")
    })

    output$product_description <- renderText({
      req(product())
      as.character(product()$description %||% "No description available")
    })

    output$product_type <- renderText({
      req(product())
      type_labels <- c(
        shiny_dashboard = "Shiny Dashboard",
        quarto_report = "Quarto Report",
        dash_app = "Dash Application",
        api_service = "API Service"
      )
      prod_type <- product()$type
      result <- if (!is.null(prod_type) && prod_type %in% names(type_labels)) {
        type_labels[[prod_type]]
      } else if (!is.null(prod_type)) {
        tools::toTitleCase(as.character(prod_type))
      } else {
        "Not specified"
      }
      as.character(result)
    })

    output$product_department <- renderText({
      req(product())
      as.character(product()$department %||% "Not specified")
    })

    output$product_team <- renderText({
      req(product())
      as.character(product()$team %||% "Not specified")
    })

    output$product_stage_badge <- renderUI({
      req(product())
      stage <- product()$lifecycle_stage

      color <- switch(stage,
        approved = "warning",
        in_development = "info",
        in_audit = "primary",
        deployed = "success",
        archived = "secondary",
        "secondary"
      )

      label <- switch(stage,
        approved = "Approved",
        in_development = "In Development",
        in_audit = "In Audit",
        deployed = "Deployed",
        archived = "Archived",
        tools::toTitleCase(stage)
      )

      shiny::span(
        class = paste0("badge bg-", color),
        label
      )
    })

    # Timeline visualization
    output$timeline <- renderUI({
      req(product())

      # Create timeline based on lifecycle stage
      stages <- list(
        list(name = "Approval", icon = "clipboard-check", status = "completed"),
        list(name = "Development", icon = "code", status = "completed"),
        list(name = "Audit", icon = "search", status = "pending"),
        list(name = "Deployment", icon = "cloud-upload", status = "pending"),
        list(name = "Reviews", icon = "clock-history", status = "pending")
      )

      # Update status based on current stage
      current_stage <- product()$lifecycle_stage
      stage_order <- c("approved", "in_development", "in_audit", "deployed")
      current_index <- which(stage_order == current_stage)

      if (length(current_index) > 0 && current_index > 0) {
        # Mark stages as completed up to current
        for (i in seq_len(current_index)) {
          if (i <= length(stages)) {
            stages[[i]]$status <- "completed"
          }
        }
        # Mark current stage as active (if not past the end)
        next_stage <- current_index + 1
        if (next_stage <= length(stages)) {
          stages[[next_stage]]$status <- "active"
        }
      }

      # Create timeline HTML
      timeline_items <- purrr::map(stages, function(stage) {
        status_class <- switch(stage$status,
          completed = "text-success",
          active = "text-primary",
          "text-muted"
        )

        icon_html <- if (stage$status == "completed") {
          "<i class='bi bi-check-circle-fill'></i>"
        } else if (stage$status == "active") {
          "<i class='bi bi-arrow-right-circle-fill'></i>"
        } else {
          "<i class='bi bi-circle'></i>"
        }

        shiny::div(
          class = paste("timeline-item", status_class),
          shiny::HTML(icon_html),
          shiny::span(stage$name)
        )
      })

      shiny::div(
        class = "product-timeline d-flex justify-content-between",
        timeline_items
      )
    })

    # Overview details
    output$overview_details <- renderUI({
      req(product())
      p <- product()

      shiny::tagList(
        shiny::p(shiny::strong("Created:"), format(p$created_at, "%Y-%m-%d %H:%M")),
        shiny::p(shiny::strong("Last Updated:"), format(p$updated_at, "%Y-%m-%d %H:%M")),
        shiny::p(shiny::strong("Current Status:"), p$current_status %||% "N/A"),
        if (!is.null(p$tags) && length(p$tags) > 0) {
          shiny::p(
            shiny::strong("Tags:"),
            shiny::br(),
            purrr::map(p$tags, ~ shiny::span(class = "badge bg-secondary me-1", .x))
          )
        }
      )
    })

    # Approval content
    output$approval_content <- renderUI({
      app <- approval()

      if (is.null(app) || nrow(app) == 0) {
        return(shiny::div(
          class = "alert alert-info",
          "No approval record found for this product."
        ))
      }

      bslib::layout_columns(
        col_widths = c(6, 6),

        bslib::card(
          bslib::card_header("Submission Details"),
          bslib::card_body(
            shiny::p(shiny::strong("Submitted by:"), app$submitted_by),
            shiny::p(shiny::strong("Submitted at:"), format(app$submitted_at, "%Y-%m-%d %H:%M")),
            shiny::p(shiny::strong("Status:"), app$status)
          )
        ),

        bslib::card(
          bslib::card_header("Business Justification"),
          bslib::card_body(
            shiny::p(app$business_justification %||% "Not provided")
          )
        ),

        bslib::card(
          bslib::card_header("Sign-offs"),
          bslib::card_body(
            shiny::div(
              class = "mb-2",
              shiny::strong("Governance:"),
              if (app$governance_signoff) {
                shiny::span(class = "badge bg-success ms-2", "Approved")
              } else {
                shiny::span(class = "badge bg-warning ms-2", "Pending")
              }
            ),
            shiny::div(
              class = "mb-2",
              shiny::strong("Technical:"),
              if (app$technical_signoff) {
                shiny::span(class = "badge bg-success ms-2", "Approved")
              } else {
                shiny::span(class = "badge bg-warning ms-2", "Pending")
              }
            ),
            shiny::div(
              shiny::strong("Security:"),
              if (app$security_signoff) {
                shiny::span(class = "badge bg-success ms-2", "Approved")
              } else {
                shiny::span(class = "badge bg-warning ms-2", "Pending")
              }
            )
          )
        )
      )
    })

    # Audit content (placeholder)
    output$audit_content <- renderUI({
      shiny::div(
        class = "alert alert-info",
        "Audit functionality will be implemented in Phase 2."
      )
    })

    # Deployment content (placeholder)
    output$deployment_content <- renderUI({
      shiny::div(
        class = "alert alert-info",
        "Deployment tracking will be implemented in Phase 3."
      )
    })

    # Reviews content (placeholder)
    output$reviews_content <- renderUI({
      shiny::div(
        class = "alert alert-info",
        "Review management will be implemented in Phase 4."
      )
    })

    # Analytics content (placeholder)
    output$analytics_content <- renderUI({
      shiny::div(
        class = "alert alert-info",
        "Google Analytics integration will be implemented in Phase 4."
      )
    })

    # Back button
    observeEvent(input$btn_back, {
      shiny.router::change_page("/products")
    })

    # Flag for review
    observeEvent(input$btn_flag_review, {
      shiny::showNotification(
        "Product flagged for review. This will be functional in Phase 4.",
        type = "message",
        duration = 3
      )
    })
  })
}
