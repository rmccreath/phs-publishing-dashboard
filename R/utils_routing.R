#' Routing Utilities
#'
#' @description Functions for handling page routing in the application
#' @noRd

#' Create router configuration
#'
#' @return shiny.router router object
#' @export
create_router <- function() {
  shiny.router::router_ui(
    # Products list page (default)
    route("products", mod_product_list_ui("product_list")),

    # Product detail page
    route("product", mod_product_detail_ui("product_detail")),

    # Approvals
    route("approvals", mod_approval_workflow_ui("approvals")),

    # Audits
    route("audits", mod_audit_management_ui("audits")),

    # Reviews
    route("reviews", mod_review_management_ui("reviews")),

    # Analytics
    route("analytics", mod_analytics_reporting_ui("analytics")),

    # Default route (redirect to products)
    route("/", mod_product_list_ui("product_list"))
  )
}

#' Navigate to a route
#'
#' @param session Shiny session
#' @param page Page name
#' @param params Optional query parameters
#' @export
navigate_to <- function(session, page, params = NULL) {
  query_string <- ""
  if (!is.null(params) && length(params) > 0) {
    query_string <- paste0(
      "?",
      paste(names(params), params, sep = "=", collapse = "&")
    )
  }

  shiny.router::change_page(paste0("/", page, query_string))
}

#' Get query parameter from URL
#'
#' @param session Shiny session
#' @param param Parameter name
#' @return Parameter value or NULL
#' @export
get_query_param <- function(session, param) {
  query <- shiny.router::get_query_param()
  if (!is.null(query) && param %in% names(query)) {
    return(query[[param]])
  }
  NULL
}

#' Create navigation link
#'
#' @param page Page to navigate to
#' @param label Link label
#' @param icon Optional icon
#' @return shiny.router link
#' @export
nav_link <- function(page, label, icon = NULL) {
  shiny.router::a(
    href = shiny.router::route_link(page),
    class = "nav-link",
    if (!is.null(icon)) shiny::icon(icon),
    label
  )
}
