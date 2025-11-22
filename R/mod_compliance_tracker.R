#' Compliance Tracker Module
#'
#' @description Shiny module for tracking and visualizing compliance
#' @name mod_compliance_tracker
NULL

#' Compliance Tracker UI
#'
#' @param id Module ID
#' @export
mod_compliance_tracker_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    # Summary cards
    bslib::layout_column_wrap(
      width = 1/4,

      bslib::value_box(
        title = "Overall Compliance",
        value = shiny::textOutput(ns("overall_compliance"), inline = TRUE),
        showcase = bsicons::bs_icon("shield-check"),
        theme = "success"
      ),

      bslib::value_box(
        title = "Excellent",
        value = shiny::textOutput(ns("count_excellent"), inline = TRUE),
        showcase = bsicons::bs_icon("star-fill"),
        theme = "success"
      ),

      bslib::value_box(
        title = "Good",
        value = shiny::textOutput(ns("count_good"), inline = TRUE),
        showcase = bsicons::bs_icon("star"),
        theme = "primary"
      ),

      bslib::value_box(
        title = "Needs Improvement",
        value = shiny::textOutput(ns("count_poor"), inline = TRUE),
        showcase = bsicons::bs_icon("exclamation-triangle"),
        theme = "warning"
      )
    ),

    # Main content
    bslib::layout_columns(
      col_widths = c(8, 4),

      # Left column - detailed view
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          shiny::div(
            shiny::h4("Compliance Details", class = "mb-0")
          ),
          shiny::div(
            shiny::actionButton(
              ns("btn_run_check"),
              "Run Compliance Check",
              icon = shiny::icon("play"),
              class = "btn-primary btn-sm"
            )
          )
        ),
        bslib::card_body(
          DT::DTOutput(ns("compliance_table"))
        )
      ),

      # Right column - visualizations
      bslib::navset_card_tab(
        bslib::nav_panel(
          "Score Distribution",
          echarts4r::echarts4rOutput(ns("score_distribution"))
        ),

        bslib::nav_panel(
          "By Metric",
          echarts4r::echarts4rOutput(ns("metric_breakdown"))
        ),

        bslib::nav_panel(
          "Trends",
          echarts4r::echarts4rOutput(ns("compliance_trends"))
        )
      )
    ),

    # Detail modal placeholder
    shiny::uiOutput(ns("detail_modal"))
  )
}

#' Compliance Tracker Server
#'
#' @param id Module ID
#' @param compliance_repo Compliance repository instance
#' @param dashboard_repo Dashboard repository instance
#' @param compliance_service Compliance service instance
#' @param user Reactive user object
#' @export
mod_compliance_tracker_server <- function(id, compliance_repo, dashboard_repo,
                                          compliance_service, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      refresh_trigger = 0
    )

    # Load compliance data
    compliance_data <- reactive({
      rv$refresh_trigger

      # Get all dashboards with latest compliance
      dashboards <- dashboard_repo$get_all()

      # Filter by user access
      dashboards <- filter_by_access(dashboards, user(), "owner_id", "team")

      dashboards
    })

    # Summary metrics
    output$overall_compliance <- renderText({
      req(compliance_data())

      compliant <- sum(!is.na(compliance_data()$compliant) &
                      compliance_data()$compliant, na.rm = TRUE)
      total <- nrow(compliance_data())

      if (total == 0) return("N/A")

      paste0(round(compliant / total * 100, 1), "%")
    })

    output$count_excellent <- renderText({
      req(compliance_data())
      sum(compliance_data()$grade == "excellent", na.rm = TRUE)
    })

    output$count_good <- renderText({
      req(compliance_data())
      sum(compliance_data()$grade == "good", na.rm = TRUE)
    })

    output$count_poor <- renderText({
      req(compliance_data())
      sum(compliance_data()$grade %in% c("acceptable", "poor"), na.rm = TRUE)
    })

    # Compliance table
    output$compliance_table <- DT::renderDT({
      req(compliance_data())

      data <- compliance_data() %>%
        dplyr::select(
          Dashboard = name,
          Team = team,
          `Overall Score` = overall_score,
          Grade = grade,
          Accessibility = accessibility_score,
          Documentation = documentation_score,
          Repository = repository_score,
          Security = security_score,
          `Last Check` = last_compliance_check
        ) %>%
        dplyr::mutate(
          across(ends_with("score") | ends_with("Score"), ~round(.x, 1))
        )

      DT::datatable(
        data,
        options = list(
          pageLength = 15,
          searchHighlight = TRUE,
          columnDefs = list(
            list(
              targets = 3,  # Grade column
              render = htmlwidgets::JS("
                function(data, type, row) {
                  if (type === 'display' && data) {
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

    # Score distribution chart
    output$score_distribution <- echarts4r::renderEcharts4r({
      req(compliance_data())

      data <- compliance_data() %>%
        dplyr::filter(!is.na(overall_score)) %>%
        dplyr::mutate(
          score_bin = cut(
            overall_score,
            breaks = c(0, 60, 75, 90, 100),
            labels = c("Poor", "Acceptable", "Good", "Excellent"),
            include.lowest = TRUE
          )
        ) %>%
        dplyr::count(score_bin, name = "count")

      data %>%
        echarts4r::e_charts(score_bin) %>%
        echarts4r::e_bar(count) %>%
        echarts4r::e_color(c("#dc3545", "#ffc107", "#0d6efd", "#198754")) %>%
        echarts4r::e_title("Compliance Score Distribution") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_legend(show = FALSE) %>%
        echarts4r::e_x_axis(name = "Grade") %>%
        echarts4r::e_y_axis(name = "Number of Dashboards")
    })

    # Metric breakdown chart
    output$metric_breakdown <- echarts4r::renderEcharts4r({
      req(compliance_data())

      data <- compliance_data() %>%
        dplyr::filter(!is.na(overall_score)) %>%
        dplyr::summarise(
          Accessibility = mean(accessibility_score, na.rm = TRUE),
          Documentation = mean(documentation_score, na.rm = TRUE),
          Repository = mean(repository_score, na.rm = TRUE),
          Security = mean(security_score, na.rm = TRUE)
        ) %>%
        tidyr::pivot_longer(everything(), names_to = "metric", values_to = "score")

      data %>%
        echarts4r::e_charts(metric) %>%
        echarts4r::e_bar(score) %>%
        echarts4r::e_color("#0d6efd") %>%
        echarts4r::e_title("Average Score by Metric") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_y_axis(min = 0, max = 100) %>%
        echarts4r::e_x_axis(name = "Metric") %>%
        echarts4r::e_y_axis(name = "Average Score")
    })

    # Compliance trends (mock data for now)
    output$compliance_trends <- echarts4r::renderEcharts4r({
      # Generate trend data for last 6 months
      months <- seq(Sys.Date() - lubridate::months(5), Sys.Date(), by = "month")

      trend_data <- tibble::tibble(
        month = format(months, "%b %Y"),
        score = seq(70, 85, length.out = 6) + rnorm(6, 0, 2)
      )

      trend_data %>%
        echarts4r::e_charts(month) %>%
        echarts4r::e_line(score, smooth = TRUE) %>%
        echarts4r::e_area(score, smooth = TRUE) %>%
        echarts4r::e_color("#0d6efd") %>%
        echarts4r::e_title("Compliance Trend (6 months)") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_y_axis(min = 0, max = 100) %>%
        echarts4r::e_x_axis(name = "Month") %>%
        echarts4r::e_y_axis(name = "Average Compliance Score")
    })

    # Run compliance check
    observeEvent(input$btn_run_check, {
      req(has_permission(user(), "edit_all") || has_permission(user(), "manage_compliance"))

      waiter::waiter_show(
        html = waiter::spin_fading_circles(),
        color = waiter::transparent(0.5)
      )

      tryCatch({
        # Get all dashboards
        dashboards <- dashboard_repo$get_all()

        # Run compliance check for each
        purrr::walk(seq_len(nrow(dashboards)), function(i) {
          dashboard <- dashboards[i, ]

          # Perform check
          check_result <- compliance_service$perform_check(dashboard)

          # Save to database
          compliance_repo$create(check_result)
        })

        shiny::showNotification(
          paste("Compliance check completed for", nrow(dashboards), "dashboards"),
          type = "message",
          duration = 3
        )

        # Trigger refresh
        rv$refresh_trigger <- rv$refresh_trigger + 1
      }, error = function(e) {
        shiny::showNotification(
          paste("Error running compliance check:", e$message),
          type = "error",
          duration = 5
        )
      }, finally = {
        waiter::waiter_hide()
      })
    })
  })
}
