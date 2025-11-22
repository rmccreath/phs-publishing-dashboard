#' Dashboard Registry Module
#'
#' @description Shiny module for managing dashboard registry
#' @name mod_dashboard_registry
NULL

#' Dashboard Registry UI
#'
#' @param id Module ID
#' @export
mod_dashboard_registry_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        title = "Filters",
        width = 250,

        shiny::selectInput(
          ns("filter_status"),
          "Status",
          choices = c(
            "All" = "",
            "Draft" = "draft",
            "Pending Approval" = "pending_approval",
            "Approved" = "approved",
            "Published" = "published",
            "Deprecated" = "deprecated"
          ),
          selected = ""
        ),

        shiny::selectInput(
          ns("filter_platform"),
          "Platform",
          choices = c(
            "All" = "",
            "Posit Connect" = "posit_connect",
            "ShinyApps.io" = "shinyapps_io",
            "Other" = "other"
          ),
          selected = ""
        ),

        shiny::textInput(
          ns("filter_team"),
          "Team",
          placeholder = "Filter by team..."
        ),

        shiny::hr(),

        shiny::actionButton(
          ns("btn_sync"),
          "Sync from APIs",
          icon = shiny::icon("refresh"),
          class = "btn-primary w-100 mb-2"
        ),

        shiny::actionButton(
          ns("btn_add"),
          "Add Dashboard",
          icon = shiny::icon("plus"),
          class = "btn-success w-100"
        )
      ),

      # Main content
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          shiny::div(
            shiny::h4("Dashboard Registry", class = "mb-0"),
            shiny::tags$small(
              class = "text-muted",
              shiny::textOutput(ns("registry_count"), inline = TRUE)
            )
          ),
          shiny::div(
            shiny::downloadButton(ns("btn_download"), "Export", class = "btn-sm")
          )
        ),
        bslib::card_body(
          waiter::useWaiter(),
          DT::DTOutput(ns("dashboard_table"))
        )
      )
    )
  )
}

#' Dashboard Registry Server
#'
#' @param id Module ID
#' @param dashboard_repo Dashboard repository instance
#' @param connect_service Posit Connect service instance
#' @param shinyapps_service ShinyApps.io service instance
#' @param user Reactive user object
#' @export
mod_dashboard_registry_server <- function(id, dashboard_repo, connect_service,
                                          shinyapps_service, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      last_sync = NULL,
      dashboards = NULL
    )

    # Load dashboards
    dashboards <- reactive({
      # Trigger on sync button, filter changes, or manual refresh
      input$btn_sync
      input$filter_status
      input$filter_platform
      input$filter_team
      rv$last_sync  # Trigger refresh when this changes

      filters <- list()

      if (!is.null(input$filter_status) && input$filter_status != "") {
        filters$status <- input$filter_status
      }

      if (!is.null(input$filter_platform) && input$filter_platform != "") {
        filters$platform <- input$filter_platform
      }

      if (!is.null(input$filter_team) && input$filter_team != "") {
        filters$team <- input$filter_team
      }

      # Get dashboards from database
      data <- dashboard_repo$get_all(filters)

      # Filter based on user permissions
      filter_by_access(data, user(), "owner_id", "team")
    })

    # Render dashboard count
    output$registry_count <- renderText({
      req(dashboards())
      paste(nrow(dashboards()), "dashboards")
    })

    # Render dashboard table
    output$dashboard_table <- DT::renderDT({
      req(dashboards())

      data <- dashboards() %>%
        dplyr::select(
          Name = name,
          Platform = platform,
          Status = status,
          Team = team,
          Owner = owner_name,
          `Compliance Score` = overall_score,
          Grade = grade,
          `Last Updated` = last_updated
        )

      DT::datatable(
        data,
        options = list(
          pageLength = 25,
          searchHighlight = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          columnDefs = list(
            list(
              targets = 6,  # Grade column
              render = JS("
                function(data, type, row) {
                  if (type === 'display') {
                    var color = 'secondary';
                    if (data === 'excellent') color = 'success';
                    else if (data === 'good') color = 'primary';
                    else if (data === 'acceptable') color = 'warning';
                    else if (data === 'poor') color = 'danger';
                    return '<span class=\"badge bg-' + color + '\">' + data + '</span>';
                  }
                  return data;
                }
              ")
            )
          )
        ),
        selection = 'single',
        class = "display compact stripe hover",
        rownames = FALSE,
        escape = FALSE
      )
    })

    # Sync from APIs
    observeEvent(input$btn_sync, {
      req(has_permission(user(), "edit_all") || has_permission(user(), "submit"))

      waiter::waiter_show(
        html = waiter::spin_fading_circles(),
        color = waiter::transparent(0.5)
      )

      tryCatch({
        # Sync from Posit Connect
        if (!is.null(connect_service)) {
          connect_content <- connect_service$get_content(use_cache = FALSE)
          if (!is.null(connect_content) && length(connect_content) > 0) {
            connect_dashboards <- connect_service$transform_to_dashboards(connect_content)

            # Upsert to database
            purrr::walk(seq_len(nrow(connect_dashboards)), function(i) {
              dashboard_repo$create(as.list(connect_dashboards[i, ]))
            })
          }
        }

        # Sync from ShinyApps.io
        if (!is.null(shinyapps_service)) {
          shinyapps_content <- shinyapps_service$get_applications(use_cache = FALSE)
          if (!is.null(shinyapps_content) && length(shinyapps_content) > 0) {
            shinyapps_dashboards <- shinyapps_service$transform_to_dashboards(shinyapps_content)

            # Upsert to database
            purrr::walk(seq_len(nrow(shinyapps_dashboards)), function(i) {
              dashboard_repo$create(as.list(shinyapps_dashboards[i, ]))
            })
          }
        }

        rv$last_sync <- Sys.time()

        shiny::showNotification(
          "Dashboard registry synchronized successfully",
          type = "message",
          duration = 3
        )
      }, error = function(e) {
        shiny::showNotification(
          paste("Sync error:", e$message),
          type = "error",
          duration = 5
        )
      }, finally = {
        waiter::waiter_hide()
      })
    })

    # Add new dashboard
    observeEvent(input$btn_add, {
      req(has_permission(user(), "submit") || has_permission(user(), "edit_all"))

      shiny::showModal(
        shiny::modalDialog(
          title = "Add New Dashboard",
          size = "l",

          shiny::textInput(ns("new_name"), "Dashboard Name *", ""),
          shiny::textAreaInput(ns("new_description"), "Description", "", rows = 3),
          shiny::textInput(ns("new_url"), "URL *", ""),

          shiny::selectInput(
            ns("new_platform"),
            "Platform *",
            choices = c("Posit Connect" = "posit_connect",
                       "ShinyApps.io" = "shinyapps_io",
                       "Other" = "other")
          ),

          shiny::textInput(ns("new_repo_url"), "Repository URL", ""),
          shiny::textInput(ns("new_doc_url"), "Documentation URL", ""),

          footer = shiny::tagList(
            shiny::modalButton("Cancel"),
            shiny::actionButton(ns("btn_save_dashboard"), "Save", class = "btn-primary")
          )
        )
      )
    })

    # Save new dashboard
    observeEvent(input$btn_save_dashboard, {
      req(input$new_name, input$new_url, input$new_platform)

      tryCatch({
        dashboard_data <- list(
          name = input$new_name,
          description = input$new_description,
          url = input$new_url,
          platform = input$new_platform,
          repository_url = input$new_repo_url,
          documentation_url = input$new_doc_url,
          owner_id = user()$user_id,
          team = user()$team,
          department = user()$department,
          status = "draft",
          visibility = "internal"
        )

        dashboard_repo$create(dashboard_data)

        shiny::showNotification(
          "Dashboard added successfully",
          type = "message",
          duration = 3
        )

        shiny::removeModal()

        # Trigger refresh
        rv$last_sync <- Sys.time()
      }, error = function(e) {
        shiny::showNotification(
          paste("Error saving dashboard:", e$message),
          type = "error",
          duration = 5
        )
      })
    })

    # Download handler
    output$btn_download <- downloadHandler(
      filename = function() {
        paste0("dashboard_registry_", Sys.Date(), ".csv")
      },
      content = function(file) {
        readr::write_csv(dashboards(), file)
      }
    )

    # Return reactive dashboards for other modules
    return(dashboards)
  })
}
