# Getting Started with PHS Governance Dashboard

## Quick Start (Demo Mode)

The easiest way to run the application is in **demo mode** with sample data:

```r
# Run the demo launcher
Rscript run_demo.R
```

This will:
- ✅ Automatically install the package if needed
- ✅ Generate 30 realistic sample dashboards
- ✅ Create 15 approval requests with various statuses
- ✅ Enable all features with mock data
- ✅ Launch the app in your browser

## What Was Fixed

### Issue 1: Config File Errors
**Problem:** App crashed with "Config file config.yml not found" errors

**Solution:**
- Created `R/utils_config.R` with safe config loading
- All services now gracefully handle missing config files
- App works perfectly in demo mode without any configuration

### Issue 2: Pipe Operator Error
**Problem:** Error "could not find function '%>%'"

**Solution:**
- Created `R/utils_pipe.R` to properly import operators
- Added missing packages to DESCRIPTION:
  - `magrittr` - provides `%>%` pipe operator
  - `tibble` - data frame creation
  - `stringr` - string manipulation
  - `base64enc` - base64 encoding
  - `digest` - cryptographic hashing
- Updated NAMESPACE with proper imports

## Features Available in Demo Mode

### Dashboard Registry
- View 30 pre-loaded sample dashboards
- Filter by status, platform, team
- Add new dashboards (stored in memory)
- Sync from APIs (gracefully disabled in demo mode)

### Approval Workflow
- 15 sample approval requests
- Submit new approvals
- Review and approve requests
- Three-stage sign-off tracking

### Compliance Tracker
- Mock compliance scores across 5 metrics
- Trend analysis and charts
- Grade distribution

### Analytics & Reporting
- Dashboard count by platform
- Status distribution
- Deployment trends over time

## Running in Production Mode

For production use with a real database:

1. **Set up PostgreSQL database:**
   ```bash
   psql -f inst/config/schema.sql
   ```

2. **Configure API credentials** in `inst/config/config.yml`:
   - Posit Connect API
   - GitHub token
   - ShinyApps.io credentials

3. **Set environment variable:**
   ```r
   Sys.setenv(DEMO_MODE = "false")
   ```

4. **Run the app:**
   ```r
   library(phsgovernance)
   run_app()
   ```

## Troubleshooting

### Package Installation Issues
If you get installation errors, try:
```r
# Install dependencies first
install.packages(c("shiny", "golem", "magrittr", "tibble", "dplyr",
                   "tidyr", "purrr", "lubridate", "stringr"))

# Then install the package
devtools::install()
```

### Data Not Showing
The app needs demo data to be generated first:
```r
source("generate_demo_data.R")
```

### API Warnings
In demo mode, you'll see warnings like:
- "Posit Connect credentials not configured"
- "GitHub token not configured"
- "ShinyApps.io credentials not configured"

These are **normal and expected** in demo mode. The app will work fine with mock data repositories.

## File Structure

```
phsgovernance/
├── R/
│   ├── app_*.R           # Main app files
│   ├── mod_*.R           # Shiny modules
│   ├── svc_*.R           # API service classes
│   ├── utils_*.R         # Utility functions
│   └── fct_*.R           # Business logic functions
├── inst/
│   ├── config/           # Configuration files
│   │   ├── config.yml    # (optional in demo mode)
│   │   └── schema.sql    # Database schema
│   └── demo_data/        # Generated demo data (RDS files)
├── run_demo.R            # Demo launcher
├── generate_demo_data.R  # Demo data generator
└── DESCRIPTION           # Package metadata
```

## Next Steps

1. **Explore the demo:** Run `Rscript run_demo.R` to see all features
2. **Review the code:** Check out the modular structure in `R/`
3. **Set up production:** Follow the production setup steps above
4. **Customize:** Modify themes, add features, integrate with your systems

## Support

For issues or questions:
- Check the logs in the R console
- Review error messages in the app notifications
- Ensure all dependencies are installed
- Try regenerating demo data if needed
