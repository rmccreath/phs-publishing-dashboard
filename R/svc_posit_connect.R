#' Posit Connect API Service
#'
#' @description R6 class for interacting with Posit Connect API
#' @export
PositConnectService <- R6::R6Class(
  "PositConnectService",
  private = list(
    base_url = NULL,
    api_key = NULL,
    cache = NULL,
    cache_ttl = NULL,
    logger = NULL,

    #' Make API request
    #' @param endpoint API endpoint
    #' @param method HTTP method
    #' @param body Request body
    #' @return Response data
    request = function(endpoint, method = "GET", body = NULL) {
      req <- httr2::request(private$base_url) %>%
        httr2::req_url_path_append(endpoint) %>%
        httr2::req_headers(Authorization = paste("Key", private$api_key)) %>%
        httr2::req_method(method) %>%
        httr2::req_retry(max_tries = 3) %>%
        httr2::req_timeout(30)

      if (!is.null(body)) {
        req <- req %>% httr2::req_body_json(body)
      }

      tryCatch({
        response <- req %>% httr2::req_perform()
        httr2::resp_body_json(response)
      }, error = function(e) {
        private$logger$error(paste("Connect API error:", e$message))
        list(error = e$message)
      })
    }
  ),

  public = list(
    #' @description Initialize service
    #' @param base_url Connect server URL
    #' @param api_key API key
    #' @param cache_ttl Cache time-to-live in seconds
    initialize = function(base_url = NULL, api_key = NULL, cache_ttl = 3600) {
      config <- safe_get_config()

      private$base_url <- base_url %||% config$apis$posit_connect$base_url
      private$api_key <- api_key %||% config$apis$posit_connect$api_key
      private$cache_ttl <- cache_ttl %||% config$apis$posit_connect$cache_ttl
      private$cache <- cachem::cache_mem()
      private$logger <- log4r::logger()

      if (is.null(private$base_url) || is.null(private$api_key) ||
          nchar(private$base_url) == 0 || nchar(private$api_key) == 0) {
        warning("Posit Connect credentials not configured - API calls will not work")
        private$logger$warning("Posit Connect service initialized without credentials")
      }
    },

    #' @description Get all content items
    #' @param use_cache Use cached data
    #' @return List of content items
    get_content = function(use_cache = TRUE) {
      cache_key <- "connect_content"

      if (use_cache) {
        cached <- private$cache$get(cache_key)
        if (!is.null(cached)) {
          private$logger$info("Returning cached content list")
          return(cached)
        }
      }

      private$logger$info("Fetching content from Connect API")
      response <- private$request("v1/content")

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get content item by GUID
    #' @param guid Content GUID
    #' @return Content item details
    get_content_item = function(guid) {
      cache_key <- paste0("connect_content_", guid)

      cached <- private$cache$get(cache_key)
      if (!is.null(cached)) {
        return(cached)
      }

      private$logger$info(paste("Fetching content item:", guid))
      response <- private$request(paste0("v1/content/", guid))

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get usage data for content
    #' @param content_guid Content GUID
    #' @param from Start date (YYYY-MM-DD)
    #' @param to End date (YYYY-MM-DD)
    #' @return Usage data
    get_usage = function(content_guid, from = NULL, to = NULL) {
      from <- from %||% (Sys.Date() - 30)
      to <- to %||% Sys.Date()

      endpoint <- glue::glue("v1/instrumentation/content/visits?
                             content_guid={content_guid}&from={from}&to={to}")

      private$logger$info(paste("Fetching usage for:", content_guid))
      private$request(endpoint)
    },

    #' @description Get user information
    #' @param user_guid User GUID
    #' @return User details
    get_user = function(user_guid) {
      cache_key <- paste0("connect_user_", user_guid)

      cached <- private$cache$get(cache_key)
      if (!is.null(cached)) {
        return(cached)
      }

      response <- private$request(paste0("v1/users/", user_guid))

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Transform Connect content to dashboard format
    #' @param content_items List of content items from API
    #' @return Data frame of dashboards
    transform_to_dashboards = function(content_items) {
      purrr::map_dfr(content_items, function(item) {
        tibble::tibble(
          external_id = item$guid,
          name = item$name,
          description = item$description %||% NA_character_,
          url = item$content_url,
          platform = "posit_connect",
          type = item$app_mode %||% "shiny",
          owner_id = item$owner_guid,
          deployment_date = lubridate::ymd_hms(item$created_time),
          last_updated = lubridate::ymd_hms(item$last_deployed_time),
          metadata = list(jsonlite::toJSON(item, auto_unbox = TRUE))
        )
      })
    },

    #' @description Clear cache
    clear_cache = function() {
      private$cache$reset()
      private$logger$info("Connect API cache cleared")
    }
  )
)
