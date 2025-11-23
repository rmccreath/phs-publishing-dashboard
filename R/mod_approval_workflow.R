#' Approval Workflow Module
#'
#' @description Shiny module for managing dashboard approval workflow
#' @name mod_approval_workflow
NULL

#' Approval Workflow UI
#'
#' @param id Module ID
#' @export
mod_approval_workflow_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    # Breadcrumbs
    approval_breadcrumbs(),

    bslib::navset_card_tab(
      id = ns("workflow_tabs"),
      full_screen = TRUE,

      # Pending Approvals Tab
      bslib::nav_panel(
        title = "Pending Approvals",
        icon = bsicons::bs_icon("clock-history"),

        bslib::layout_column_wrap(
          width = 1/3,

          bslib::value_box(
            title = "Pending Reviews",
            value = shiny::textOutput(ns("count_pending"), inline = TRUE),
            showcase = bsicons::bs_icon("hourglass-split"),
            theme = "warning"
          ),

          bslib::value_box(
            title = "Under Review",
            value = shiny::textOutput(ns("count_under_review"), inline = TRUE),
            showcase = bsicons::bs_icon("search"),
            theme = "info"
          ),

          bslib::value_box(
            title = "Requires Changes",
            value = shiny::textOutput(ns("count_requires_changes"), inline = TRUE),
            showcase = bsicons::bs_icon("exclamation-triangle"),
            theme = "danger"
          )
        ),

        bslib::card(
          bslib::card_header("Approval Queue"),
          bslib::card_body(
            DT::DTOutput(ns("pending_table"))
          )
        )
      ),

      # Submit New Dashboard Tab
      bslib::nav_panel(
        title = "Submit for Approval",
        icon = bsicons::bs_icon("upload"),

        bslib::card(
          bslib::card_header("Submit New Dashboard for Approval"),
          bslib::card_body(
            shiny::div(
              class = "row",

              shiny::div(
                class = "col-md-6",

                shiny::h5("Product Information"),

                shiny::textInput(
                  ns("submit_product_name"),
                  "Product Name *",
                  placeholder = "Enter the name of the new product..."
                ),

                shiny::selectInput(
                  ns("submit_product_type"),
                  "Product Type *",
                  choices = c(
                    "Shiny Dashboard" = "shiny_dashboard",
                    "Quarto Report" = "quarto_report",
                    "Dash Application" = "dash_app",
                    "API Service" = "api_service",
                    "Other" = "other"
                  )
                ),

                shiny::textInput(
                  ns("submit_department"),
                  "Department *",
                  placeholder = "e.g., Digital & Technology"
                ),

                shiny::textInput(
                  ns("submit_team"),
                  "Team *",
                  placeholder = "e.g., Analytics"
                ),

                shiny::textAreaInput(
                  ns("submit_description"),
                  "Description *",
                  placeholder = "Brief description of the product...",
                  rows = 3
                ),

                shiny::textAreaInput(
                  ns("submit_justification"),
                  "Business Justification *",
                  placeholder = "Explain the business need and expected benefits...",
                  rows = 4
                ),

                shiny::textAreaInput(
                  ns("submit_audience"),
                  "Target Audience *",
                  placeholder = "Who will use this dashboard?",
                  rows = 3
                ),

                shiny::textAreaInput(
                  ns("submit_data_sources"),
                  "Data Sources *",
                  placeholder = "List the data sources used...",
                  rows = 3
                )
              ),

              shiny::div(
                class = "col-md-6",

                shiny::h5("Support & Maintenance"),

                shiny::selectInput(
                  ns("submit_update_schedule"),
                  "Update Schedule *",
                  choices = c(
                    "Real-time" = "real_time",
                    "Daily" = "daily",
                    "Weekly" = "weekly",
                    "Monthly" = "monthly",
                    "Quarterly" = "quarterly",
                    "On-demand" = "on_demand"
                  )
                ),

                shiny::textAreaInput(
                  ns("submit_support_plan"),
                  "Support Plan *",
                  placeholder = "How will this dashboard be maintained and supported?",
                  rows = 4
                ),

                shiny::checkboxInput(
                  ns("submit_confirm"),
                  "I confirm that this dashboard meets PHS standards and is ready for review",
                  value = FALSE
                ),

                shiny::hr(),

                shiny::actionButton(
                  ns("btn_submit"),
                  "Submit for Approval",
                  icon = shiny::icon("paper-plane"),
                  class = "btn-primary btn-lg w-100"
                )
              )
            )
          )
        )
      ),

      # Review Dashboard Tab
      bslib::nav_panel(
        title = "Review",
        icon = bsicons::bs_icon("clipboard-check"),

        shiny::conditionalPanel(
          condition = "output.has_selected_approval",
          ns = ns,

          bslib::layout_sidebar(
            sidebar = bslib::sidebar(
              title = "Approval Details",
              width = 350,

              shiny::h6("Dashboard Information"),
              shiny::verbatimTextOutput(ns("review_dashboard_info")),

              shiny::hr(),

              shiny::h6("Submission Details"),
              shiny::verbatimTextOutput(ns("review_submission_info")),

              shiny::hr(),

              shiny::h6("Sign-offs"),
              shiny::uiOutput(ns("review_signoffs"))
            ),

            # Main review area
            bslib::navset_card_tab(
              bslib::nav_panel(
                "Justification",
                shiny::div(
                  class = "p-3",
                  shiny::h5("Business Justification"),
                  shiny::verbatimTextOutput(ns("review_justification")),

                  shiny::h5("Target Audience"),
                  shiny::verbatimTextOutput(ns("review_audience")),

                  shiny::h5("Data Sources"),
                  shiny::verbatimTextOutput(ns("review_data_sources")),

                  shiny::h5("Update Schedule"),
                  shiny::verbatimTextOutput(ns("review_schedule")),

                  shiny::h5("Support Plan"),
                  shiny::verbatimTextOutput(ns("review_support"))
                )
              ),

              bslib::nav_panel(
                "Actions",
                shiny::div(
                  class = "p-3",

                  bslib::card(
                    bslib::card_header("Review Actions"),
                    bslib::card_body(
                      shiny::textAreaInput(
                        ns("review_notes"),
                        "Review Notes",
                        placeholder = "Add comments or feedback...",
                        rows = 4
                      ),

                      shiny::div(
                        class = "d-grid gap-2",

                        shiny::actionButton(
                          ns("btn_approve"),
                          "Approve",
                          icon = shiny::icon("check"),
                          class = "btn-success btn-lg"
                        ),

                        shiny::actionButton(
                          ns("btn_require_changes"),
                          "Require Changes",
                          icon = shiny::icon("edit"),
                          class = "btn-warning btn-lg"
                        ),

                        shiny::actionButton(
                          ns("btn_reject"),
                          "Reject",
                          icon = shiny::icon("times"),
                          class = "btn-danger btn-lg"
                        )
                      )
                    )
                  ),

                  bslib::card(
                    bslib::card_header("Sign-offs"),
                    bslib::card_body(
                      shiny::checkboxInput(
                        ns("signoff_governance"),
                        "Governance Sign-off",
                        value = FALSE
                      ),
                      shiny::checkboxInput(
                        ns("signoff_technical"),
                        "Technical Sign-off",
                        value = FALSE
                      ),
                      shiny::checkboxInput(
                        ns("signoff_security"),
                        "Security Sign-off",
                        value = FALSE
                      ),

                      shiny::actionButton(
                        ns("btn_add_signoff"),
                        "Add Sign-off",
                        icon = shiny::icon("signature"),
                        class = "btn-primary w-100"
                      )
                    )
                  )
                )
              )
            )
          )
        ),

        shiny::conditionalPanel(
          condition = "!output.has_selected_approval",
          ns = ns,
          shiny::div(
            class = "text-center p-5",
            shiny::h4("Select an approval from the Pending Approvals tab to review")
          )
        )
      ),

      # Approval History Tab
      bslib::nav_panel(
        title = "History",
        icon = bsicons::bs_icon("clock-history"),

        bslib::card(
          bslib::card_header("Approval History"),
          bslib::card_body(
            DT::DTOutput(ns("history_table"))
          )
        )
      )
    )
  )
}

#' Approval Workflow Server
#'
#' @param id Module ID
#' @param approval_repo Approval repository instance
#' @param dashboard_repo Dashboard repository instance
#' @param user Reactive user object
#' @export
mod_approval_workflow_server <- function(id, approval_repo, dashboard_repo, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      selected_approval = NULL,
      refresh_trigger = 0
    )

    # Check for tab query parameter and switch to it
    observe({
      query <- shiny.router::get_query_param()
      if (!is.null(query) && "tab" %in% names(query)) {
        tab_name <- query[["tab"]]
        if (tab_name == "submit") {
          shiny::updateTabsetPanel(session, "workflow_tabs", selected = "Submit for Approval")
        }
      }
    })

    # Load pending approvals
    pending_approvals <- reactive({
      rv$refresh_trigger  # Trigger refresh

      filters <- list()

      # Filter based on permissions
      if (!has_permission(user(), "view_all")) {
        if (has_permission(user(), "view_team")) {
          # Get team dashboards
          dashboards <- dashboard_repo$get_all(list(team = user()$team))
          filters$dashboard_id <- dashboards$dashboard_id
        } else {
          filters$submitted_by <- user()$user_id
        }
      }

      approval_repo$get_all(filters) %>%
        dplyr::filter(status %in% c("pending", "under_review", "requires_changes"))
    })

    # Counts for value boxes
    output$count_pending <- renderText({
      req(pending_approvals())
      sum(pending_approvals()$status == "pending")
    })

    output$count_under_review <- renderText({
      req(pending_approvals())
      sum(pending_approvals()$status == "under_review")
    })

    output$count_requires_changes <- renderText({
      req(pending_approvals())
      sum(pending_approvals()$status == "requires_changes")
    })

    # Render pending approvals table
    output$pending_table <- DT::renderDT({
      req(pending_approvals())

      # Store product IDs for click handling
      approvals_data <- pending_approvals()

      data <- approvals_data %>%
        dplyr::mutate(
          # Create clickable links for product names
          Product = paste0(
            '<a href="#" onclick="Shiny.setInputValue(\'',
            ns("product_link_clicked"),
            '\', \'',
            dashboard_id,
            '\', {priority: \'event\'}); return false;">',
            dashboard_name,
            '</a>'
          )
        ) %>%
        dplyr::select(
          Product,
          `Submitted By` = submitted_by_name,
          `Submitted At` = submitted_at,
          Status = status,
          `Governance` = governance_signoff,
          `Technical` = technical_signoff,
          `Security` = security_signoff
        )

      DT::datatable(
        data,
        options = list(
          pageLength = 10,
          searchHighlight = TRUE
        ),
        selection = 'single',
        class = "display compact stripe hover",
        rownames = FALSE,
        escape = FALSE  # Allow HTML in Product column
      )
    })

    # Handle product link clicks
    observeEvent(input$product_link_clicked, {
      req(input$product_link_clicked)
      product_id <- input$product_link_clicked
      shiny.router::change_page(paste0("/product?id=", product_id))
    })

    # Handle row selection
    observeEvent(input$pending_table_rows_selected, {
      req(input$pending_table_rows_selected)

      selected_row <- pending_approvals()[input$pending_table_rows_selected, ]
      rv$selected_approval <- selected_row

      # Switch to review tab
      updateTabsetPanel(session, "workflow_tabs", selected = "Review")
    })

    # Check if approval is selected
    output$has_selected_approval <- reactive({
      !is.null(rv$selected_approval)
    })
    outputOptions(output, "has_selected_approval", suspendWhenHidden = FALSE)

    # Render review information
    output$review_dashboard_info <- renderPrint({
      req(rv$selected_approval)
      cat("Dashboard:", rv$selected_approval$dashboard_name, "\n")
      cat("Platform:", rv$selected_approval$platform, "\n")
    })

    output$review_submission_info <- renderPrint({
      req(rv$selected_approval)
      cat("Submitted by:", rv$selected_approval$submitted_by_name, "\n")
      cat("Submitted at:", format(rv$selected_approval$submitted_at), "\n")
      cat("Status:", rv$selected_approval$status, "\n")
    })

    output$review_justification <- renderText({
      req(rv$selected_approval)
      rv$selected_approval$business_justification
    })

    output$review_audience <- renderText({
      req(rv$selected_approval)
      rv$selected_approval$target_audience
    })

    output$review_data_sources <- renderText({
      req(rv$selected_approval)
      rv$selected_approval$data_sources
    })

    output$review_schedule <- renderText({
      req(rv$selected_approval)
      rv$selected_approval$update_schedule
    })

    output$review_support <- renderText({
      req(rv$selected_approval)
      rv$selected_approval$support_plan
    })

    output$review_signoffs <- renderUI({
      req(rv$selected_approval)

      shiny::tagList(
        shiny::div(
          class = "mb-2",
          shiny::tags$span(
            class = if (rv$selected_approval$governance_signoff) "badge bg-success" else "badge bg-secondary",
            "Governance"
          )
        ),
        shiny::div(
          class = "mb-2",
          shiny::tags$span(
            class = if (rv$selected_approval$technical_signoff) "badge bg-success" else "badge bg-secondary",
            "Technical"
          )
        ),
        shiny::div(
          class = "mb-2",
          shiny::tags$span(
            class = if (rv$selected_approval$security_signoff) "badge bg-success" else "badge bg-secondary",
            "Security"
          )
        )
      )
    })

    # Submit new approval
    observeEvent(input$btn_submit, {
      # Validate required fields
      errors <- c()

      if (is.null(input$submit_product_name) || nchar(trimws(input$submit_product_name)) == 0) {
        errors <- c(errors, "Product Name is required")
      }
      if (is.null(input$submit_department) || nchar(trimws(input$submit_department)) == 0) {
        errors <- c(errors, "Department is required")
      }
      if (is.null(input$submit_team) || nchar(trimws(input$submit_team)) == 0) {
        errors <- c(errors, "Team is required")
      }
      if (is.null(input$submit_description) || nchar(trimws(input$submit_description)) == 0) {
        errors <- c(errors, "Description is required")
      }
      if (is.null(input$submit_justification) || nchar(trimws(input$submit_justification)) == 0) {
        errors <- c(errors, "Business Justification is required")
      }
      if (is.null(input$submit_audience) || nchar(trimws(input$submit_audience)) == 0) {
        errors <- c(errors, "Target Audience is required")
      }
      if (is.null(input$submit_data_sources) || nchar(trimws(input$submit_data_sources)) == 0) {
        errors <- c(errors, "Data Sources is required")
      }
      if (is.null(input$submit_support_plan) || nchar(trimws(input$submit_support_plan)) == 0) {
        errors <- c(errors, "Support Plan is required")
      }
      if (!input$submit_confirm) {
        errors <- c(errors, "You must confirm that the product meets PHS standards")
      }

      # Show validation errors
      if (length(errors) > 0) {
        shiny::showNotification(
          HTML(paste0(
            "<strong>Please fix the following errors:</strong><br/>",
            paste("•", errors, collapse = "<br/>")
          )),
          type = "error",
          duration = 8
        )
        return()
      }

      tryCatch({
        # Create new product record (approved but not yet in development)
        product_data <- list(
          name = input$submit_product_name,
          type = input$submit_product_type,
          department = input$submit_department,
          team = input$submit_team,
          description = input$submit_description,
          lifecycle_stage = "approved",
          current_status = "awaiting_development",
          created_by = user()$username,
          owner_id = user()$user_id,
          owner_name = user()$full_name,
          owner_email = user()$email
        )

        product_id <- dashboard_repo$create(product_data)

        # Create approval record linked to the new product
        approval_data <- list(
          dashboard_id = product_id,
          dashboard_name = input$submit_product_name,
          submitted_by = user()$user_id,
          submitted_by_name = user()$full_name,
          business_justification = input$submit_justification,
          target_audience = input$submit_audience,
          data_sources = input$submit_data_sources,
          update_schedule = input$submit_update_schedule,
          support_plan = input$submit_support_plan,
          status = "approved"
        )

        approval_repo$create(approval_data)

        shiny::showNotification(
          HTML(paste0(
            "<strong>Success!</strong><br/>",
            "Product '", input$submit_product_name, "' has been created and is awaiting development."
          )),
          type = "message",
          duration = 5
        )

        # Reset form
        updateTextInput(session, "submit_product_name", value = "")
        updateTextInput(session, "submit_department", value = "")
        updateTextInput(session, "submit_team", value = "")
        updateTextAreaInput(session, "submit_description", value = "")
        updateTextAreaInput(session, "submit_justification", value = "")
        updateTextAreaInput(session, "submit_audience", value = "")
        updateTextAreaInput(session, "submit_data_sources", value = "")
        updateTextAreaInput(session, "submit_support_plan", value = "")
        updateCheckboxInput(session, "submit_confirm", value = FALSE)

        # Navigate to the newly created product detail page
        rv$refresh_trigger <- rv$refresh_trigger + 1
        shiny.router::change_page(paste0("/product?id=", product_id))
      }, error = function(e) {
        shiny::showNotification(
          HTML(paste0(
            "<strong>Error submitting approval:</strong><br/>",
            e$message
          )),
          type = "error",
          duration = 8
        )
      })
    })

    # Approve
    observeEvent(input$btn_approve, {
      req(rv$selected_approval)
      req(has_permission(user(), "approve"))

      approval_repo$update_status(
        rv$selected_approval$approval_id,
        "approved",
        user()$user_id,
        input$review_notes
      )

      # Update dashboard status
      dashboard_repo$update(
        rv$selected_approval$dashboard_id,
        list(status = "approved")
      )

      shiny::showNotification("Approval granted", type = "message")

      rv$selected_approval <- NULL
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })

    # Require changes
    observeEvent(input$btn_require_changes, {
      req(rv$selected_approval)
      req(has_permission(user(), "approve"))

      approval_repo$update_status(
        rv$selected_approval$approval_id,
        "requires_changes",
        user()$user_id,
        input$review_notes
      )

      shiny::showNotification("Changes requested", type = "warning")

      rv$selected_approval <- NULL
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })

    # Reject
    observeEvent(input$btn_reject, {
      req(rv$selected_approval)
      req(has_permission(user(), "approve"))

      approval_repo$update_status(
        rv$selected_approval$approval_id,
        "rejected",
        user()$user_id,
        input$review_notes
      )

      # Update dashboard status
      dashboard_repo$update(
        rv$selected_approval$dashboard_id,
        list(status = "draft")
      )

      shiny::showNotification("Approval rejected", type = "error")

      rv$selected_approval <- NULL
      rv$refresh_trigger <- rv$refresh_trigger + 1
    })

    # Add sign-off
    observeEvent(input$btn_add_signoff, {
      req(rv$selected_approval)
      req(has_permission(user(), "approve"))

      tryCatch({
        if (input$signoff_governance) {
          approval_repo$add_signoff(
            rv$selected_approval$approval_id,
            "governance",
            user()$user_id
          )
        }

        if (input$signoff_technical) {
          approval_repo$add_signoff(
            rv$selected_approval$approval_id,
            "technical",
            user()$user_id
          )
        }

        if (input$signoff_security) {
          approval_repo$add_signoff(
            rv$selected_approval$approval_id,
            "security",
            user()$user_id
          )
        }

        shiny::showNotification("Sign-off(s) added", type = "message")

        rv$refresh_trigger <- rv$refresh_trigger + 1
      }, error = function(e) {
        shiny::showNotification(
          paste("Error adding sign-off:", e$message),
          type = "error"
        )
      })
    })

    # Load approval history
    approval_history <- reactive({
      rv$refresh_trigger

      approval_repo$get_all() %>%
        dplyr::filter(status %in% c("approved", "rejected"))
    })

    # Render history table
    output$history_table <- DT::renderDT({
      req(approval_history())

      data <- approval_history() %>%
        dplyr::select(
          Dashboard = dashboard_name,
          `Submitted By` = submitted_by_name,
          `Submitted At` = submitted_at,
          Status = status,
          `Reviewed By` = reviewed_by,
          `Reviewed At` = reviewed_at
        )

      DT::datatable(
        data,
        options = list(
          pageLength = 25,
          searchHighlight = TRUE,
          order = list(list(5, 'desc'))  # Sort by reviewed_at desc
        ),
        class = "display compact stripe hover",
        rownames = FALSE
      )
    })
  })
}
