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

# Check if package is installed
if (!requireNamespace("phsgovernance", quietly = TRUE)) {
  cat("📦 Package not installed. Installing now...\n\n")

  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }

  devtools::install(quiet = TRUE, upgrade = "never")
  cat("✅ Installation complete!\n\n")
}

# Set demo mode
Sys.setenv(DEMO_MODE = "true")

cat("🚀 Starting application in DEMO MODE...\n")
cat("\n")
cat("Features:\n")
cat("  ✅ Sample dashboards pre-loaded\n")
cat("  ✅ Mock compliance data\n")
cat("  ✅ All features accessible\n")
cat("  ℹ️  Data not persisted (resets on restart)\n")
cat("  ℹ️  API integrations disabled\n")
cat("\n")
cat("The app will open in your browser shortly...\n")
cat("\n")

# Load and run the app
library(phsgovernance)
run_app()
