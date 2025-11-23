#' Product List Module
#'
#' @description Main product list page showing all products across all lifecycle stages
#' @name mod_product_list
NULL

#' Product List UI
#'
#' @param id Module ID
#' @export
mod_product_list_ui <- function(id) {
  ns <- NS(id)

  bslib::page_fillable(
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        title = "Filters",
        width = 280,

        shiny::selectInput(
          ns("filter_stage"),
          "Lifecycle Stage",
          choices = c(
            "All" = "",
            "Approved (Awaiting Development)" = "approved",
            "In Development" = "in_development",
            "In Audit" = "in_audit",
            "Deployed" = "deployed",
            "Archived" = "archived"
          ),
          selected = ""
        ),

        shiny::selectInput(
          ns("filter_type"),
          "Product Type",
          choices = c(
            "All" = "",
            "Shiny Dashboard" = "shiny_dashboard",
            "Quarto Report" = "quarto_report",
            "Dash Application" = "dash_app",
            "API Service" = "api_service",
            "Other" = "other"
          ),
          selected = ""
        ),

        shiny::selectInput(
          ns("filter_department"),
          "Department",
          choices = c("All" = ""),
          selected = ""
        ),

        shiny::textInput(
          ns("filter_search"),
          "Search",
          placeholder = "Product name..."
        ),

        shiny::hr(),

        shiny::div(
          class = "d-grid gap-2",
          shiny::actionButton(
            ns("btn_clear_filters"),
            "Clear Filters",
            icon = shiny::icon("filter-circle-xmark"),
            class = "btn-outline-secondary btn-sm"
          )
        )
      ),

      # Main content
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(
          class = "d-flex justify-content-between align-items-center",
          shiny::div(
            shiny::h4("Information Products", class = "mb-0"),
            shiny::tags$small(
              class = "text-muted",
              shiny::textOutput(ns("product_count"), inline = TRUE)
            )
          ),
          shiny::div(
            class = "btn-group",
            shiny::actionButton(
              ns("btn_new_approval"),
              "Submit New Approval",
              icon = shiny::icon("plus"),
              class = "btn-success"
            ),
            shiny::actionButton(
              ns("btn_refresh"),
              "Refresh",
              icon = shiny::icon("refresh"),
              class = "btn-outline-primary"
            )
          )
        ),
        bslib::card_body(
          waiter::useWaiter(),
          DT::DTOutput(ns("product_table"))
        )
      )
    ),

    # Summary cards at top
    bslib::layout_column_wrap(
      width = 1/5,
      heights_equal = "row",

      bslib::value_box(
        title = "Awaiting Approval",
        value = shiny::textOutput(ns("count_approval"), inline = TRUE),
        showcase = bsicons::bs_icon("clipboard-check"),
        theme = "warning"
      ),

      bslib::value_box(
        title = "In Audit",
        value = shiny::textOutput(ns("count_audit"), inline = TRUE),
        showcase = bsicons::bs_icon("search"),
        theme = "info"
      ),

      bslib::value_box(
        title = "Deployed",
        value = shiny::textOutput(ns("count_deployed"), inline = TRUE),
        showcase = bsicons::bs_icon("check-circle"),
        theme = "success"
      ),

      bslib::value_box(
        title = "Review Due",
        value = shiny::textOutput(ns("count_review_due"), inline = TRUE),
        showcase = bsicons::bs_icon("clock"),
        theme = "danger"
      ),

      bslib::value_box(
        title = "Total Products",
        value = shiny::textOutput(ns("count_total"), inline = TRUE),
        showcase = bsicons::bs_icon("grid"),
        theme = "primary"
      )
    )
  )
}

#' Product List Server
#'
#' @param id Module ID
#' @param product_repo Product repository instance
#' @param user Reactive user object
#' @export
mod_product_list_server <- function(id, product_repo, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      last_refresh = Sys.time()
    )

    # Load products
    products <- reactive({
      # Trigger on filter changes or refresh
      input$filter_stage
      input$filter_type
      input$filter_department
      input$filter_search
      input$btn_refresh
      rv$last_refresh

      tryCatch({
        # Get all products
        data <- product_repo$get_all()

        # Ensure we have data
        if (is.null(data) || nrow(data) == 0) {
          message("No products found in repository")
          return(tibble::tibble())
        }

        message("Loaded ", nrow(data), " products")

        # Apply filters
        filter_stage_value <- input$filter_stage
        if (!is.null(filter_stage_value) && filter_stage_value != "") {
          data <- data %>% dplyr::filter(.data$lifecycle_stage == filter_stage_value)
        }

        filter_type_value <- input$filter_type
        if (!is.null(filter_type_value) && filter_type_value != "") {
          data <- data %>% dplyr::filter(.data$type == filter_type_value)
        }

        filter_dept_value <- input$filter_department
        if (!is.null(filter_dept_value) && filter_dept_value != "") {
          data <- data %>% dplyr::filter(.data$department == filter_dept_value)
        }

        filter_search_value <- input$filter_search
        if (!is.null(filter_search_value) && nchar(filter_search_value) > 0) {
          search_term <- tolower(filter_search_value)
          data <- data %>%
            dplyr::filter(
              grepl(search_term, tolower(.data$name)) |
              grepl(search_term, tolower(.data$description %||% ""))
            )
        }

        # Filter by access permissions
        filter_by_access(data, user(), "created_by", "team")
      }, error = function(e) {
        message("Error loading products: ", e$message)
        shiny::showNotification(
          paste("Error loading products:", e$message),
          type = "error",
          duration = 5
        )
        tibble::tibble()
      })
    })

    # Update department choices dynamically
    observe({
      all_products <- product_repo$get_all()
      departments <- unique(all_products$department)
      departments <- sort(departments[!is.na(departments)])

      shiny::updateSelectInput(
        session,
        "filter_department",
        choices = c("All" = "", setNames(departments, departments))
      )
    })

    # Summary counts
    output$count_approval <- renderText({
      sum(products()$lifecycle_stage == "approved", na.rm = TRUE)
    })

    output$count_audit <- renderText({
      sum(products()$lifecycle_stage == "in_audit", na.rm = TRUE)
    })

    output$count_deployed <- renderText({
      sum(products()$lifecycle_stage == "deployed", na.rm = TRUE)
    })

    output$count_review_due <- renderText({
      # Count products with review_due status
      sum(products()$current_status == "review_due", na.rm = TRUE)
    })

    output$count_total <- renderText({
      nrow(products())
    })

    # Product count
    output$product_count <- renderText({
      paste(nrow(products()), "products")
    })

    # Render product table
    output$product_table <- DT::renderDT({
      req(products())
      req(nrow(products()) > 0)

      # Store full data for row selection
      full_data <- products()

      # Prepare display data
      data <- full_data %>%
        dplyr::mutate(
          Type_Display = dplyr::case_when(
            type == "shiny_dashboard" ~ "Shiny Dashboard",
            type == "quarto_report" ~ "Quarto Report",
            type == "dash_app" ~ "Dash App",
            type == "api_service" ~ "API Service",
            TRUE ~ tools::toTitleCase(type)
          ),
          Stage_Display = dplyr::case_when(
            lifecycle_stage == "approved" ~ "Approved",
            lifecycle_stage == "in_development" ~ "In Development",
            lifecycle_stage == "in_audit" ~ "In Audit",
            lifecycle_stage == "deployed" ~ "Deployed",
            lifecycle_stage == "archived" ~ "Archived",
            TRUE ~ tools::toTitleCase(lifecycle_stage)
          ),
          Status_Display = tools::toTitleCase(gsub("_", " ", current_status %||% ""))
        ) %>%
        dplyr::select(
          product_id,  # Keep for row selection
          Name = name,
          Type = Type_Display,
          Department = department,
          Team = team,
          Stage = Stage_Display,
          Status = Status_Display,
          Created = created_at
        )

      DT::datatable(
        data,
        options = list(
          pageLength = 25,
          searchHighlight = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel'),
          order = list(list(7, 'desc')), # Sort by Created descending (adjusted for hidden column)
          columnDefs = list(
            list(visible = FALSE, targets = 0)  # Hide product_id column
          )
        ),
        selection = 'single',
        class = "display compact stripe hover",
        rownames = FALSE
      )
    })

    # Clear filters
    observeEvent(input$btn_clear_filters, {
      shiny::updateSelectInput(session, "filter_stage", selected = "")
      shiny::updateSelectInput(session, "filter_type", selected = "")
      shiny::updateSelectInput(session, "filter_department", selected = "")
      shiny::updateTextInput(session, "filter_search", value = "")
    })

    # Navigate to product detail on row click
    observeEvent(input$product_table_rows_selected, {
      req(input$product_table_rows_selected)
      selected_row <- input$product_table_rows_selected

      # Get product data
      prod_data <- products()
      if (!is.null(prod_data) && nrow(prod_data) >= selected_row) {
        product_id <- prod_data[selected_row, ]$product_id
        if (!is.null(product_id) && nchar(product_id) > 0) {
          # Navigate to product detail page
          shiny.router::change_page(paste0("/product?id=", product_id))
        }
      }
    })

    # Navigate to approval submission
    observeEvent(input$btn_new_approval, {
      shiny.router::change_page("/approvals?tab=submit")
    })

    # Refresh data
    observeEvent(input$btn_refresh, {
      rv$last_refresh <- Sys.time()
      shiny::showNotification("Products refreshed", type = "message", duration = 2)
    })
  })
}
