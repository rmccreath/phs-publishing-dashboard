#!/usr/bin/env Rscript
#' Quick Demo Mode Launcher
#'
#' This script sets up the environment and runs the app in demo mode

cat("===== Starting PHS Governance Dashboard (Demo Mode) =====\n\n")

# Set demo mode
Sys.setenv(DEMO_MODE = "true")
cat("✓ Demo mode enabled\n")

# Check if package is installed
if (!"phsgovernance" %in% rownames(installed.packages())) {
  cat("\n✗ Package not installed. Please run clean_reinstall.R first.\n")
  cat("\nTo install:\n")
  cat("  source('clean_reinstall.R')\n\n")
  quit(status = 1)
}

# Load package
cat("✓ Loading phsgovernance package...\n")
library(phsgovernance)

# Verify demo mode
demo_mode_check <- is_demo_mode()
cat("✓ Demo mode check:", demo_mode_check, "\n")

if (!demo_mode_check) {
  cat("\n⚠ Warning: is_demo_mode() returned FALSE\n")
  cat("  Current DEMO_MODE value:", Sys.getenv("DEMO_MODE"), "\n")
}

# Check if demo data functions exist
cat("\n✓ Checking demo data functions...\n")
if (exists("generate_sample_dashboards", mode = "function")) {
  cat("  ✓ generate_sample_dashboards() available\n")
  
  # Test data generation
  test_data <- generate_sample_dashboards()
  cat("  ✓ Generated", nrow(test_data), "sample products\n")
} else {
  cat("  ✗ generate_sample_dashboards() not found\n")
}

if (exists("MockDashboardRepository")) {
  cat("  ✓ MockDashboardRepository class available\n")
  
  # Test repository
  test_repo <- MockDashboardRepository$new()
  repo_data <- test_repo$get_all()
  cat("  ✓ Repository initialized with", nrow(repo_data), "products\n")
} else {
  cat("  ✗ MockDashboardRepository not found\n")
}

cat("\n===== Launching Application =====\n\n")

# Run the app
phsgovernance::run_app()
