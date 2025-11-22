#!/usr/bin/env Rscript

# Clean Install Script for PHS Governance Dashboard
# Removes corrupted installation and reinstalls fresh

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   PHS Governance Dashboard - Clean Installation           ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Step 1: Remove existing installation
cat("Step 1: Removing existing installation...\n")
tryCatch({
  if ("phsgovernance" %in% rownames(installed.packages())) {
    remove.packages("phsgovernance")
    cat("✅ Existing package removed\n\n")
  } else {
    cat("ℹ️  No existing installation found\n\n")
  }
}, error = function(e) {
  cat("⚠️  Warning during removal:", e$message, "\n\n")
})

# Step 2: Clean R session
cat("Step 2: Cleaning R session...\n")
tryCatch({
  # Unload package if loaded
  if ("package:phsgovernance" %in% search()) {
    detach("package:phsgovernance", unload = TRUE, force = TRUE)
  }
  # Clear namespace cache
  unloadNamespace("phsgovernance")
  cat("✅ Session cleaned\n\n")
}, error = function(e) {
  cat("ℹ️  Nothing to unload\n\n")
})

# Step 3: Install required dependencies
cat("Step 3: Installing/checking dependencies...\n")
required_packages <- c(
  "devtools", "roxygen2", "shiny", "golem", "config",
  "bslib", "bsicons", "DBI", "pool", "RPostgres",
  "httr2", "jsonlite", "dplyr", "tidyr", "tibble",
  "purrr", "lubridate", "stringr", "magrittr",
  "base64enc", "digest", "htmlwidgets", "DT",
  "plotly", "shinyjs", "shinyWidgets", "R6",
  "cachem", "log4r", "glue", "rlang",
  "promises", "future", "reactable", "echarts4r", "waiter"
)

missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  cat("Installing", length(missing_packages), "missing packages...\n")
  install.packages(missing_packages, repos = "https://cloud.r-project.org/", quiet = TRUE)
  cat("✅ Dependencies installed\n\n")
} else {
  cat("✅ All dependencies already installed\n\n")
}

# Step 4: Document and install package
cat("Step 4: Documenting package...\n")
tryCatch({
  roxygen2::roxygenize(clean = TRUE)
  cat("✅ Documentation updated\n\n")
}, error = function(e) {
  cat("⚠️  Documentation warning:", e$message, "\n\n")
})

cat("Step 5: Installing package...\n")
devtools::install(
  upgrade = "never",
  quiet = FALSE,
  build = TRUE,
  force = TRUE
)

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   ✅ Installation Complete!                                ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")
cat("To run the app in demo mode:\n")
cat("  Rscript run_demo.R\n")
cat("\n")
cat("Or in R console:\n")
cat("  library(phsgovernance)\n")
cat("  Sys.setenv(DEMO_MODE = 'true')\n")
cat("  run_app()\n")
cat("\n")
