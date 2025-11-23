#' Breadcrumb Navigation Utilities
#'
#' @description Functions for creating breadcrumb navigation
#' @noRd

#' Create breadcrumb navigation
#'
#' @param ... Named list of breadcrumb items (name = url)
#' @return HTML for breadcrumb navigation
#' @export
breadcrumbs <- function(...) {
  items <- list(...)

  if (length(items) == 0) {
    return(NULL)
  }

  # Build breadcrumb items
  breadcrumb_items <- lapply(seq_along(items), function(i) {
    name <- names(items)[i]
    url <- items[[i]]
    is_last <- i == length(items)

    if (is_last) {
      # Last item is not clickable
      shiny::tags$li(
        class = "breadcrumb-item active",
        `aria-current` = "page",
        name
      )
    } else {
      # Other items are clickable
      shiny::tags$li(
        class = "breadcrumb-item",
        shiny::tags$a(
          href = shiny.router::route_link(url),
          name
        )
      )
    }
  })

  # Return breadcrumb nav
  shiny::tags$nav(
    `aria-label` = "breadcrumb",
    class = "mb-3",
    shiny::tags$ol(
      class = "breadcrumb",
      breadcrumb_items
    )
  )
}

#' Product breadcrumbs
#'
#' @param product_name Product name (optional)
#' @return Breadcrumb HTML
#' @export
product_breadcrumbs <- function(product_name = NULL) {
  if (is.null(product_name)) {
    breadcrumbs(
      "Products" = "products"
    )
  } else {
    breadcrumbs(
      "Products" = "products",
      !!product_name := ""
    )
  }
}

#' Approval breadcrumbs
#'
#' @return Breadcrumb HTML
#' @export
approval_breadcrumbs <- function() {
  breadcrumbs(
    "Products" = "products",
    "Approvals" = "approvals"
  )
}

#' Audit breadcrumbs
#'
#' @param product_name Product name (optional)
#' @return Breadcrumb HTML
#' @export
audit_breadcrumbs <- function(product_name = NULL) {
  if (is.null(product_name)) {
    breadcrumbs(
      "Products" = "products",
      "Audits" = "audits"
    )
  } else {
    breadcrumbs(
      "Products" = "products",
      "Audits" = "audits",
      !!product_name := ""
    )
  }
}

#' Review breadcrumbs
#'
#' @param product_name Product name (optional)
#' @return Breadcrumb HTML
#' @export
review_breadcrumbs <- function(product_name = NULL) {
  if (is.null(product_name)) {
    breadcrumbs(
      "Products" = "products",
      "Reviews" = "reviews"
    )
  } else {
    breadcrumbs(
      "Products" = "products",
      "Reviews" = "reviews",
      !!product_name := ""
    )
  }
}

#' Analytics breadcrumbs
#'
#' @return Breadcrumb HTML
#' @export
analytics_breadcrumbs <- function() {
  breadcrumbs(
    "Products" = "products",
    "Analytics" = "analytics"
  )
}
