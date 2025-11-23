#!/usr/bin/env Rscript
#' Complete Clean Reinstall Script
#'
#' This script completely removes and reinstalls the phsgovernance package
#' to fix corruption issues.

cat("===== PHS Governance Package Clean Reinstall =====\n\n")

# Step 1: Detach and unload the package
cat("Step 1: Unloading phsgovernance package...\n")
if ("package:phsgovernance" %in% search()) {
  detach("package:phsgovernance", unload = TRUE)
  cat("  ✓ Package detached\n")
}

if ("phsgovernance" %in% loadedNamespaces()) {
  try(unloadNamespace("phsgovernance"), silent = TRUE)
  cat("  ✓ Namespace unloaded\n")
}

# Step 2: Remove installed package
cat("\nStep 2: Removing installed package...\n")
if ("phsgovernance" %in% rownames(installed.packages())) {
  remove.packages("phsgovernance")
  cat("  ✓ Package removed\n")
} else {
  cat("  ! Package not currently installed\n")
}

# Step 3: Clean package cache and temporary files
cat("\nStep 3: Cleaning cache and temporary files...\n")
lib_paths <- .libPaths()
for (lib_path in lib_paths) {
  pkg_path <- file.path(lib_path, "phsgovernance")
  if (dir.exists(pkg_path)) {
    unlink(pkg_path, recursive = TRUE, force = TRUE)
    cat("  ✓ Removed:", pkg_path, "\n")
  }
}

# Clean R session temporary files
tmp_files <- list.files(tempdir(), pattern = "phsgovernance", full.names = TRUE)
if (length(tmp_files) > 0) {
  unlink(tmp_files, recursive = TRUE)
  cat("  ✓ Cleaned temporary files\n")
}

# Step 4: Check and install required dependencies
cat("\nStep 4: Checking dependencies...\n")
required_packages <- c(
  "devtools",
  "roxygen2",
  "shiny",
  "bslib",
  "bsicons",
  "golem",
  "shiny.router",
  "DT",
  "dplyr",
  "tibble",
  "R6",
  "pool",
  "config",
  "httr2",
  "magrittr",
  "rlang",
  "purrr",
  "stringr",
  "base64enc",
  "digest",
  "htmlwidgets",
  "waiter"
)

missing_packages <- required_packages[!required_packages %in% rownames(installed.packages())]

if (length(missing_packages) > 0) {
  cat("  Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages, dependencies = TRUE, quiet = FALSE)
  cat("  ✓ Dependencies installed\n")
} else {
  cat("  ✓ All dependencies already installed\n")
}

# Step 5: Clean build artifacts in source directory
cat("\nStep 5: Cleaning build artifacts...\n")
if (file.exists("NAMESPACE")) {
  cat("  Cleaning NAMESPACE...\n")
}
artifacts <- c("src/*.o", "src/*.so", "src/*.dll")
for (pattern in artifacts) {
  files <- Sys.glob(pattern)
  if (length(files) > 0) {
    unlink(files)
    cat("  ✓ Removed build artifacts:", pattern, "\n")
  }
}

# Step 6: Generate fresh documentation
cat("\nStep 6: Generating documentation...\n")
roxygen2::roxygenize(clean = TRUE)
cat("  ✓ Documentation generated\n")

# Step 7: Install package
cat("\nStep 7: Installing package...\n")
devtools::install(
  upgrade = "never",
  quiet = FALSE,
  build = TRUE,
  force = TRUE,
  reload = TRUE
)
cat("  ✓ Package installed\n")

# Step 8: Verify installation
cat("\nStep 8: Verifying installation...\n")
if ("phsgovernance" %in% rownames(installed.packages())) {
  cat("  ✓ Package successfully installed\n")

  # Try loading the package
  library(phsgovernance)
  cat("  ✓ Package successfully loaded\n")

  # Check key functions exist
  if (exists("run_app", mode = "function")) {
    cat("  ✓ run_app() function available\n")
  }

  if (exists("MockDashboardRepository")) {
    cat("  ✓ MockDashboardRepository class available\n")
  }

  cat("\n===== SUCCESS =====\n")
  cat("\nTo run the app in demo mode:\n")
  cat("  Sys.setenv(DEMO_MODE = 'true')\n")
  cat("  phsgovernance::run_app()\n\n")

} else {
  cat("  ✗ Installation failed\n")
  cat("\nPlease check error messages above.\n")
}
