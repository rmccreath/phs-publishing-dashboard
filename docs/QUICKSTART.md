# Quick Start Guide

This guide will help you get the PHS Dashboard Governance Hub running in under 5 minutes.

## Option 1: Demo Mode (No Database Required)

The easiest way to try the application is to use demo mode with in-memory data.

### Step 1: Install R Package

```r
# Install the package
devtools::install()
```

### Step 2: Run in Demo Mode

```r
# Load the package
library(phsgovernance)

# Set demo mode (no database required)
Sys.setenv(DEMO_MODE = "true")

# Run the app
run_app()
```

The app will open in your browser at `http://localhost:3838` with sample data.

**Demo Mode Features**:
- ✅ Sample dashboards pre-loaded
- ✅ Mock compliance data
- ✅ All features accessible
- ❌ Data not persisted (resets on restart)
- ❌ API integrations disabled

---

## Option 2: Full Setup (With Database)

For production use with real data persistence.

### Prerequisites

- R >= 4.3.0
- PostgreSQL >= 14
- Git

### Step 1: Set Up Database

```bash
# Create PostgreSQL database
createdb phs_governance

# Initialize schema
psql -d phs_governance -f inst/config/schema.sql
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .Renviron.example .Renviron

# Edit .Renviron with your credentials
# Required: DB_PASSWORD
# Optional: CONNECT_SERVER, CONNECT_API_KEY, GITHUB_TOKEN
```

Minimal `.Renviron` for local development:

```
R_CONFIG_ACTIVE=development
DB_PASSWORD=your_password_here
```

### Step 3: Install Package

```r
# Install dependencies and package
devtools::install()
```

### Step 4: Run Application

```r
library(phsgovernance)
run_app()
```

---

## Troubleshooting

### "Could not connect to database"

**Solution**: Use demo mode or check your database credentials:

```r
# Test database connection
library(DBI)
con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "phs_governance",
  host = "localhost",
  user = "postgres",
  password = Sys.getenv("DB_PASSWORD")
)
dbDisconnect(con)
```

### "Package installation failed"

**Solution**: Clean and reinstall:

```r
# Remove old installation
remove.packages("phsgovernance")

# Clean build artifacts
unlink("R/*.rdb", recursive = TRUE)
unlink("R/*.rdx", recursive = TRUE)

# Reinstall
devtools::install()
```

### "Could not find function 'run_app'"

**Solution**: Load the package first:

```r
library(phsgovernance)
run_app()
```

---

## Next Steps

1. **Explore the UI**: Navigate through Registry, Approvals, Compliance, and Analytics tabs
2. **Add API Keys**: Configure Posit Connect and GitHub tokens in `.Renviron`
3. **Sync Dashboards**: Use "Sync from APIs" button to import real dashboards
4. **Review Documentation**: Check `docs/` folder for detailed guides

## Need Help?

- **Documentation**: See `docs/` folder
- **Issues**: https://github.com/Public-Health-Scotland/phs-publishing-dashboard/issues
- **Email**: governance@phs.scot
