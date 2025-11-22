#' Authentication and Authorization Utilities
#'
#' @description Functions for user authentication and role-based access control
#' @noRd

#' Get current user information
#'
#' @description Extract user info from Posit Connect session
#' @param session Shiny session object
#' @return List with user information
#' @export
get_current_user <- function(session = shiny::getDefaultReactiveDomain()) {
  # In Posit Connect, user info is available in session$user
  user <- session$user

  if (is.null(user)) {
    # Development mode - return mock user
    return(list(
      user_id = "user-1",
      username = "dev_user",
      email = "dev@phs.scot",
      full_name = "Development User",
      role = "admin",
      team = "Development",
      department = "IT"
    ))
  }

  # Extract user information
  list(
    user_id = user %||% "unknown",
    username = user %||% "unknown",
    email = paste0(user, "@phs.scot"),
    full_name = user,
    role = determine_user_role(user),
    team = get_user_team(user),
    department = get_user_department(user)
  )
}

#' Determine user role
#'
#' @param username Username
#' @return Role string
#' @noRd
determine_user_role <- function(username) {
  # This would typically query a database or LDAP
  # For now, use simple logic based on username pattern

  config <- config::get()

  # Check environment variable for admin users
  admin_users <- Sys.getenv("ADMIN_USERS", "")
  if (admin_users != "" && username %in% strsplit(admin_users, ",")[[1]]) {
    return("admin")
  }

  # Check for governance role
  governance_users <- Sys.getenv("GOVERNANCE_USERS", "")
  if (governance_users != "" && username %in% strsplit(governance_users, ",")[[1]]) {
    return("governance")
  }

  # Default role
  "viewer"
}

#' Get user team
#'
#' @param username Username
#' @return Team name
#' @noRd
get_user_team <- function(username) {
  # This would typically query LDAP or HR system
  "Analytics"  # Default
}

#' Get user department
#'
#' @param username Username
#' @return Department name
#' @noRd
get_user_department <- function(username) {
  # This would typically query LDAP or HR system
  "Data Science"  # Default
}

#' Check if user has permission
#'
#' @param user User object
#' @param permission Permission string
#' @return Boolean
#' @export
has_permission <- function(user, permission) {
  config <- config::get()
  role_permissions <- config$rbac$permissions[[user$role]]

  if (is.null(role_permissions)) {
    return(FALSE)
  }

  permission %in% role_permissions
}

#' Filter data based on user role
#'
#' @param data Data frame
#' @param user User object
#' @param owner_col Column name for owner
#' @param team_col Column name for team
#' @return Filtered data frame
#' @export
filter_by_access <- function(data, user, owner_col = "owner_id", team_col = "team") {
  if (has_permission(user, "view_all")) {
    return(data)
  }

  if (has_permission(user, "view_team")) {
    return(dplyr::filter(data, .data[[team_col]] == user$team))
  }

  if (has_permission(user, "view_own")) {
    return(dplyr::filter(data, .data[[owner_col]] == user$user_id))
  }

  # Return empty data frame if no access
  data[0, ]
}

#' Create access control wrapper for UI elements
#'
#' @param ui UI element
#' @param required_permission Required permission
#' @param user User object
#' @return UI element or NULL
#' @export
with_permission <- function(ui, required_permission, user) {
  if (has_permission(user, required_permission)) {
    return(ui)
  }
  NULL
}

#' Show unauthorized message
#'
#' @return Shiny UI
#' @export
unauthorized_ui <- function() {
  bslib::card(
    bslib::card_header(
      "Unauthorized Access",
      class = "bg-danger text-white"
    ),
    bslib::card_body(
      shiny::p(
        "You do not have permission to access this resource.",
        "Please contact your administrator if you believe this is an error."
      ),
      shiny::p(
        shiny::tags$a(
          href = "javascript:history.back()",
          "Go Back",
          class = "btn btn-primary"
        )
      )
    )
  )
}
