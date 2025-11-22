#!/usr/bin/env Rscript

# Rebuild package documentation and check for issues
cat("Updating package documentation...\n")
roxygen2::roxygenize()

cat("\nChecking package...\n")
devtools::check(document = FALSE, args = c('--no-manual', '--no-tests'))

cat("\nPackage rebuild complete!\n")
