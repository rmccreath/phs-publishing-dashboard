#!/usr/bin/env Rscript
#' Quick Fix for Corrupt Package
#'
#' Fast script to fix package corruption without full reinstall

cat("===== Quick Package Fix =====\n\n")

# Step 1: Force unload
cat("1. Force unloading package...\n")
pkgload::unload("phsgovernance")
cat("   ✓ Unloaded\n")

# Step 2: Re-document
cat("\n2. Regenerating documentation...\n")
roxygen2::roxygenize(clean = TRUE)
cat("   ✓ Documentation regenerated\n")

# Step 3: Quick install
cat("\n3. Installing package...\n")
devtools::install(upgrade = "never", reload = TRUE, force = TRUE)
cat("   ✓ Installed\n")

# Step 4: Test load
cat("\n4. Testing package load...\n")
library(phsgovernance)
cat("   ✓ Package loaded successfully\n")

cat("\n===== DONE =====\n")
cat("\nTo run in demo mode:\n")
cat("  source('run_demo.R')\n\n")
