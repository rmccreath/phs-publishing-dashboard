#!/usr/bin/env Rscript

# PHS Dashboard Governance Hub - Clean Installation Script
#
# This script performs a clean installation of the package,
# removing any corrupt files first.

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   PHS Dashboard Governance Hub - Clean Install            ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Step 1: Remove old installation
cat("🧹 Step 1: Cleaning old installation...\n")
tryCatch({
  remove.packages("phsgovernance")
  cat("  ✓ Removed old package\n")
}, error = function(e) {
  cat("  ℹ️  No previous installation found\n")
})

# Step 2: Clean build artifacts
cat("\n🧹 Step 2: Cleaning build artifacts...\n")
unlink("R/*.rdb", recursive = TRUE)
unlink("R/*.rdx", recursive = TRUE)
cat("  ✓ Cleaned .rdb and .rdx files\n")

# Step 3: Install devtools if needed
cat("\n📦 Step 3: Checking dependencies...\n")
if (!requireNamespace("devtools", quietly = TRUE)) {
  cat("  Installing devtools...\n")
  install.packages("devtools")
}
cat("  ✓ devtools available\n")

# Step 4: Install package
cat("\n📦 Step 4: Installing phsgovernance package...\n")
cat("  This may take a few minutes...\n\n")

devtools::install(
  dependencies = TRUE,
  upgrade = "ask",
  quiet = FALSE
)

cat("\n")
cat("✅ Installation complete!\n")
cat("\n")
cat("Next steps:\n")
cat("  1. To run in DEMO mode (no database):\n")
cat("     Rscript run_demo.R\n")
cat("\n")
cat("  2. To run in R console:\n")
cat("     library(phsgovernance)\n")
cat("     Sys.setenv(DEMO_MODE = \"true\")\n")
cat("     run_app()\n")
cat("\n")
