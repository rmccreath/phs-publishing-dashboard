#' Audit Checklist Module
#'
#' @description Pre-deployment audit checklist for products
#' @name mod_audit_checklist
NULL

#' Audit Checklist UI
#'
#' @param id Module ID
#' @export
mod_audit_checklist_ui <- function(id) {
  ns <- NS(id)

  shiny::tagList(
    # Audit status banner
    shiny::uiOutput(ns("audit_status_banner")),

    # Audit checklist sections
    shiny::uiOutput(ns("audit_checklist"))
  )
}

#' Audit Checklist Server
#'
#' @param id Module ID
#' @param product_id Reactive product ID
#' @param product Reactive product data
#' @param audit_repo Audit repository instance
#' @param user Reactive user object
#' @export
mod_audit_checklist_server <- function(id, product_id, product, audit_repo, user) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      refresh_trigger = 0
    )

    # Load audit checklist
    audit_data <- reactive({
      rv$refresh_trigger  # Trigger refresh
      req(product_id())

      if (is.null(audit_repo)) {
        return(NULL)
      }

      result <- audit_repo$get_by_product_id(product_id())
      result
    })

    # Calculate completion percentage
    completion_pct <- reactive({
      audit <- audit_data()
      if (is.null(audit) || nrow(audit) == 0) return(0)

      items <- audit$checklist_items[[1]]
      if (is.null(items) || length(items) == 0) return(0)

      completed <- sum(sapply(items, function(x) x$status == "completed"))
      total <- length(items)

      round((completed / total) * 100)
    })

    # Audit status banner
    output$audit_status_banner <- renderUI({
      audit <- audit_data()
      prod <- product()

      req(prod)
      req(nrow(prod) > 0)

      if (is.null(audit) || nrow(audit) == 0) {
        return(shiny::div(
          class = "alert alert-info d-flex align-items-center mb-4",
          shiny::icon("info-circle", class = "me-2"),
          shiny::div(
            shiny::strong("Audit Not Started"), shiny::br(),
            "This product is ready for audit. Click 'Start Audit' to begin the pre-deployment checklist."
          ),
          if (has_permission(user(), "audit")) {
            shiny::actionButton(
              ns("btn_start_audit"),
              "Start Audit",
              class = "btn-primary ms-auto",
              icon = shiny::icon("play")
            )
          }
        ))
      }

      pct <- completion_pct()
      audit_complete <- !is.null(audit$status[1]) && audit$status[1] == "completed"

      if (audit_complete) {
        shiny::div(
          class = "alert alert-success d-flex align-items-center mb-4",
          shiny::icon("check-circle", class = "me-2"),
          shiny::div(
            shiny::strong("Audit Complete"), shiny::br(),
            sprintf("All checklist items completed. Ready for deployment.")
          )
        )
      } else {
        shiny::div(
          class = "alert alert-warning d-flex align-items-center mb-4",
          shiny::icon("tasks", class = "me-2"),
          shiny::div(
            shiny::strong("Audit In Progress"), shiny::br(),
            sprintf("%d%% complete - %d items remaining",
                    pct,
                    sum(sapply(audit$checklist_items[[1]], function(x) x$status != "completed")))
          )
        )
      }
    })

    # Render audit checklist
    output$audit_checklist <- renderUI({
      audit <- audit_data()

      if (is.null(audit) || nrow(audit) == 0) {
        return(NULL)
      }

      items <- audit$checklist_items[[1]]
      can_audit <- has_permission(user(), "audit")

      # Group items by category
      categories <- unique(sapply(items, function(x) x$category))

      category_cards <- lapply(categories, function(cat) {
        cat_items <- items[sapply(items, function(x) x$category == cat)]

        bslib::card(
          bslib::card_header(
            class = "bg-light",
            shiny::strong(cat)
          ),
          bslib::card_body(
            lapply(cat_items, function(item) {
              item_completed <- item$status == "completed"

              shiny::div(
                class = "border rounded p-3 mb-2",
                style = if(item_completed) "background-color: #d4edda;" else "background-color: #fff9e6;",
                shiny::div(
                  class = "d-flex justify-content-between align-items-start",
                  shiny::div(
                    shiny::h6(
                      class = "mb-1",
                      if(item_completed) {
                        shiny::span(shiny::icon("check-square", class = "text-success me-2"), item$description)
                      } else {
                        shiny::span(shiny::icon("square", class = "text-muted me-2"), item$description)
                      }
                    ),
                    if (!is.null(item$guidance) && nchar(item$guidance) > 0) {
                      shiny::p(class = "text-muted small mb-0", item$guidance)
                    }
                  ),
                  if (item_completed) {
                    shiny::span(class = "badge bg-success", "Completed")
                  } else {
                    shiny::span(class = "badge bg-warning text-dark",
                               tools::toTitleCase(gsub("_", " ", item$status)))
                  }
                ),
                if (item_completed && !is.null(item$checked_by)) {
                  shiny::div(
                    class = "mt-2 small text-muted",
                    sprintf("Completed by %s on %s",
                           item$checked_by,
                           format(item$checked_at, "%d %b %Y %H:%M"))
                  )
                },
                if (!item_completed && can_audit) {
                  shiny::div(
                    class = "mt-2",
                    shiny::actionButton(
                      ns(paste0("btn_check_", item$id)),
                      "Mark Complete",
                      class = "btn-success btn-sm",
                      icon = shiny::icon("check"),
                      onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority: 'event'});",
                                       ns("item_checked"), item$id)
                    )
                  )
                }
              )
            })
          )
        )
      })

      shiny::tagList(category_cards)
    })

    # Start audit
    observeEvent(input$btn_start_audit, {
      req(product_id())
      req(has_permission(user(), "audit"))

      tryCatch({
        audit_repo$create(product_id())

        shiny::showNotification(
          "Audit checklist created successfully",
          type = "message",
          duration = 3
        )

        rv$refresh_trigger <- rv$refresh_trigger + 1
      }, error = function(e) {
        shiny::showNotification(
          paste("Error creating audit:", e$message),
          type = "error",
          duration = 5
        )
      })
    })

    # Handle item check
    observeEvent(input$item_checked, {
      req(input$item_checked)
      req(has_permission(user(), "audit"))
      req(product_id())

      item_id <- input$item_checked

      tryCatch({
        result <- audit_repo$check_item(
          product_id(),
          item_id,
          user()$full_name
        )

        if (result$all_complete) {
          shiny::showNotification(
            HTML("<strong>Audit Complete!</strong><br/>All checklist items have been completed. Product is ready for deployment."),
            type = "message",
            duration = 5
          )
        } else {
          shiny::showNotification(
            "Item marked complete",
            type = "message",
            duration = 2
          )
        }

        rv$refresh_trigger <- rv$refresh_trigger + 1
      }, error = function(e) {
        shiny::showNotification(
          paste("Error updating item:", e$message),
          type = "error",
          duration = 5
        )
      })
    })
  })
}
