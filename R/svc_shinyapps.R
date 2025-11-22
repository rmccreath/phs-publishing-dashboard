#' ShinyApps.io API Service
#'
#' @description R6 class for interacting with ShinyApps.io API
#' @export
ShinyAppsService <- R6::R6Class(
  "ShinyAppsService",
  private = list(
    base_url = NULL,
    api_key = NULL,
    api_secret = NULL,
    cache = NULL,
    cache_ttl = NULL,
    logger = NULL,

    #' Generate HMAC signature for authentication
    #' @param method HTTP method
    #' @param path URL path
    #' @param timestamp Unix timestamp
    #' @return Signature string
    generate_signature = function(method, path, timestamp) {
      message <- paste(method, path, timestamp, sep = "\n")
      signature <- digest::hmac(
        private$api_secret,
        message,
        algo = "sha256",
        serialize = FALSE
      )
      base64enc::base64encode(charToRaw(signature))
    },

    #' Make API request
    #' @param endpoint API endpoint
    #' @param method HTTP method
    #' @return Response data
    request = function(endpoint, method = "GET") {
      timestamp <- as.character(as.integer(Sys.time()))
      path <- paste0("/v1/", endpoint)

      signature <- private$generate_signature(method, path, timestamp)

      req <- httr2::request(private$base_url) %>%
        httr2::req_url_path_append(endpoint) %>%
        httr2::req_headers(
          `X-Auth-Token` = private$api_key,
          `X-Auth-Signature` = signature,
          `X-Auth-Timestamp` = timestamp
        ) %>%
        httr2::req_method(method) %>%
        httr2::req_retry(max_tries = 3) %>%
        httr2::req_timeout(30)

      tryCatch({
        response <- req %>% httr2::req_perform()
        httr2::resp_body_json(response)
      }, error = function(e) {
        private$logger$error(paste("ShinyApps.io API error:", e$message))
        list(error = e$message)
      })
    }
  ),

  public = list(
    #' @description Initialize service
    #' @param api_key ShinyApps.io API key
    #' @param api_secret ShinyApps.io API secret
    initialize = function(api_key = NULL, api_secret = NULL) {
      config <- safe_get_config()

      private$base_url <- config$apis$shinyapps_io$base_url
      private$api_key <- api_key %||% config$apis$shinyapps_io$api_key
      private$api_secret <- api_secret %||% config$apis$shinyapps_io$api_secret
      private$cache_ttl <- config$apis$shinyapps_io$cache_ttl
      private$cache <- cachem::cache_mem()
      private$logger <- log4r::logger()

      if (is.null(private$api_key) || is.null(private$api_secret) ||
          nchar(private$api_key) == 0 || nchar(private$api_secret) == 0) {
        warning("ShinyApps.io credentials not configured - API calls will not work")
        private$logger$warning("ShinyApps.io service initialized without credentials")
      }
    },

    #' @description Get all applications
    #' @param use_cache Use cached data
    #' @return List of applications
    get_applications = function(use_cache = TRUE) {
      cache_key <- "shinyapps_applications"

      if (use_cache) {
        cached <- private$cache$get(cache_key)
        if (!is.null(cached)) {
          return(cached)
        }
      }

      private$logger$info("Fetching applications from ShinyApps.io")
      response <- private$request("applications")

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get application details
    #' @param app_id Application ID
    #' @return Application details
    get_application = function(app_id) {
      cache_key <- paste0("shinyapps_app_", app_id)

      cached <- private$cache$get(cache_key)
      if (!is.null(cached)) {
        return(cached)
      }

      private$logger$info(paste("Fetching application:", app_id))
      response <- private$request(paste0("applications/", app_id))

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get application metrics
    #' @param app_id Application ID
    #' @param from Start date
    #' @param to End date
    #' @return Metrics data
    get_metrics = function(app_id, from = NULL, to = NULL) {
      from <- from %||% (Sys.Date() - 30)
      to <- to %||% Sys.Date()

      endpoint <- glue::glue("applications/{app_id}/metrics?from={from}&to={to}")
      private$request(endpoint)
    },

    #' @description Transform ShinyApps applications to dashboard format
    #' @param applications List of applications from API
    #' @return Data frame of dashboards
    transform_to_dashboards = function(applications) {
      purrr::map_dfr(applications, function(app) {
        tibble::tibble(
          external_id = as.character(app$id),
          name = app$name,
          description = app$title %||% NA_character_,
          url = app$url,
          platform = "shinyapps_io",
          type = "shiny",
          deployment_date = lubridate::ymd_hms(app$created_time),
          last_updated = lubridate::ymd_hms(app$updated_time),
          metadata = list(jsonlite::toJSON(app, auto_unbox = TRUE))
        )
      })
    },

    #' @description Clear cache
    clear_cache = function() {
      private$cache$reset()
      private$logger$info("ShinyApps.io API cache cleared")
    }
  )
)
