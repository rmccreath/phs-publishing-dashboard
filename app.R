# Launch the PHS Dashboard Governance Hub application
#
# This file is used to deploy the application to Posit Connect or ShinyApps.io
# For local development, you can also run this file directly

# Attach required packages
library(shiny)
library(phsgovernance)

# Run the application
phsgovernance::run_app()
