# Troubleshooting Guide - PHS Governance Dashboard

## Common Errors and Solutions

### Error: "lazy-load database is corrupt"

**Full Error:**
```
Error in eapply(pkgload::ns_env(pkg$package), force, all.names = TRUE) :
  lazy-load database '/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/phsgovernance/R/phsgovernance.rdb' is corrupt
```

**Cause:** The R package installation has become corrupted, usually due to:
- Interrupted installation
- Source code changes while package was loaded
- R session crash during installation
- Disk I/O issues

**Solution:**

**Option 1: Quick Fix** (Try this first)
```r
source('quick_fix.R')
```

**Option 2: Complete Clean Reinstall** (If quick fix doesn't work)
```r
source('clean_reinstall.R')
```

**Option 3: Manual Fix**
```r
# 1. Unload the package
pkgload::unload("phsgovernance")

# 2. Remove the package
remove.packages("phsgovernance")

# 3. Regenerate documentation
roxygen2::roxygenize(clean = TRUE)

# 4. Reinstall
devtools::install(upgrade = "never", force = TRUE, reload = TRUE)

# 5. Test
library(phsgovernance)
```

---

### Error: Products Not Loading / Empty Product List

**Symptoms:**
- Product list shows "30 products" but displays none
- All counts show 0
- Empty tables

**Cause:** Demo mode not enabled or demo data not initializing

**Solution:**

**Check demo mode is enabled:**
```r
# In R console BEFORE loading package:
Sys.setenv(DEMO_MODE = "true")
library(phsgovernance)

# Verify it's set:
is_demo_mode()  # Should return TRUE
```

**Check demo data generation:**
```r
# Test data generation
test_data <- generate_sample_dashboards()
nrow(test_data)  # Should be 25

# Test repository
repo <- MockDashboardRepository$new()
all_products <- repo$get_all()
nrow(all_products)  # Should be 25
```

**Run using the demo launcher:**
```r
source('run_demo.R')
```

---

### Error: Functions Not Found (e.g., MockDashboardRepository)

**Symptoms:**
```
Error: object 'MockDashboardRepository' not found
Error: could not find function "generate_sample_dashboards"
```

**Cause:** Package not properly exported or not installed

**Solution:**

1. **Regenerate NAMESPACE:**
```r
roxygen2::roxygenize(clean = TRUE)
```

2. **Check NAMESPACE file** should include:
```
export(MockApprovalRepository)
export(MockComplianceRepository)
export(MockDashboardRepository)
export(generate_sample_approvals)
export(generate_sample_dashboards)
export(is_demo_mode)
```

3. **Reinstall:**
```r
devtools::install(upgrade = "never", force = TRUE)
```

---

### Error: Shiny Router Not Working / Page Not Found

**Symptoms:**
- Clicking links does nothing
- URLs don't change
- "Page not found" errors

**Cause:** shiny.router package issues or route definitions

**Solution:**

1. **Check shiny.router is installed:**
```r
if (!"shiny.router" %in% installed.packages()) {
  install.packages("shiny.router")
}
```

2. **Clear browser cache and refresh**

3. **Check console for JavaScript errors** (F12 in browser)

---

### Error: Filter Errors in Product List

**Symptoms:**
```
Error: In argument: lifecycle_stage == input$filter_stage
```

**Cause:** NSE (Non-Standard Evaluation) scoping issues in dplyr

**Solution:** This should be fixed in the latest version. If still occurring:

1. **Pull latest changes:**
```bash
git pull origin claude/governance-dashboard-shiny-018ziowKUd4d3kveyCVzvnnW
```

2. **Reinstall:**
```r
source('clean_reinstall.R')
```

---

### Error: Database Connection Issues (Not in Demo Mode)

**Symptoms:**
```
Database connection not available
Error connecting to PostgreSQL
```

**Cause:** Trying to run without database in production mode

**Solution:**

**Either:**

**A. Use Demo Mode** (Recommended for development):
```r
Sys.setenv(DEMO_MODE = "true")
phsgovernance::run_app()
```

**B. Set up Database:**
1. Create PostgreSQL database
2. Create `.Renviron` file with:
```
DEMO_MODE=false
DB_HOST=localhost
DB_PORT=5432
DB_NAME=phsgovernance
DB_USER=your_user
DB_PASSWORD=your_password
```

---

## Installation Workflows

### Fresh Installation

```r
# 1. Install dependencies
required <- c("devtools", "roxygen2", "shiny", "bslib",
              "golem", "shiny.router", "DT", "dplyr",
              "tibble", "R6", "magrittr", "purrr")
install.packages(required)

# 2. Clean install
source('clean_reinstall.R')

# 3. Run demo
source('run_demo.R')
```

### After Git Pull

```r
# Quick fix after pulling changes
source('quick_fix.R')

# Then run
source('run_demo.R')
```

### After Code Changes

```r
# If you've edited R files:
pkgload::load_all()  # For testing during development

# OR for full install:
roxygen2::roxygenize()
devtools::install()
```

---

## Running the Application

### Method 1: Demo Launcher (Recommended)
```r
source('run_demo.R')
```

### Method 2: Manual
```r
# Set demo mode
Sys.setenv(DEMO_MODE = "true")

# Load package
library(phsgovernance)

# Run app
run_app()
```

### Method 3: During Development
```r
# Load without installing
pkgload::load_all()

# Set demo mode
Sys.setenv(DEMO_MODE = "true")

# Run
run_app()
```

---

## Verification Checklist

After installation, verify everything works:

```r
# 1. Package loads
library(phsgovernance)
# ✓ No errors

# 2. Demo mode check
is_demo_mode()
# ✓ Should return TRUE (if DEMO_MODE=true)

# 3. Data generation
test_data <- generate_sample_dashboards()
nrow(test_data)
# ✓ Should return 25

# 4. Repository works
repo <- MockDashboardRepository$new()
products <- repo$get_all()
nrow(products)
# ✓ Should return 25

# 5. App runs
run_app()
# ✓ Should launch browser with dashboard
# ✓ Should see "Demo Mode Active" notification
# ✓ Should see 25 products in product list
```

---

## Getting Help

If none of these solutions work:

1. **Check R version:** `R.version.string`
   - Minimum required: R 4.1.0

2. **Check package versions:**
```r
packageVersion("shiny")      # >= 1.7.0
packageVersion("bslib")      # >= 0.5.0
packageVersion("shiny.router") # >= 0.3.0
```

3. **Check for conflicts:**
```r
conflicts()
```

4. **Session info:**
```r
sessionInfo()
```

5. **Create an issue** with:
   - Full error message
   - Session info
   - Steps to reproduce
