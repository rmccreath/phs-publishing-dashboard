#' GitHub API Service
#'
#' @description R6 class for interacting with GitHub API
#' @export
GitHubService <- R6::R6Class(
  "GitHubService",
  private = list(
    base_url = NULL,
    token = NULL,
    org = NULL,
    cache = NULL,
    cache_ttl = NULL,
    logger = NULL,

    # Make API request
    # @param endpoint API endpoint
    # @param method HTTP method
    # @return Response data
    request = function(endpoint, method = "GET") {
      req <- httr2::request(private$base_url) %>%
        httr2::req_url_path_append(endpoint) %>%
        httr2::req_headers(
          Authorization = paste("Bearer", private$token),
          Accept = "application/vnd.github+json"
        ) %>%
        httr2::req_method(method) %>%
        httr2::req_retry(max_tries = 3) %>%
        httr2::req_timeout(30)

      tryCatch({
        response <- req %>% httr2::req_perform()
        httr2::resp_body_json(response)
      }, error = function(e) {
        private$logger$error(paste("GitHub API error:", e$message))
        list(error = e$message)
      })
    }
  ),

  public = list(
    #' @description Initialize service
    #' @param token GitHub token
    #' @param org GitHub organization
    initialize = function(token = NULL, org = NULL) {
      config <- safe_get_config()

      private$base_url <- config$apis$github$base_url
      private$token <- token %||% config$apis$github$token
      private$org <- org %||% config$apis$github$org
      private$cache_ttl <- config$apis$github$cache_ttl
      private$cache <- cachem::cache_mem()
      private$logger <- log4r::logger()

      if (is.null(private$token) || nchar(private$token) == 0) {
        warning("GitHub token not configured - API calls will not work")
        private$logger$warning("GitHub service initialized without token")
      }
    },

    #' @description Get organization repositories
    #' @param use_cache Use cached data
    #' @return List of repositories
    get_repos = function(use_cache = TRUE) {
      cache_key <- paste0("github_repos_", private$org)

      if (use_cache) {
        cached <- private$cache$get(cache_key)
        if (!is.null(cached)) {
          return(cached)
        }
      }

      private$logger$info(paste("Fetching repos for org:", private$org))
      endpoint <- paste0("orgs/", private$org, "/repos?per_page=100")
      response <- private$request(endpoint)

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get repository details
    #' @param owner Repository owner
    #' @param repo Repository name
    #' @return Repository details
    get_repo = function(owner, repo) {
      cache_key <- paste0("github_repo_", owner, "_", repo)

      cached <- private$cache$get(cache_key)
      if (!is.null(cached)) {
        return(cached)
      }

      private$logger$info(paste("Fetching repo:", owner, "/", repo))
      endpoint <- paste0("repos/", owner, "/", repo)
      response <- private$request(endpoint)

      if (is.null(response$error)) {
        private$cache$set(cache_key, response, ttl = private$cache_ttl)
      }

      response
    },

    #' @description Get repository README
    #' @param owner Repository owner
    #' @param repo Repository name
    #' @return README content
    get_readme = function(owner, repo) {
      cache_key <- paste0("github_readme_", owner, "_", repo)

      cached <- private$cache$get(cache_key)
      if (!is.null(cached)) {
        return(cached)
      }

      endpoint <- paste0("repos/", owner, "/", repo, "/readme")
      response <- private$request(endpoint)

      if (!is.null(response$content)) {
        # Decode base64 content
        content <- rawToChar(base64enc::base64decode(response$content))
        private$cache$set(cache_key, content, ttl = private$cache_ttl)
        return(content)
      }

      response
    },

    #' @description Get repository commits
    #' @param owner Repository owner
    #' @param repo Repository name
    #' @param per_page Number of commits
    #' @return List of commits
    get_commits = function(owner, repo, per_page = 10) {
      endpoint <- paste0("repos/", owner, "/", repo, "/commits?per_page=", per_page)
      private$request(endpoint)
    },

    #' @description Check repository health
    #' @param owner Repository owner
    #' @param repo Repository name
    #' @return Health metrics
    check_health = function(owner, repo) {
      repo_data <- self$get_repo(owner, repo)

      if (!is.null(repo_data$error)) {
        return(list(
          exists = FALSE,
          error = repo_data$error
        ))
      }

      commits <- self$get_commits(owner, repo, per_page = 1)
      last_commit <- if (length(commits) > 0) commits[[1]]$commit$author$date else NA

      readme <- self$get_readme(owner, repo)

      list(
        exists = TRUE,
        has_readme = !is.null(readme) && !is.list(readme),
        has_description = !is.null(repo_data$description) && nchar(repo_data$description) > 0,
        is_active = !is.na(last_commit) &&
          lubridate::as_datetime(last_commit) > (Sys.time() - lubridate::days(90)),
        last_updated = repo_data$updated_at,
        last_commit = last_commit,
        stars = repo_data$stargazers_count,
        open_issues = repo_data$open_issues_count
      )
    },

    #' @description Extract owner and repo from URL
    #' @param url GitHub URL
    #' @return List with owner and repo
    parse_repo_url = function(url) {
      # Extract owner/repo from various GitHub URL formats
      pattern <- "github\\.com[:/]([^/]+)/([^/\\.]+)"
      matches <- stringr::str_match(url, pattern)

      if (is.na(matches[1])) {
        return(NULL)
      }

      list(
        owner = matches[2],
        repo = matches[3]
      )
    },

    #' @description Calculate compliance score based on repo health
    #' @param health_data Health metrics from check_health
    #' @return Compliance score (0-100)
    calculate_compliance_score = function(health_data) {
      if (!health_data$exists) {
        return(0)
      }

      score <- 0

      # Repository exists: 40 points
      score <- score + 40

      # Has README: 20 points
      if (health_data$has_readme) {
        score <- score + 20
      }

      # Has description: 10 points
      if (health_data$has_description) {
        score <- score + 10
      }

      # Is active (committed in last 90 days): 30 points
      if (health_data$is_active) {
        score <- score + 30
      }

      score
    },

    #' @description Clear cache
    clear_cache = function() {
      private$cache$reset()
      private$logger$info("GitHub API cache cleared")
    }
  )
)
