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

    # Reactive values for refresh triggers
    rv <- reactiveValues(
      refresh_trigger = 0
    )

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
      rv$refresh_trigger  # Trigger refresh
      req(product_id())
      result <- product_repo$get_by_id(product_id())

      # Validate result
      if (is.null(result) || nrow(result) == 0) {
        return(NULL)
      }

      result
    })

    # Load approval data
    approval <- reactive({
      rv$refresh_trigger  # Trigger refresh
      req(product_id())
      if (is.null(approval_repo)) {
        return(NULL)
      }
      result <- approval_repo$get_by_product_id(product_id())

      # Can be NULL or empty, that's okay
      result
    })

    # Breadcrumbs
    output$breadcrumbs <- renderUI({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)

      prod_name <- as.character(prod$name[1])
      product_breadcrumbs(prod_name)
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
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)
      as.character(prod$name[1] %||% "Unknown Product")
    })

    output$product_description <- renderText({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)
      as.character(prod$description[1] %||% "No description available")
    })

    output$product_type <- renderText({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)

      type_labels <- c(
        shiny_dashboard = "Shiny Dashboard",
        quarto_report = "Quarto Report",
        dash_app = "Dash Application",
        api_service = "API Service"
      )
      prod_type <- prod$type[1]
      result <- if (!is.null(prod_type) && length(prod_type) > 0 && prod_type %in% names(type_labels)) {
        type_labels[[prod_type]]
      } else if (!is.null(prod_type) && length(prod_type) > 0) {
        tools::toTitleCase(as.character(prod_type))
      } else {
        "Not specified"
      }
      as.character(result)
    })

    output$product_department <- renderText({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)
      as.character(prod$department[1] %||% "Not specified")
    })

    output$product_team <- renderText({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)
      as.character(prod$team[1] %||% "Not specified")
    })

    output$product_stage_badge <- renderUI({
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)
      stage <- prod$lifecycle_stage[1]

      color <- switch(stage,
        awaiting_approval = "warning",
        in_development = "info",
        in_audit = "primary",
        deployed = "success",
        archived = "secondary",
        "secondary"
      )

      label <- switch(stage,
        awaiting_approval = "Awaiting Approval",
        in_development = "In Development",
        in_audit = "In Audit",
        deployed = "Deployed",
        archived = "Archived",
        tools::toTitleCase(gsub("_", " ", stage))
      )

      shiny::span(
        class = paste0("badge bg-", color),
        label
      )
    })

    # Timeline visualization
    output$timeline <- renderUI({
      p <- product()
      req(p)
      req(nrow(p) > 0)

      # Get approval status
      appr <- approval()
      approval_complete <- FALSE
      if (!is.null(appr) && nrow(appr) > 0 && !is.null(appr$status)) {
        approval_complete <- appr$status[1] == "approved"
      }

      # Create timeline based on lifecycle stage
      stages <- list(
        list(name = "Approval", icon = "clipboard-check", status = "pending"),
        list(name = "Development", icon = "code", status = "pending"),
        list(name = "Audit", icon = "search", status = "pending"),
        list(name = "Deployment", icon = "cloud-upload", status = "pending"),
        list(name = "Reviews", icon = "clock-history", status = "pending")
      )

      # Update status based on current stage and approval status
      current_stage <- p$lifecycle_stage[1]

      # IMPORTANT: Development cannot start until approval is complete
      if (current_stage == "awaiting_approval") {
        # Awaiting approval stage - approval process in progress
        if (approval_complete) {
          stages[[1]]$status <- "completed"  # Approval done
          stages[[2]]$status <- "active"     # Development can start
        } else {
          stages[[1]]$status <- "active"     # Approval in progress
          stages[[2]]$status <- "blocked"    # Development blocked until approval
        }
      } else if (current_stage == "in_development") {
        stages[[1]]$status <- "completed"
        stages[[2]]$status <- "active"
      } else if (current_stage == "in_audit") {
        stages[[1]]$status <- "completed"
        stages[[2]]$status <- "completed"
        stages[[3]]$status <- "active"
      } else if (current_stage == "deployed") {
        stages[[1]]$status <- "completed"
        stages[[2]]$status <- "completed"
        stages[[3]]$status <- "completed"
        stages[[4]]$status <- "completed"
        stages[[5]]$status <- "active"  # Ongoing reviews
      } else if (current_stage == "archived") {
        # All complete but archived
        for (i in 1:4) {
          stages[[i]]$status <- "completed"
        }
        stages[[5]]$status <- "completed"
      }

      # Create timeline HTML
      timeline_items <- purrr::map(stages, function(stage) {
        status_class <- switch(stage$status,
          completed = "text-success",
          active = "text-primary",
          on_hold = "text-warning",
          blocked = "text-secondary",
          "text-muted"
        )

        icon_html <- if (stage$status == "completed") {
          "<i class='bi bi-check-circle-fill'></i>"
        } else if (stage$status == "active") {
          "<i class='bi bi-arrow-right-circle-fill'></i>"
        } else if (stage$status == "on_hold") {
          "<i class='bi bi-hourglass-split'></i>"
        } else if (stage$status == "blocked") {
          "<i class='bi bi-slash-circle'></i>"
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
      p <- product()
      req(p)
      req(nrow(p) > 0)

      shiny::tagList(
        shiny::p(shiny::strong("Created:"), as.character(format(p$created_at[1], "%Y-%m-%d %H:%M"))),
        shiny::p(shiny::strong("Last Updated:"), as.character(format(p$updated_at[1], "%Y-%m-%d %H:%M"))),
        shiny::p(shiny::strong("Current Status:"), as.character(p$current_status[1] %||% "N/A")),
        if (!is.null(p$tags[[1]]) && length(p$tags[[1]]) > 0) {
          shiny::p(
            shiny::strong("Tags:"),
            shiny::br(),
            purrr::map(p$tags[[1]], ~ shiny::span(class = "badge bg-secondary me-1", .x))
          )
        }
      )
    })

    # Approval content
    output$approval_content <- renderUI({
      app <- approval()
      prod <- product()

      if (is.null(app) || nrow(app) == 0) {
        return(shiny::div(
          class = "alert alert-info",
          "No approval record found for this product."
        ))
      }

      # Check if user can approve
      req(nrow(prod) > 0)
      can_approve <- has_permission(user(), "approve")
      approval_complete <- !is.null(app$status[1]) && app$status[1] == "approved"

      shiny::tagList(
        # Overall status banner
        if (approval_complete) {
          shiny::div(
            class = "alert alert-success",
            shiny::icon("check-circle"),
            " This product has been fully approved and is ready for development."
          )
        } else {
          shiny::div(
            class = "alert alert-warning",
            shiny::icon("hourglass-split"),
            " Approval in progress. All sections must be approved before development can begin."
          )
        },

        # Submission Information
        bslib::card(
          bslib::card_header("Submission Information"),
          bslib::card_body(
            bslib::layout_columns(
              col_widths = c(6, 6),
              shiny::div(
                shiny::p(shiny::strong("Submitted by:"), as.character(app$submitted_by_name[1] %||% "Unknown")),
                shiny::p(shiny::strong("Submitted at:"), as.character(format(app$submitted_at[1], "%Y-%m-%d %H:%M")))
              ),
              shiny::div(
                shiny::p(shiny::strong("Product Type:"), as.character(prod$type[1] %||% "Unknown")),
                shiny::p(shiny::strong("Department:"), as.character(prod$department[1] %||% "Unknown")),
                shiny::p(shiny::strong("Team:"), as.character(prod$team[1] %||% "Unknown"))
              )
            ),
            shiny::hr(),
            shiny::h6("Business Justification"),
            shiny::p(as.character(app$business_justification[1] %||% "Not provided")),
            shiny::h6("Target Audience"),
            shiny::p(as.character(app$target_audience[1] %||% "Not provided")),
            shiny::h6("Data Sources"),
            shiny::p(as.character(app$data_sources[1] %||% "Not provided"))
          )
        ),

        # Approval Sections (Guided Process)
        bslib::card(
          bslib::card_header("Approval Checklist"),
          bslib::card_body(
            # Governance Sign-off
            shiny::div(
              class = "approval-section mb-4",
              shiny::div(
                class = "d-flex justify-content-between align-items-center mb-2",
                shiny::h6("1. Governance Review", class = "mb-0"),
                if (!is.null(app$governance_signoff[1]) && app$governance_signoff[1]) {
                  shiny::span(class = "badge bg-success", shiny::icon("check"), " Approved")
                } else {
                  shiny::span(class = "badge bg-warning", shiny::icon("clock"), " Pending")
                }
              ),
              shiny::p(
                class = "text-muted small",
                "Reviews business case, strategic alignment, and governance compliance"
              ),
              if (can_approve && (is.null(app$governance_signoff[1]) || !app$governance_signoff[1])) {
                shiny::actionButton(
                  ns("btn_approve_governance"),
                  "Approve Governance",
                  class = "btn-success btn-sm",
                  icon = shiny::icon("check")
                )
              } else if (!is.null(app$governance_signoff[1]) && app$governance_signoff[1]) {
                shiny::div(
                  class = "small text-success",
                  "Approved by: ", as.character(app$governance_signoff_by[1] %||% "System")
                )
              }
            ),

            # Technical Sign-off
            shiny::div(
              class = "approval-section mb-4",
              shiny::div(
                class = "d-flex justify-content-between align-items-center mb-2",
                shiny::h6("2. Technical Review", class = "mb-0"),
                if (!is.null(app$technical_signoff[1]) && app$technical_signoff[1]) {
                  shiny::span(class = "badge bg-success", shiny::icon("check"), " Approved")
                } else {
                  shiny::span(class = "badge bg-warning", shiny::icon("clock"), " Pending")
                }
              ),
              shiny::p(
                class = "text-muted small",
                "Reviews technical feasibility, architecture, and resource requirements"
              ),
              if (can_approve && (is.null(app$technical_signoff[1]) || !app$technical_signoff[1])) {
                shiny::actionButton(
                  ns("btn_approve_technical"),
                  "Approve Technical",
                  class = "btn-success btn-sm",
                  icon = shiny::icon("check")
                )
              } else if (!is.null(app$technical_signoff[1]) && app$technical_signoff[1]) {
                shiny::div(
                  class = "small text-success",
                  "Approved by: ", as.character(app$technical_signoff_by[1] %||% "System")
                )
              }
            ),

            # Security Sign-off
            shiny::div(
              class = "approval-section mb-4",
              shiny::div(
                class = "d-flex justify-content-between align-items-center mb-2",
                shiny::h6("3. Security Review", class = "mb-0"),
                if (!is.null(app$security_signoff[1]) && app$security_signoff[1]) {
                  shiny::span(class = "badge bg-success", shiny::icon("check"), " Approved")
                } else {
                  shiny::span(class = "badge bg-warning", shiny::icon("clock"), " Pending")
                }
              ),
              shiny::p(
                class = "text-muted small",
                "Reviews data security, access controls, and compliance requirements"
              ),
              if (can_approve && (is.null(app$security_signoff[1]) || !app$security_signoff[1])) {
                shiny::actionButton(
                  ns("btn_approve_security"),
                  "Approve Security",
                  class = "btn-success btn-sm",
                  icon = shiny::icon("check")
                )
              } else if (!is.null(app$security_signoff[1]) && app$security_signoff[1]) {
                shiny::div(
                  class = "small text-success",
                  "Approved by: ", as.character(app$security_signoff_by[1] %||% "System")
                )
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

    # Edit button - show edit modal
    observeEvent(input$btn_edit, {
      prod <- product()
      req(prod)
      req(nrow(prod) > 0)

      # Show modal with current product data
      shiny::showModal(
        shiny::modalDialog(
          title = "Edit Product",
          size = "l",

          shiny::textInput(
            ns("edit_name"),
            "Product Name",
            value = as.character(prod$name[1])
          ),

          shiny::textAreaInput(
            ns("edit_description"),
            "Description",
            value = as.character(prod$description[1]),
            rows = 3
          ),

          shiny::selectInput(
            ns("edit_type"),
            "Product Type",
            choices = c(
              "Shiny Dashboard" = "shiny_dashboard",
              "Quarto Report" = "quarto_report",
              "Dash Application" = "dash_app",
              "API Service" = "api_service"
            ),
            selected = as.character(prod$type[1])
          ),

          shiny::textInput(
            ns("edit_department"),
            "Department",
            value = as.character(prod$department[1])
          ),

          shiny::textInput(
            ns("edit_team"),
            "Team",
            value = as.character(prod$team[1])
          ),

          footer = shiny::tagList(
            shiny::modalButton("Cancel"),
            shiny::actionButton(
              ns("btn_save_edit"),
              "Save Changes",
              class = "btn-primary"
            )
          )
        )
      )
    })

    # Save edited product
    observeEvent(input$btn_save_edit, {
      req(product_id())

      # Validate inputs
      if (is.null(input$edit_name) || nchar(trimws(input$edit_name)) == 0) {
        shiny::showNotification(
          "Product name is required",
          type = "error",
          duration = 3
        )
        return()
      }

      # Update the product
      updates <- list(
        name = trimws(input$edit_name),
        description = trimws(input$edit_description),
        type = input$edit_type,
        department = trimws(input$edit_department),
        team = trimws(input$edit_team)
      )

      result <- product_repo$update(product_id(), updates)

      if (!is.null(result) && result > 0) {
        shiny::showNotification(
          "Product updated successfully",
          type = "message",
          duration = 3
        )

        # Refresh the product data
        rv$refresh_trigger <- rv$refresh_trigger + 1

        # Close the modal
        shiny::removeModal()
      } else {
        shiny::showNotification(
          "Error updating product",
          type = "error",
          duration = 3
        )
      }
    })

    # Governance approval button
    observeEvent(input$btn_approve_governance, {
      req(product_id())
      req(has_permission(user(), "approve"))

      # Update the sign-off in the approval repository
      all_complete <- approval_repo$update_signoff_by_product(
        product_id(),
        "governance",
        user()$full_name
      )

      if (all_complete) {
        # All sign-offs complete - move product to in_development
        product_repo$update_lifecycle_stage(
          product_id(),
          "in_development",
          "in_progress"
        )

        shiny::showNotification(
          HTML("<strong>All approvals complete!</strong><br/>Product has been moved to 'In Development' stage."),
          type = "message",
          duration = 5
        )
      } else {
        shiny::showNotification(
          "Governance approval recorded successfully.",
          type = "message",
          duration = 3
        )
      }

      # Refresh the page data
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })

    # Technical approval button
    observeEvent(input$btn_approve_technical, {
      req(product_id())
      req(has_permission(user(), "approve"))

      # Update the sign-off in the approval repository
      all_complete <- approval_repo$update_signoff_by_product(
        product_id(),
        "technical",
        user()$full_name
      )

      if (all_complete) {
        # All sign-offs complete - move product to in_development
        product_repo$update_lifecycle_stage(
          product_id(),
          "in_development",
          "in_progress"
        )

        shiny::showNotification(
          HTML("<strong>All approvals complete!</strong><br/>Product has been moved to 'In Development' stage."),
          type = "message",
          duration = 5
        )
      } else {
        shiny::showNotification(
          "Technical approval recorded successfully.",
          type = "message",
          duration = 3
        )
      }

      # Refresh the page data
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })

    # Security approval button
    observeEvent(input$btn_approve_security, {
      req(product_id())
      req(has_permission(user(), "approve"))

      # Update the sign-off in the approval repository
      all_complete <- approval_repo$update_signoff_by_product(
        product_id(),
        "security",
        user()$full_name
      )

      if (all_complete) {
        # All sign-offs complete - move product to in_development
        product_repo$update_lifecycle_stage(
          product_id(),
          "in_development",
          "in_progress"
        )

        shiny::showNotification(
          HTML("<strong>All approvals complete!</strong><br/>Product has been moved to 'In Development' stage."),
          type = "message",
          duration = 5
        )
      } else {
        shiny::showNotification(
          "Security approval recorded successfully.",
          type = "message",
          duration = 3
        )
      }

      # Refresh the page data
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })
  })
}
