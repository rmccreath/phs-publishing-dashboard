#' Helper Utilities
#'
#' @description Miscellaneous helper functions
#' @noRd

#' Null coalescing operator
#'
#' @param x First value
#' @param y Second value (default if x is NULL)
#' @return x if not NULL, otherwise y
#' @export
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Format number with commas
#'
#' @param x Numeric value
#' @param digits Number of decimal places
#' @return Formatted string
#' @export
format_number <- function(x, digits = 0) {
  if (is.na(x)) return("N/A")
  formatC(x, format = "f", big.mark = ",", digits = digits)
}

#' Format percentage
#'
#' @param x Numeric value (0-100)
#' @param digits Number of decimal places
#' @return Formatted string with % sign
#' @export
format_percentage <- function(x, digits = 1) {
  if (is.na(x)) return("N/A")
  paste0(round(x, digits), "%")
}

#' Format date for display
#'
#' @param x Date/datetime
#' @param format Format string
#' @return Formatted date string
#' @export
format_date <- function(x, format = "%Y-%m-%d") {
  if (is.na(x)) return("N/A")
  format(as.POSIXct(x), format)
}

#' Safe HTML output
#'
#' @param text Text to sanitize
#' @return Sanitized text
#' @export
safe_html <- function(text) {
  if (is.null(text) || is.na(text)) return("")
  gsub("<", "&lt;", gsub(">", "&gt;", text))
}

#' Create badge HTML
#'
#' @param text Badge text
#' @param type Badge type (success, danger, warning, info, primary, secondary)
#' @return HTML badge
#' @export
badge <- function(text, type = "secondary") {
  shiny::tags$span(class = paste0("badge bg-", type), text)
}

#' Create status icon
#'
#' @param status Status value
#' @return HTML icon
#' @export
status_icon <- function(status) {
  icons <- list(
    success = list(icon = "check-circle", color = "success"),
    error = list(icon = "x-circle", color = "danger"),
    warning = list(icon = "exclamation-triangle", color = "warning"),
    info = list(icon = "info-circle", color = "info")
  )

  icon_data <- icons[[status]] %||% icons$info

  shiny::tags$i(
    class = paste0("bi bi-", icon_data$icon, " text-", icon_data$color)
  )
}

#' Validate email address
#'
#' @param email Email string
#' @return Boolean
#' @export
is_valid_email <- function(email) {
  grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)
}

#' Validate URL
#'
#' @param url URL string
#' @return Boolean
#' @export
is_valid_url <- function(url) {
  grepl("^https?://", url)
}

#' Truncate text
#'
#' @param text Text to truncate
#' @param max_length Maximum length
#' @param suffix Suffix to add (default "...")
#' @return Truncated text
#' @export
truncate_text <- function(text, max_length = 50, suffix = "...") {
  if (is.na(text)) return("")
  if (nchar(text) <= max_length) return(text)
  paste0(substr(text, 1, max_length - nchar(suffix)), suffix)
}

#' Generate random color
#'
#' @param n Number of colors
#' @return Vector of hex colors
#' @export
random_colors <- function(n) {
  grDevices::rainbow(n)
}

#' Safe division
#'
#' @param x Numerator
#' @param y Denominator
#' @param default Default value if y is 0
#' @return Result of x/y or default
#' @export
safe_divide <- function(x, y, default = 0) {
  ifelse(y == 0 | is.na(y), default, x / y)
}

#' Log message with timestamp
#'
#' @param message Message to log
#' @param level Log level (INFO, WARNING, ERROR)
#' @export
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, level, message))
}

#' Create info tooltip
#'
#' @param text Tooltip text
#' @param icon Icon to display
#' @return HTML with tooltip
#' @export
info_tooltip <- function(text, icon = "question-circle") {
  shiny::tags$span(
    class = "info-tooltip",
    bsicons::bs_icon(icon),
    title = text,
    `data-bs-toggle` = "tooltip"
  )
}
