#!/usr/bin/env Rscript

# PHS Dashboard Governance Hub - Initialize Demo Data
#
# This script populates the application with comprehensive demo data
# for testing and demonstration purposes.

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║   PHS Governance Hub - Demo Data Initializer             ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n")
cat("\n")

# Load required packages
suppressPackageStartupMessages({
  library(phsgovernance)
  library(dplyr)
  library(lubridate)
})

# Enable demo mode
Sys.setenv(DEMO_MODE = "true")

cat("🎲 Generating comprehensive demo data...\n\n")

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

generate_rich_dashboards <- function(n = 30) {
  cat("  📊 Creating", n, "sample dashboards...\n")

  dashboard_names <- c(
    # COVID & Infectious Diseases
    "COVID-19 Weekly Surveillance Dashboard",
    "Vaccination Progress Tracker",
    "COVID-19 Hospital Capacity Monitor",
    "Outbreak Response Dashboard",
    "Contact Tracing Analytics",

    # Hospital & Acute Care
    "Emergency Department Performance",
    "Hospital Admissions & Discharges",
    "Waiting Times Analysis",
    "Bed Occupancy Monitor",
    "Theatre Utilization Dashboard",

    # Primary Care
    "GP Practice Performance Scorecard",
    "Primary Care Access Dashboard",
    "Prescription Analytics",
    "GP Appointment Availability",
    "Chronic Disease Management Tracker",

    # Mental Health
    "Mental Health Services Monitor",
    "CAMHS Waiting Times",
    "Psychiatric Bed Occupancy",
    "Mental Health Outcomes Tracker",
    "Crisis Response Analytics",

    # Public Health
    "Population Health Indicators",
    "Health Inequalities Dashboard",
    "Screening Programme Monitor",
    "Immunisation Coverage Tracker",
    "Lifestyle & Behaviours Dashboard",

    # Quality & Safety
    "Patient Safety Incidents Monitor",
    "Clinical Quality Indicators",
    "Healthcare Associated Infections",
    "Mortality Statistics Dashboard",
    "Adverse Events Tracker"
  )

  descriptions <- c(
    "Weekly surveillance of COVID-19 cases, hospitalizations, and deaths across Scotland",
    "Real-time tracking of vaccination uptake by age group and health board",
    "Monitoring hospital capacity and ICU utilization during pandemic",
    "Tracking and visualizing outbreak investigations and response measures",
    "Analytics on contact tracing efficiency and case isolation",

    "Real-time monitoring of A&E waiting times and performance targets",
    "Daily tracking of hospital admissions, discharges, and patient flow",
    "Analysis of waiting times across specialties and treatment pathways",
    "Live bed occupancy data by ward type and health board",
    "Operating theatre scheduling efficiency and utilization rates",

    "Comprehensive performance metrics for GP practices across Scotland",
    "Monitoring patient access to primary care services",
    "Analysis of prescribing patterns, costs, and safety alerts",
    "Tracking GP appointment availability and booking patterns",
    "Monitoring of chronic disease registers and management outcomes",

    "Overview of mental health service capacity and demand",
    "Tracking waiting times for Child and Adolescent Mental Health Services",
    "Monitoring psychiatric inpatient bed availability",
    "Outcomes tracking for mental health interventions",
    "Analytics on crisis response times and pathways",

    "Key population health indicators by geography and demographics",
    "Tracking health inequalities across deprivation quintiles",
    "Monitoring uptake and outcomes of national screening programmes",
    "Immunisation coverage rates for children and at-risk groups",
    "Surveillance of diet, physical activity, smoking, and alcohol consumption",

    "Tracking and analysis of patient safety incidents",
    "Monitoring clinical quality measures across health boards",
    "Surveillance of HAIs including C.diff, MRSA, and E.coli",
    "Analysis of mortality statistics and standardized ratios",
    "Tracking of adverse events and near-miss incidents"
  )

  teams <- c("Analytics", "Intelligence", "Data Science", "Operations", "Quality", "Public Health", "Clinical Effectiveness")
  departments <- c("Digital", "Public Health", "Healthcare Quality", "Acute Services", "Primary Care")
  platforms <- c("posit_connect", "shinyapps_io", "other")
  statuses <- c("published", "approved", "draft", "pending_approval")

  tibble::tibble(
    dashboard_id = paste0("demo-", 1:n),
    external_id = paste0("ext-", sprintf("%03d", 1:n)),
    name = dashboard_names[1:n],
    description = descriptions[1:n],
    url = paste0("https://connect.phs.scot/dashboard-", sprintf("%03d", 1:n)),
    platform = sample(platforms, n, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
    type = sample(c("shiny", "rmarkdown", "quarto"), n, replace = TRUE, prob = c(0.7, 0.2, 0.1)),

    # Ownership
    owner_id = paste0("user-", sample(1:10, n, replace = TRUE)),
    owner_name = sample(c(
      "Alice Smith", "Bob Jones", "Carol White", "David Brown", "Eve Wilson",
      "Frank Taylor", "Grace Lee", "Henry Clark", "Isla Martin", "James Anderson"
    ), n, replace = TRUE),
    owner_email = paste0("user", sample(1:10, n, replace = TRUE), "@phs.scot"),
    team = sample(teams, n, replace = TRUE),
    department = sample(departments, n, replace = TRUE),

    # Status - more published dashboards, some drafts for approval workflow
    status = sample(statuses, n, replace = TRUE, prob = c(0.5, 0.2, 0.2, 0.1)),
    visibility = sample(c("public", "internal", "restricted"), n, replace = TRUE, prob = c(0.2, 0.6, 0.2)),

    # Dates
    deployment_date = as.POSIXct(Sys.Date() - days(sample(1:730, n))),
    last_updated = as.POSIXct(Sys.Date() - days(sample(1:60, n))),
    update_frequency = sample(c("real_time", "daily", "weekly", "monthly", "quarterly"), n, replace = TRUE),

    # Links - not all dashboards have repos/docs
    repository_url = ifelse(
      runif(n) > 0.2,
      paste0("https://github.com/Public-Health-Scotland/dashboard-", sprintf("%03d", 1:n)),
      NA_character_
    ),
    documentation_url = ifelse(
      runif(n) > 0.3,
      paste0("https://docs.phs.scot/dashboard-", sprintf("%03d", 1:n)),
      NA_character_
    ),

    # Metadata
    tags = I(lapply(1:n, function(x) {
      sample(c("covid", "hospital", "vaccine", "gp", "mental-health", "public-health",
               "quality", "safety", "screening", "primary-care"), sample(1:4, 1))
    })),
    keywords = I(lapply(1:n, function(x) {
      sample(c("analytics", "monitoring", "reporting", "surveillance", "outcomes"), sample(1:3, 1))
    })),
    metadata = I(lapply(1:n, function(x) {
      list(
        has_tests = runif(1) > 0.4,
        test_coverage = if (runif(1) > 0.4) round(runif(1, 40, 95), 1) else NA,
        wcag_level = sample(c("AA", "A", NA), 1, prob = c(0.5, 0.3, 0.2)),
        security_reviewed = runif(1) > 0.3,
        vulnerabilities = sample(0:3, 1, prob = c(0.7, 0.2, 0.08, 0.02)),
        handles_personal_data = runif(1) > 0.6,
        data_protection_impact_assessment = runif(1) > 0.5
      )
    })),

    # Compliance scores - vary by status
    overall_score = ifelse(
      status == "published",
      round(runif(n, 70, 98), 1),
      round(runif(n, 45, 85), 1)
    ),
    grade = case_when(
      overall_score >= 90 ~ "excellent",
      overall_score >= 75 ~ "good",
      overall_score >= 60 ~ "acceptable",
      TRUE ~ "poor"
    ),
    compliant = overall_score >= 60,
    last_compliance_check = as.POSIXct(Sys.Date() - days(sample(1:14, n))),

    # Individual metric scores
    accessibility_score = pmin(100, overall_score + rnorm(n, 0, 10)),
    documentation_score = pmin(100, overall_score + rnorm(n, -5, 12)),
    repository_score = ifelse(is.na(repository_url), runif(n, 0, 40), pmin(100, overall_score + rnorm(n, -10, 15))),
    security_score = pmin(100, overall_score + rnorm(n, 5, 8)),

    # Timestamps
    created_at = deployment_date - days(sample(7:60, n)),
    updated_at = as.POSIXct(Sys.Date() - days(sample(1:30, n)))
  )
}

generate_rich_approvals <- function(dashboards, n = 15) {
  cat("  ✅ Creating", n, "approval requests...\n")

  # Get draft and pending dashboards
  eligible_dashboards <- dashboards %>%
    filter(status %in% c("draft", "pending_approval")) %>%
    sample_n(min(n, nrow(.)))

  if (nrow(eligible_dashboards) == 0) {
    cat("  ⚠️  No draft dashboards available for approvals\n")
    return(tibble::tibble())
  }

  justifications <- c(
    "This dashboard addresses a critical gap in our monitoring capabilities and will provide real-time insights to clinical teams.",
    "Senior management have requested this dashboard to support strategic decision-making and resource allocation.",
    "Required to meet regulatory reporting requirements and improve data transparency.",
    "Will enable proactive identification of issues and support quality improvement initiatives.",
    "Requested by multiple stakeholder groups to improve service delivery and patient outcomes.",
    "Essential for monitoring key performance indicators and meeting national targets.",
    "Will consolidate multiple existing reports and reduce manual reporting burden.",
    "Supports our digital transformation strategy and promotes data-driven culture.",
    "Critical for pandemic response and public health surveillance.",
    "Enables benchmarking against national standards and identifies areas for improvement.",
    "Provides commissioners and planners with insights needed for service redesign.",
    "Required to support clinical audit and governance processes.",
    "Will improve data accessibility for frontline staff and reduce information requests.",
    "Supports our commitment to transparency and public accountability.",
    "Essential for identifying health inequalities and targeting interventions."
  )

  audiences <- c(
    "Senior Management Team and Board Members",
    "Clinical Teams and Service Managers",
    "Public Health Practitioners",
    "NHS Scotland Commissioners",
    "General Public and Media",
    "Academic Researchers and Analysts",
    "Policy Makers and Scottish Government",
    "Quality Improvement Teams",
    "Frontline Clinical Staff",
    "Patient Safety Teams",
    "Health Board Directors",
    "Local Authorities and Partners",
    "Third Sector Organizations",
    "Primary Care Networks",
    "Specialist Clinical Groups"
  )

  data_sources_list <- c(
    "NHS Scotland data warehouse, SMR01 (hospital admissions), PIS (prescribing)",
    "A&E datamart, hospital bed census, theatre management system",
    "GP IT systems, primary care data extract, QOF indicators",
    "Mental health service datasets, psychiatric admissions, CAMHS records",
    "Scottish Cancer Registry, screening programme databases",
    "Public Health Scotland surveillance systems, HPS datasets",
    "SPIRE (patient safety incidents), DATIX, adverse events reporting",
    "National Records of Scotland, mortality registrations, census data",
    "Laboratory information systems, microbiology results, infection control data",
    "COVID-19 surveillance, Test & Protect data, vaccination records"
  )

  tibble::tibble(
    approval_id = paste0("approval-", sprintf("%03d", 1:nrow(eligible_dashboards))),
    dashboard_id = eligible_dashboards$dashboard_id,
    dashboard_name = eligible_dashboards$name,

    # Submission
    submitted_by = eligible_dashboards$owner_id,
    submitted_by_name = eligible_dashboards$owner_name,
    submitted_at = as.POSIXct(Sys.Date() - days(sample(1:60, nrow(eligible_dashboards)))),

    # Justification
    business_justification = sample(justifications, nrow(eligible_dashboards), replace = TRUE),
    target_audience = sample(audiences, nrow(eligible_dashboards), replace = TRUE),
    data_sources = sample(data_sources_list, nrow(eligible_dashboards), replace = TRUE),
    update_schedule = eligible_dashboards$update_frequency,
    support_plan = paste(
      "Dashboard will be maintained by the", eligible_dashboards$team, "team.",
      "On-call support during business hours with 4-hour response SLA.",
      "Regular review scheduled quarterly with stakeholders."
    ),

    # Status - mix of statuses
    status = sample(
      c("pending", "under_review", "approved", "rejected", "requires_changes"),
      nrow(eligible_dashboards),
      replace = TRUE,
      prob = c(0.3, 0.2, 0.3, 0.1, 0.1)
    ),

    # Review (only for non-pending)
    reviewed_by = ifelse(status != "pending", paste0("user-", sample(1:3, nrow(eligible_dashboards), replace = TRUE)), NA_character_),
    reviewed_at = as.POSIXct(ifelse(
      status != "pending",
      submitted_at + days(sample(3:14, nrow(eligible_dashboards))),
      NA
    ), origin = "1970-01-01"),
    review_notes = case_when(
      status == "approved" ~ "All requirements met. Approved for publication.",
      status == "requires_changes" ~ sample(c(
        "Please add accessibility statement and WCAG compliance documentation.",
        "Repository needs README with setup instructions and architecture overview.",
        "Requires DPIA as personal data is processed. Please provide before approval.",
        "Testing evidence required. Please add unit tests and document test coverage.",
        "Documentation needs updating to reflect current functionality."
      ), nrow(eligible_dashboards), replace = TRUE),
      status == "rejected" ~ "Does not meet minimum standards for publication. Please revise and resubmit.",
      TRUE ~ NA_character_
    ),

    # Sign-offs (more likely for approved/under_review)
    governance_signoff = status %in% c("approved") | (status == "under_review" & runif(nrow(eligible_dashboards)) > 0.5),
    governance_signoff_by = ifelse(governance_signoff, "user-1", NA_character_),
    governance_signoff_at = as.POSIXct(ifelse(governance_signoff, reviewed_at + days(sample(1:3, nrow(eligible_dashboards))), NA), origin = "1970-01-01"),

    technical_signoff = status %in% c("approved") | (status == "under_review" & runif(nrow(eligible_dashboards)) > 0.6),
    technical_signoff_by = ifelse(technical_signoff, "user-2", NA_character_),
    technical_signoff_at = as.POSIXct(ifelse(technical_signoff, reviewed_at + days(sample(1:3, nrow(eligible_dashboards))), NA), origin = "1970-01-01"),

    security_signoff = status %in% c("approved") | (status == "under_review" & runif(nrow(eligible_dashboards)) > 0.4),
    security_signoff_by = ifelse(security_signoff, "user-3", NA_character_),
    security_signoff_at = as.POSIXct(ifelse(security_signoff, reviewed_at + days(sample(1:5, nrow(eligible_dashboards))), NA), origin = "1970-01-01"),

    # Metadata
    metadata = I(lapply(1:nrow(eligible_dashboards), function(x) list())),
    created_at = submitted_at,
    updated_at = ifelse(!is.na(reviewed_at), reviewed_at, submitted_at)
  )
}

# ============================================================================
# GENERATE AND SAVE DATA
# ============================================================================

# Generate dashboards
set.seed(42)  # For reproducibility
dashboards_data <- generate_rich_dashboards(30)

# Generate approvals
approvals_data <- generate_rich_approvals(dashboards_data, 15)

# Save to RDS files for demo mode
demo_data_dir <- "inst/demo_data"
if (!dir.exists(demo_data_dir)) {
  dir.create(demo_data_dir, recursive = TRUE)
}

saveRDS(dashboards_data, file.path(demo_data_dir, "dashboards.rds"))
saveRDS(approvals_data, file.path(demo_data_dir, "approvals.rds"))

cat("\n📦 Demo data saved to:", demo_data_dir, "\n")
cat("\n")
cat("Summary:\n")
cat("  • Dashboards:", nrow(dashboards_data), "\n")
cat("  • Approvals:", nrow(approvals_data), "\n")
cat("\n")
cat("Status breakdown:\n")
cat("  • Published:", sum(dashboards_data$status == "published"), "\n")
cat("  • Approved:", sum(dashboards_data$status == "approved"), "\n")
cat("  • Draft:", sum(dashboards_data$status == "draft"), "\n")
cat("  • Pending approval:", sum(dashboards_data$status == "pending_approval"), "\n")
cat("\n")
cat("✅ Demo data generation complete!\n")
cat("\n")
cat("Run the app with:\n")
cat("  Rscript run_demo.R\n")
cat("\n")
