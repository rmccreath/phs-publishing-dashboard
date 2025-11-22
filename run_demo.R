#!/usr/bin/env Rscript

# PHS Dashboard Governance Hub - Demo Mode Launcher
#
# This script runs the application in demo mode with sample data.
# No database or API credentials required!

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   PHS Dashboard Governance Hub - DEMO MODE                ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Check if package is installed and not corrupted
needs_install <- FALSE
if (!requireNamespace("phsgovernance", quietly = TRUE)) {
  cat("📦 Package not installed. Installing now...\n\n")
  needs_install <- TRUE
} else {
  # Check for corruption
  test_load <- tryCatch({
    loadNamespace("phsgovernance")
    TRUE
  }, error = function(e) {
    if (grepl("corrupt|internal error", e$message, ignore.case = TRUE)) {
      cat("⚠️  Package installation is corrupted. Reinstalling...\n\n")
      TRUE
    } else {
      FALSE
    }
  })

  if (test_load == TRUE && grepl("corrupt", test_load, ignore.case = TRUE)) {
    needs_install <- TRUE
  }
}

if (needs_install) {
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }

  # Use clean install if corruption detected
  if (file.exists("clean_install.R")) {
    cat("Using clean installation process...\n")
    source("clean_install.R")
  } else {
    devtools::install(quiet = FALSE, upgrade = "never", force = TRUE)
  }
  cat("✅ Installation complete!\n\n")
}

# Set demo mode
Sys.setenv(DEMO_MODE = "true")

# Check if demo data exists, generate if not
demo_data_dir <- "inst/demo_data"
dashboards_file <- file.path(demo_data_dir, "dashboards.rds")

if (!file.exists(dashboards_file)) {
  cat("📊 Generating comprehensive demo data...\n")
  cat("   This will create realistic sample dashboards and approvals.\n\n")

  if (file.exists("generate_demo_data.R")) {
    source("generate_demo_data.R")
  } else {
    cat("   ⚠️  Demo data generator not found. Using basic sample data.\n\n")
  }
}

cat("🚀 Starting application in DEMO MODE...\n")
cat("\n")
cat("Features:\n")
cat("  ✅ 30 sample dashboards pre-loaded\n")
cat("  ✅ 15 approval requests (various statuses)\n")
cat("  ✅ Mock compliance scores and analytics\n")
cat("  ✅ All features fully functional\n")
cat("  ℹ️  Data not persisted (resets on restart)\n")
cat("  ℹ️  API integrations disabled\n")
cat("\n")
cat("The app will open in your browser shortly...\n")
cat("\n")

# Load and run the app
library(phsgovernance)
run_app()
