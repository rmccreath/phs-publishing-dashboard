#' Analytics & Reporting Module
#'
#' @description Shiny module for dashboard analytics and reporting
#' @name mod_analytics_reporting
NULL

#' Analytics & Reporting UI
#'
#' @param id Module ID
#' @export
mod_analytics_reporting_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    bslib::navset_card_tab(
      id = ns("analytics_tabs"),
      full_screen = TRUE,

      # Overview Tab
      bslib::nav_panel(
        title = "Overview",
        icon = bsicons::bs_icon("speedometer2"),

        bslib::layout_column_wrap(
          width = 1/4,

          bslib::value_box(
            title = "Total Dashboards",
            value = shiny::textOutput(ns("total_dashboards"), inline = TRUE),
            showcase = bsicons::bs_icon("grid"),
            theme = "primary"
          ),

          bslib::value_box(
            title = "Published",
            value = shiny::textOutput(ns("published_count"), inline = TRUE),
            showcase = bsicons::bs_icon("check-circle"),
            theme = "success"
          ),

          bslib::value_box(
            title = "In Development",
            value = shiny::textOutput(ns("draft_count"), inline = TRUE),
            showcase = bsicons::bs_icon("pencil"),
            theme = "info"
          ),

          bslib::value_box(
            title = "Teams",
            value = shiny::textOutput(ns("team_count"), inline = TRUE),
            showcase = bsicons::bs_icon("people"),
            theme = "secondary"
          )
        ),

        bslib::layout_columns(
          col_widths = c(6, 6),

          bslib::card(
            bslib::card_header("Dashboards by Platform"),
            bslib::card_body(
              echarts4r::echarts4rOutput(ns("platform_chart"))
            )
          ),

          bslib::card(
            bslib::card_header("Dashboards by Status"),
            bslib::card_body(
              echarts4r::echarts4rOutput(ns("status_chart"))
            )
          )
        ),

        bslib::card(
          bslib::card_header("Deployment Timeline"),
          bslib::card_body(
            echarts4r::echarts4rOutput(ns("deployment_timeline"), height = "300px")
          )
        )
      ),

      # Team Performance Tab
      bslib::nav_panel(
        title = "Team Performance",
        icon = bsicons::bs_icon("people-fill"),

        bslib::card(
          bslib::card_header("Team Compliance Scorecard"),
          bslib::card_body(
            reactable::reactableOutput(ns("team_scorecard"))
          )
        ),

        bslib::layout_columns(
          col_widths = c(6, 6),

          bslib::card(
            bslib::card_header("Compliance by Team"),
            bslib::card_body(
              echarts4r::echarts4rOutput(ns("team_compliance_chart"))
            )
          ),

          bslib::card(
            bslib::card_header("Dashboard Count by Team"),
            bslib::card_body(
              echarts4r::echarts4rOutput(ns("team_dashboard_chart"))
            )
          )
        )
      ),

      # Benchmarking Tab
      bslib::nav_panel(
        title = "Benchmarking",
        icon = bsicons::bs_icon("bar-chart"),

        bslib::card(
          bslib::card_header("Best Performing Dashboards"),
          bslib::card_body(
            DT::DTOutput(ns("best_dashboards_table"))
          )
        ),

        bslib::card(
          bslib::card_header("Compliance Metric Comparison"),
          bslib::card_body(
            echarts4r::echarts4rOutput(ns("metric_comparison_chart"), height = "400px")
          )
        )
      ),

      # Reports Tab
      bslib::nav_panel(
        title = "Reports",
        icon = bsicons::bs_icon("file-earmark-text"),

        bslib::card(
          bslib::card_header("Generate Reports"),
          bslib::card_body(
            shiny::div(
              class = "row",

              shiny::div(
                class = "col-md-6",

                shiny::h5("Report Type"),

                shiny::radioButtons(
                  ns("report_type"),
                  NULL,
                  choices = c(
                    "Executive Summary" = "executive",
                    "Compliance Report" = "compliance",
                    "Team Performance" = "team",
                    "Full Audit" = "audit"
                  ),
                  selected = "executive"
                ),

                shiny::selectInput(
                  ns("report_format"),
                  "Format",
                  choices = c("PDF" = "pdf", "CSV" = "csv", "Excel" = "xlsx")
                ),

                shiny::dateRangeInput(
                  ns("report_date_range"),
                  "Date Range",
                  start = Sys.Date() - 30,
                  end = Sys.Date()
                ),

                shiny::checkboxGroupInput(
                  ns("report_sections"),
                  "Include Sections",
                  choices = c(
                    "Summary Statistics" = "summary",
                    "Compliance Details" = "compliance",
                    "Team Breakdown" = "teams",
                    "Recommendations" = "recommendations"
                  ),
                  selected = c("summary", "compliance")
                ),

                shiny::hr(),

                shiny::actionButton(
                  ns("btn_generate"),
                  "Generate Report",
                  icon = shiny::icon("file-download"),
                  class = "btn-primary btn-lg w-100"
                )
              ),

              shiny::div(
                class = "col-md-6",

                shiny::h5("Recent Reports"),

                shiny::div(
                  class = "list-group",

                  shiny::div(
                    class = "list-group-item",
                    shiny::h6("Executive Summary - ", Sys.Date()),
                    shiny::p("Generated by ", user()$full_name, class = "text-muted mb-0")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

#' Analytics & Reporting Server
#'
#' @param id Module ID
#' @param dashboard_repo Dashboard repository instance
#' @param user Reactive user object
#' @export
mod_analytics_reporting_server <- function(id, dashboard_repo, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Load dashboard data
    dashboard_data <- reactive({
      data <- dashboard_repo$get_all()
      filter_by_access(data, user(), "owner_id", "team")
    })

    # Summary metrics
    output$total_dashboards <- renderText({
      req(dashboard_data())
      nrow(dashboard_data())
    })

    output$published_count <- renderText({
      req(dashboard_data())
      sum(dashboard_data()$status == "published", na.rm = TRUE)
    })

    output$draft_count <- renderText({
      req(dashboard_data())
      sum(dashboard_data()$status %in% c("draft", "pending_approval"), na.rm = TRUE)
    })

    output$team_count <- renderText({
      req(dashboard_data())
      length(unique(dashboard_data()$team))
    })

    # Platform chart
    output$platform_chart <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::count(platform) %>%
        dplyr::mutate(
          platform = dplyr::case_when(
            platform == "posit_connect" ~ "Posit Connect",
            platform == "shinyapps_io" ~ "ShinyApps.io",
            TRUE ~ "Other"
          )
        )

      data %>%
        echarts4r::e_charts(platform) %>%
        echarts4r::e_pie(n, radius = c("40%", "70%")) %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_legend(orient = "vertical", right = "10%")
    })

    # Status chart
    output$status_chart <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::count(status) %>%
        dplyr::mutate(
          status = tools::toTitleCase(gsub("_", " ", status))
        )

      data %>%
        echarts4r::e_charts(status) %>%
        echarts4r::e_pie(n, radius = c("40%", "70%")) %>%
        echarts4r::e_color(c("#198754", "#0d6efd", "#ffc107", "#dc3545", "#6c757d")) %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_legend(orient = "vertical", right = "10%")
    })

    # Deployment timeline
    output$deployment_timeline <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::filter(!is.na(deployment_date)) %>%
        dplyr::mutate(
          month = lubridate::floor_date(deployment_date, "month")
        ) %>%
        dplyr::count(month) %>%
        dplyr::arrange(month)

      data %>%
        echarts4r::e_charts(month) %>%
        echarts4r::e_line(n, smooth = TRUE) %>%
        echarts4r::e_area(n, smooth = TRUE) %>%
        echarts4r::e_color("#0d6efd") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_x_axis(name = "Month") %>%
        echarts4r::e_y_axis(name = "Deployments") %>%
        echarts4r::e_datazoom()
    })

    # Team scorecard
    output$team_scorecard <- reactable::renderReactable({
      req(dashboard_data())

      team_data <- dashboard_data() %>%
        dplyr::group_by(team) %>%
        dplyr::summarise(
          Dashboards = dplyr::n(),
          Published = sum(status == "published", na.rm = TRUE),
          `Avg Compliance` = mean(overall_score, na.rm = TRUE),
          Excellent = sum(grade == "excellent", na.rm = TRUE),
          Good = sum(grade == "good", na.rm = TRUE),
          Poor = sum(grade %in% c("acceptable", "poor"), na.rm = TRUE),
          .groups = "drop"
        ) %>%
        dplyr::arrange(desc(`Avg Compliance`))

      reactable::reactable(
        team_data,
        columns = list(
          team = reactable::colDef(name = "Team", minWidth = 150),
          Dashboards = reactable::colDef(minWidth = 100),
          Published = reactable::colDef(minWidth = 100),
          `Avg Compliance` = reactable::colDef(
            format = reactable::colFormat(digits = 1),
            style = function(value) {
              if (is.na(value)) return(NULL)
              color <- if (value >= 90) {
                "#198754"
              } else if (value >= 75) {
                "#0d6efd"
              } else if (value >= 60) {
                "#ffc107"
              } else {
                "#dc3545"
              }
              list(color = color, fontWeight = "bold")
            }
          ),
          Excellent = reactable::colDef(
            cell = function(value) {
              if (value > 0) {
                shiny::tags$span(class = "badge bg-success", value)
              } else {
                value
              }
            }
          ),
          Good = reactable::colDef(
            cell = function(value) {
              if (value > 0) {
                shiny::tags$span(class = "badge bg-primary", value)
              } else {
                value
              }
            }
          ),
          Poor = reactable::colDef(
            cell = function(value) {
              if (value > 0) {
                shiny::tags$span(class = "badge bg-warning", value)
              } else {
                value
              }
            }
          )
        ),
        striped = TRUE,
        highlight = TRUE,
        bordered = TRUE,
        defaultPageSize = 10
      )
    })

    # Team compliance chart
    output$team_compliance_chart <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::filter(!is.na(team), !is.na(overall_score)) %>%
        dplyr::group_by(team) %>%
        dplyr::summarise(avg_score = mean(overall_score, na.rm = TRUE), .groups = "drop") %>%
        dplyr::arrange(desc(avg_score))

      data %>%
        echarts4r::e_charts(team) %>%
        echarts4r::e_bar(avg_score) %>%
        echarts4r::e_color("#0d6efd") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_y_axis(min = 0, max = 100) %>%
        echarts4r::e_x_axis(axisLabel = list(rotate = 45))
    })

    # Team dashboard count chart
    output$team_dashboard_chart <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::count(team) %>%
        dplyr::arrange(desc(n))

      data %>%
        echarts4r::e_charts(team) %>%
        echarts4r::e_bar(n) %>%
        echarts4r::e_color("#198754") %>%
        echarts4r::e_tooltip() %>%
        echarts4r::e_x_axis(axisLabel = list(rotate = 45))
    })

    # Best dashboards table
    output$best_dashboards_table <- DT::renderDT({
      req(dashboard_data())

      data <- dashboard_data() %>%
        dplyr::filter(!is.na(overall_score)) %>%
        dplyr::arrange(desc(overall_score)) %>%
        dplyr::select(
          Name = name,
          Team = team,
          `Overall Score` = overall_score,
          Grade = grade,
          Platform = platform
        ) %>%
        head(20)

      DT::datatable(
        data,
        options = list(
          pageLength = 10,
          dom = 't'
        ),
        class = "display compact stripe",
        rownames = FALSE
      )
    })

    # Metric comparison chart
    output$metric_comparison_chart <- echarts4r::renderEcharts4r({
      req(dashboard_data())

      # Get top 10 dashboards
      top_dashboards <- dashboard_data() %>%
        dplyr::filter(!is.na(overall_score)) %>%
        dplyr::arrange(desc(overall_score)) %>%
        head(10)

      # Prepare data for radar chart
      top_dashboards %>%
        dplyr::select(
          name,
          Accessibility = accessibility_score,
          Documentation = documentation_score,
          Repository = repository_score,
          Security = security_score
        ) %>%
        tidyr::pivot_longer(-name, names_to = "metric", values_to = "score") %>%
        dplyr::group_by(name) %>%
        echarts4r::e_charts(metric) %>%
        echarts4r::e_radar(score, max = 100) %>%
        echarts4r::e_tooltip()
    })

    # Generate report
    observeEvent(input$btn_generate, {
      req(input$report_type, input$report_format)

      shiny::showNotification(
        "Report generation feature coming soon",
        type = "info",
        duration = 3
      )
    })
  })
}
