# PHS Governance Dashboard - Workflow Design

## Overview

This document describes the correct workflow for information product governance, from initial approval through deployment and ongoing reviews.

## Product Lifecycle Stages

### 1. Approval (BEFORE Development)

**Purpose:** Approve new information products before development begins

**Process:**
- Development team submits approval request for a NEW product
- Product does NOT exist yet (won't appear on APIs)
- Captures:
  - Product details (name, type, description)
  - Department and team information
  - Developer assignments
  - Maintenance plan
  - Business justification
  - Support plan
  - Target audience
- Requires sign-offs:
  - Governance sign-off
  - Technical sign-off
  - Security sign-off (if needed)
- **Status:** `pending` → `approved` → `rejected`

### 2. Development (External to System)

**Purpose:** Teams build the approved product

**Process:**
- Happens OUTSIDE this system
- Teams use approved templates and standards
- Automated testing integrated (future)
- NOT tracked in governance dashboard

### 3. Audit (AFTER Development, BEFORE Deployment)

**Purpose:** Comprehensive quality check before deployment

**Process:**
- Triggered when development is complete
- **Collaborative** - multiple users contribute
- Checklist covers:
  - **Governance:** Follows PHS standards, has proper documentation
  - **Design:** UI/UX quality, branding compliance
  - **Metadata:** Proper titles, descriptions, tags
  - **Accessibility:** WCAG 2.1 AA compliance
  - **Data Quality:** Accuracy, sources documented
  - **Security:** No vulnerabilities, data protection
  - **Performance:** Load times, responsiveness
  - **Testing:** Evidence of testing provided
  - **Documentation:** README, user guide, technical docs
  - **Reproducibility:** Can be rebuilt, dependencies documented

**Key Features:**
- Checklist items assigned to different auditors
- Evidence uploads (screenshots, test reports)
- Comments and discussion per item
- Must achieve minimum score to pass
- Can request changes and re-audit

**Automation Opportunities:**
- Auto-check accessibility with automated tools
- Pull test coverage from CI/CD
- Scan dependencies for vulnerabilities
- Check documentation exists in repo

**Status:** `in_audit` → `audit_passed` → `audit_failed` → `changes_requested`

### 4. Deployment

**Purpose:** Product goes live

**Process:**
- Only products that passed audit can deploy
- Product deployed to platform (Posit Connect, ShinyApps.io, etc.)
- NOW appears on API endpoints
- System reconciles API data with approval/audit data:
  - Match by name/URL
  - Confirm details match approval
  - Flag discrepancies for review
- Maintain link between:
  - Approval record
  - Audit record
  - API data
  - Deployment metadata

**Status:** `deployed`

### 5. Ongoing Reviews

**Purpose:** Ensure products maintain quality over time

**Process:**
- Triggered by:
  - **Schedule:** Based on product type and risk
  - **Manual:** Flag for review action
  - **Automatic:** New version detected, publication date passed
- Uses **subset** of audit checklist (focus on key items)
- Frequency varies by product type:
  - **Static reports (Quarto):** Quarterly or on publication
  - **Dashboards (Shiny):** Monthly for high-traffic, quarterly for low-traffic
  - **API services:** Monthly
  - **One-off reports:** On update only

**Review Triggers:**
- Time-based: X days since last review
- Event-based: New version deployed
- Manual: User flags for review
- Usage-based: Traffic threshold exceeded

**Status:** `current` → `review_due` → `under_review` → `review_passed` → `flagged`

## Page Structure with Routing

### Main Navigation

1. **Products** (`/products`)
   - List ALL products (regardless of stage)
   - Filters: Stage, Department, Type, Status, Owner
   - Click to go to product detail page

2. **Approvals** (`/approvals`)
   - Submit new approval requests
   - Review pending approvals
   - History of all approvals

3. **Audits** (`/audits`)
   - Products awaiting audit
   - Ongoing audits (collaborative)
   - Completed audits

4. **Reviews** (`/reviews`)
   - Products due for review
   - Schedule management
   - Review history

5. **Analytics** (`/analytics`)
   - Organization-wide overview
   - Usage analytics (Google Analytics integration)
   - Compliance trends
   - Department comparisons

### Product Detail Pages

**Route:** `/product/{product_id}`

**Sections:**
- **Overview:** Current status, key details, owners
- **Timeline:** Visual timeline of approval → audit → deployment → reviews
- **Approval:** Original approval form and sign-offs
- **Audit:** Full audit report with checklist
- **Deployment:** API data, deployment metadata, reconciliation status
- **Reviews:** History of all reviews with trends
- **Analytics:** Product-specific Google Analytics (if available)
- **Actions:**
  - Flag for review
  - Request re-audit
  - Update metadata
  - Archive/deprecate

## Data Model Changes

### New/Updated Tables

#### `products`
Core table for ALL products (approved, in development, deployed)
```sql
- product_id (PK)
- name
- type (shiny_dashboard, quarto_report, dash_app, api_service)
- department
- team
- lifecycle_stage (approved, in_development, in_audit, deployed, archived)
- current_status (specific to stage)
- created_at
- updated_at
```

#### `approvals`
Links to `products`, one approval per product
```sql
- approval_id (PK)
- product_id (FK)
- submitted_by
- submitted_at
- business_justification
- maintenance_plan
- developers (JSON array)
- target_audience
- data_sources
- update_schedule
- governance_signoff, governance_signoff_by, governance_signoff_at
- technical_signoff, technical_signoff_by, technical_signoff_at
- security_signoff, security_signoff_by, security_signoff_at
- status (pending, approved, rejected)
```

#### `audits`
Full audit checklist for pre-deployment
```sql
- audit_id (PK)
- product_id (FK)
- audit_type (pre_deployment, review)
- initiated_by
- initiated_at
- completed_at
- overall_score
- pass_threshold
- status (in_progress, passed, failed, changes_requested)

-- Checklist sections stored in related table
```

#### `audit_checklist_items`
Individual checklist items with collaboration
```sql
- item_id (PK)
- audit_id (FK)
- category (governance, design, metadata, accessibility, etc.)
- item_name
- description
- assigned_to (user_id, can be NULL)
- status (pending, in_progress, completed, failed)
- score (0-100)
- evidence_url
- notes
- checked_by
- checked_at
```

#### `deployments`
Links products to API deployments
```sql
- deployment_id (PK)
- product_id (FK)
- platform (posit_connect, shinyapps_io, other)
- external_id (from API)
- url
- deployed_at
- api_data (JSON - raw API response)
- reconciliation_status (matched, discrepancy, unlinked)
- reconciliation_notes
- last_synced_at
```

#### `reviews`
Ongoing periodic reviews
```sql
- review_id (PK)
- product_id (FK)
- review_type (scheduled, manual, version_triggered)
- triggered_by (schedule_id or user_id)
- due_date
- completed_at
- reviewer
- checklist_items (JSON - subset of audit checklist)
- overall_score
- status (pending, in_progress, passed, flagged)
- notes
```

#### `review_schedules`
Automated review scheduling
```sql
- schedule_id (PK)
- product_id (FK)
- frequency_days
- next_review_date
- last_review_date
- active (boolean)
```

#### `google_analytics`
GA data for products
```sql
- ga_id (PK)
- product_id (FK)
- property_id (GA4 property)
- date
- page_views
- unique_users
- avg_session_duration
- bounce_rate
- synced_at
```

## Key Features

### 1. Page Routing
Use `shiny.router` package to implement:
- Product list page
- Product detail pages with unique URLs
- Approval workflow pages
- Audit management pages
- Review dashboard
- Analytics pages

### 2. Data Reconciliation
When API sync runs:
```
1. Fetch deployments from APIs
2. For each API deployment:
   a. Try to match to existing product (by URL, name, external_id)
   b. If matched:
      - Compare API data with approval/audit data
      - Flag discrepancies (different owner, URL mismatch, etc.)
      - Update deployment record
   c. If unmatched:
      - Create "unlinked" product
      - Flag for manual reconciliation
3. For each deployed product not found in API:
   - Flag as potentially removed/unavailable
```

### 3. Collaborative Auditing
- Audit coordinator creates audit
- Assigns checklist items to team members
- Each member completes their items
- Comments and evidence attached
- Coordinator reviews and approves

### 4. Automated Review Scheduling
- Each product type has default frequency
- Override per product if needed
- Nightly job checks for due reviews
- Notifications sent to owners
- Manual trigger always available

### 5. Audit Checklist Template System
Create reusable templates:
- **Full Pre-Deployment Audit** (30-50 items)
- **Quarterly Review** (10-15 key items)
- **Monthly Review** (5-8 critical items)
- **Product-Type Specific** (Shiny has different checks than Quarto)

## Implementation Priority

### Phase 1 (Core Restructure)
1. ✅ Design workflow and data model
2. Update database schema
3. Implement page routing
4. Restructure product list as primary view
5. Update demo data for new workflow

### Phase 2 (Audit System)
6. Build comprehensive audit checklist system
7. Implement collaborative features
8. Create audit templates
9. Add evidence uploads

### Phase 3 (Integration)
10. Build data reconciliation engine
11. Link API data to products
12. Discrepancy detection and flagging

### Phase 4 (Reviews & Analytics)
13. Implement review scheduling
14. Create Google Analytics integration
15. Build organization-wide analytics
16. Add drill-down and filtering

## Next Steps

1. Update database schema SQL
2. Create updated mock data for demo mode
3. Implement routing infrastructure
4. Build new modules for each stage
5. Create product detail page template
6. Test end-to-end workflow
