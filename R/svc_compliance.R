#' Compliance Service
#'
#' @description R6 class for compliance checking and scoring
#' @export
ComplianceService <- R6::R6Class(
  "ComplianceService",
  private = list(
    config = NULL,
    github_service = NULL,
    logger = NULL,

    # Calculate grade from score
    # @param score Overall score
    # @return Grade string
    calculate_grade = function(score) {
      thresholds <- private$config$compliance$thresholds

      if (score >= thresholds$excellent) {
        return("excellent")
      } else if (score >= thresholds$good) {
        return("good")
      } else if (score >= thresholds$acceptable) {
        return("acceptable")
      } else {
        return("poor")
      }
    }
  ),

  public = list(
    #' @description Initialize service
    #' @param github_service GitHub service instance
    initialize = function(github_service) {
      private$config <- safe_get_config()
      private$github_service <- github_service
      private$logger <- log4r::logger()
    },

    #' @description Check accessibility compliance
    #' @param dashboard_data Dashboard information
    #' @return List with score and notes
    check_accessibility = function(dashboard_data) {
      score <- 0
      notes <- character()

      # Check for accessibility statement in metadata
      metadata <- dashboard_data$metadata
      if (!is.null(metadata$accessibility_statement)) {
        score <- score + 50
        notes <- c(notes, "Accessibility statement present")
      } else {
        notes <- c(notes, "No accessibility statement found")
      }

      # Check for WCAG compliance claim
      if (!is.null(metadata$wcag_level)) {
        if (metadata$wcag_level == "AA") {
          score <- score + 50
          notes <- c(notes, "WCAG 2.1 AA compliance claimed")
        } else if (metadata$wcag_level == "A") {
          score <- score + 30
          notes <- c(notes, "WCAG 2.1 A compliance claimed")
        }
      } else {
        notes <- c(notes, "No WCAG compliance level specified")
      }

      list(
        score = score,
        notes = paste(notes, collapse = "; "),
        wcag_level = metadata$wcag_level %||% NA_character_
      )
    },

    #' @description Check documentation compliance
    #' @param dashboard_data Dashboard information
    #' @return List with score and notes
    check_documentation = function(dashboard_data) {
      score <- 0
      notes <- character()

      # Check for documentation URL
      if (!is.na(dashboard_data$documentation_url) &&
          nchar(dashboard_data$documentation_url) > 0) {
        score <- score + 40
        notes <- c(notes, "Documentation URL provided")
      } else {
        notes <- c(notes, "No documentation URL")
      }

      # Check for README in repository
      if (!is.na(dashboard_data$repository_url)) {
        repo_info <- private$github_service$parse_repo_url(dashboard_data$repository_url)
        if (!is.null(repo_info)) {
          health <- private$github_service$check_health(repo_info$owner, repo_info$repo)
          if (health$has_readme) {
            score <- score + 40
            notes <- c(notes, "README file present in repository")
          } else {
            notes <- c(notes, "No README file in repository")
          }

          if (health$has_description) {
            score <- score + 20
            notes <- c(notes, "Repository description present")
          }
        }
      }

      list(
        score = score,
        notes = paste(notes, collapse = "; "),
        complete = score >= 60
      )
    },

    #' @description Check repository compliance
    #' @param dashboard_data Dashboard information
    #' @return List with score and notes
    check_repository = function(dashboard_data) {
      score <- 0
      notes <- character()

      if (is.na(dashboard_data$repository_url) ||
          nchar(dashboard_data$repository_url) == 0) {
        return(list(
          score = 0,
          notes = "No repository linked",
          linked = FALSE,
          active = FALSE
        ))
      }

      # Repository URL exists
      score <- score + 40
      notes <- c(notes, "Repository URL provided")

      # Check repository health
      repo_info <- private$github_service$parse_repo_url(dashboard_data$repository_url)
      if (!is.null(repo_info)) {
        health <- private$github_service$check_health(repo_info$owner, repo_info$repo)

        if (health$exists) {
          score <- score + 30
          notes <- c(notes, "Repository accessible")

          if (health$is_active) {
            score <- score + 30
            notes <- c(notes, "Repository actively maintained")
          } else {
            notes <- c(notes, "Repository not recently updated")
          }
        } else {
          notes <- c(notes, "Repository not accessible")
        }

        list(
          score = score,
          notes = paste(notes, collapse = "; "),
          linked = TRUE,
          active = health$is_active %||% FALSE
        )
      } else {
        notes <- c(notes, "Invalid repository URL format")
        list(
          score = score,
          notes = paste(notes, collapse = "; "),
          linked = TRUE,
          active = FALSE
        )
      }
    },

    #' @description Check testing compliance
    #' @param dashboard_data Dashboard information
    #' @return List with score and notes
    check_testing = function(dashboard_data) {
      score <- 0
      notes <- character()

      metadata <- dashboard_data$metadata

      # Check for testing information in metadata
      if (!is.null(metadata$has_tests)) {
        if (metadata$has_tests) {
          score <- score + 50
          notes <- c(notes, "Tests present")

          if (!is.null(metadata$test_coverage)) {
            coverage <- as.numeric(metadata$test_coverage)
            if (coverage >= 80) {
              score <- score + 50
              notes <- c(notes, paste("Excellent test coverage:", coverage, "%"))
            } else if (coverage >= 60) {
              score <- score + 30
              notes <- c(notes, paste("Good test coverage:", coverage, "%"))
            } else {
              score <- score + 10
              notes <- c(notes, paste("Low test coverage:", coverage, "%"))
            }
          } else {
            score <- score + 20
            notes <- c(notes, "Test coverage not specified")
          }
        } else {
          notes <- c(notes, "No tests present")
        }
      } else {
        notes <- c(notes, "Testing information not provided")
      }

      list(
        score = score,
        notes = paste(notes, collapse = "; "),
        coverage = metadata$test_coverage %||% NA_real_
      )
    },

    #' @description Check security compliance
    #' @param dashboard_data Dashboard information
    #' @return List with score and notes
    check_security = function(dashboard_data) {
      score <- 100  # Start with full score, deduct for issues
      notes <- character()
      vulnerabilities <- 0

      metadata <- dashboard_data$metadata

      # Check for security review
      if (!is.null(metadata$security_reviewed)) {
        if (metadata$security_reviewed) {
          notes <- c(notes, "Security review completed")
        } else {
          score <- score - 30
          notes <- c(notes, "No security review")
        }
      } else {
        score <- score - 20
        notes <- c(notes, "Security review status unknown")
      }

      # Check for known vulnerabilities
      if (!is.null(metadata$vulnerabilities)) {
        vulnerabilities <- as.integer(metadata$vulnerabilities)
        if (vulnerabilities > 0) {
          score <- score - (vulnerabilities * 10)
          notes <- c(notes, paste(vulnerabilities, "known vulnerabilities"))
        } else {
          notes <- c(notes, "No known vulnerabilities")
        }
      }

      # Check for data protection
      if (!is.null(metadata$handles_personal_data)) {
        if (metadata$handles_personal_data) {
          if (!is.null(metadata$data_protection_impact_assessment)) {
            notes <- c(notes, "DPIA completed")
          } else {
            score <- score - 20
            notes <- c(notes, "Handles personal data but no DPIA")
          }
        }
      }

      list(
        score = max(0, score),  # Don't go below 0
        notes = paste(notes, collapse = "; "),
        vulnerabilities = vulnerabilities
      )
    },

    #' @description Perform full compliance check
    #' @param dashboard_data Dashboard information
    #' @return Complete compliance check data
    perform_check = function(dashboard_data) {
      private$logger$info(paste("Performing compliance check for:", dashboard_data$name))

      # Perform individual checks
      accessibility <- self$check_accessibility(dashboard_data)
      documentation <- self$check_documentation(dashboard_data)
      repository <- self$check_repository(dashboard_data)
      testing <- self$check_testing(dashboard_data)
      security <- self$check_security(dashboard_data)

      # Get metric weights
      weights <- private$config$compliance$metrics

      # Calculate overall score
      overall_score <- (
        accessibility$score * weights$accessibility$weight +
        documentation$score * weights$documentation$weight +
        repository$score * weights$repository$weight +
        testing$score * weights$testing$weight +
        security$score * weights$security$weight
      )

      # Determine if compliant (all required metrics must meet threshold)
      compliant <- TRUE
      if (weights$accessibility$required && accessibility$score < 60) compliant <- FALSE
      if (weights$documentation$required && documentation$score < 60) compliant <- FALSE
      if (weights$repository$required && repository$score < 60) compliant <- FALSE
      if (weights$security$required && security$score < 60) compliant <- FALSE

      grade <- private$calculate_grade(overall_score)

      list(
        dashboard_id = dashboard_data$dashboard_id,
        accessibility_score = accessibility$score,
        accessibility_notes = accessibility$notes,
        accessibility_wcag_level = accessibility$wcag_level,
        documentation_score = documentation$score,
        documentation_notes = documentation$notes,
        documentation_complete = documentation$complete,
        repository_score = repository$score,
        repository_notes = repository$notes,
        repository_linked = repository$linked,
        repository_active = repository$active,
        testing_score = testing$score,
        testing_notes = testing$notes,
        testing_coverage = testing$coverage,
        security_score = security$score,
        security_notes = security$notes,
        security_vulnerabilities = security$vulnerabilities,
        overall_score = round(overall_score, 2),
        grade = grade,
        compliant = compliant
      )
    }
  )
)
