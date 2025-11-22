# PHS Governance Dashboard - Restructure Implementation Summary

## Overview

Based on your feedback, I've designed a complete restructure of the application to properly reflect the governance workflow. This document summarizes the design for your review before I proceed with implementation.

## Current vs. New Workflow

### Current (Incorrect) ❌
1. Show deployed dashboards from APIs
2. Add approval workflow (backwards)
3. Run compliance checks

### New (Correct) ✅
1. **Approval** → Teams submit requests for NEW products (not yet built)
2. **Development** → Teams build the product (outside system)
3. **Audit** → Comprehensive pre-deployment quality check (collaborative)
4. **Deployment** → Product goes live, appears on APIs
5. **Ongoing Reviews** → Periodic checks based on schedule/triggers

## Key Changes

### 1. Product Lifecycle Management

**All products tracked regardless of stage:**
- Approved (waiting for development)
- In Development (external to system)
- In Audit (collaborative quality check)
- Deployed (live on platforms)
- Under Review (periodic checks)
- Archived

### 2. Approval Process (BEFORE Development)

**For NEW products that don't exist yet:**
- Team submits approval form with:
  - Product details
  - Business justification
  - Developers assigned
  - Maintenance plan
  - Support plan
- Three-stage sign-off:
  - Governance
  - Technical
  - Security (if needed)
- Status: Pending → Approved → Development can begin

### 3. Audit System (AFTER Development, BEFORE Deployment)

**Comprehensive checklist covering:**
- Governance compliance
- UI/UX design quality
- Metadata completeness
- Accessibility (WCAG 2.1 AA)
- Data quality
- Security
- Testing evidence
- Documentation
- Performance

**Key features:**
- **Collaborative**: Items assigned to different auditors
- **Evidence-based**: Upload screenshots, reports
- **Automatable**: Flags for future automation (accessibility scans, test coverage)
- **Template-based**: Reusable checklists for different product types
- Must pass audit (score > threshold) to deploy

### 4. Deployment & Reconciliation

**When product goes live:**
- Deployment record created
- Links to API data (Posit Connect, ShinyApps.io)
- **Reconciliation engine:**
  - Matches API deployments to products
  - Compares API data with approval/audit data
  - Flags discrepancies (different owner, wrong URL, etc.)
  - Creates "unlinked" products for unmapped API items

### 5. Ongoing Reviews

**Periodic quality checks:**
- **Scheduled**: Based on product type
  - Static reports: Quarterly
  - High-traffic dashboards: Monthly
  - Low-traffic: Quarterly
- **Manual**: User flags for review
- **Triggered**: New version detected
- Uses **subset** of audit checklist (5-15 items vs. 30-50)
- Status: Pending → In Progress → Passed/Flagged

### 6. Page Routing

**Product-specific pages:**
- `/products` - List all products with filters
- `/product/{id}` - Product detail page with:
  - Overview & timeline
  - Approval details
  - Audit report
  - Deployment info
  - Review history
  - Analytics (Google Analytics)
  - Actions (flag for review, etc.)
- `/approvals` - Submit & review approvals
- `/audits` - Manage ongoing audits
- `/reviews` - Review dashboard & scheduling
- `/analytics` - Organization-wide analytics

### 7. Google Analytics Integration

**Separate analytics section:**
- Link GA4 properties to products
- Daily metrics: page views, users, sessions
- Product-specific analytics pages
- Organization-wide aggregation
- Drill-down capabilities

## Database Schema Changes

**New tables:**
- `products` - Core table for ALL products (any stage)
- `approvals` - Pre-development approval requests
- `audits` - Audit management
- `audit_checklist_items` - Individual checklist items (collaborative)
- `audit_templates` - Reusable checklist templates
- `deployments` - Links to API deployments with reconciliation
- `reviews` - Periodic review records
- `review_schedules` - Automated review scheduling
- `google_analytics` - GA4 data integration
- `audit_log` - Full change tracking

**Key views:**
- `vw_product_overview` - Complete product status
- `vw_products_needing_attention` - Action items dashboard

## Implementation Phases

### Phase 1: Core Restructure (Foundation)
1. ✅ Design workflow and data model
2. ✅ Update database schema
3. Install routing package (`shiny.router`)
4. Create product-centric navigation
5. Update demo data for new workflow
6. Basic product list and detail pages

**Outcome:** Foundation for new workflow, can navigate to products

### Phase 2: Approval & Audit (Core Workflow)
7. Rebuild approval module for pre-development
8. Create comprehensive audit checklist system
9. Implement collaborative auditing
10. Build audit templates
11. Add evidence uploads
12. Link approval → audit → deployment

**Outcome:** Complete pre-deployment workflow functional

### Phase 3: Deployment & Reconciliation (API Integration)
13. Build deployment tracking
14. Create reconciliation engine
15. Match API data to products
16. Discrepancy detection and flagging
17. Manual reconciliation interface

**Outcome:** API data properly linked and validated

### Phase 4: Reviews & Analytics (Ongoing Monitoring)
18. Implement review scheduling
19. Create review management interface
20. Build Google Analytics integration
21. Organization-wide analytics dashboards
22. Drill-down and filtering

**Outcome:** Complete governance lifecycle operational

## Questions for You

Before I proceed with implementation, please confirm:

1. **Workflow**: Does this match your governance process?
2. **Audit checklist**: Should I create a sample checklist now, or will you define items later?
3. **Product types**: Are these sufficient? `shiny_dashboard`, `quarto_report`, `dash_app`, `api_service`, `other`
4. **Review frequency**: Are the defaults appropriate? (monthly for high-traffic, quarterly for others)
5. **Phase 1 scope**: Should I implement Phase 1 now, or do you want to review more details first?

## Recommendations

**Start with Phase 1:**
- Establishes foundation
- You can test navigation and structure
- Allows iterative refinement before complex features
- Demo mode will show complete workflow with sample data

**Incremental deployment:**
- Each phase adds functionality
- Can test and refine between phases
- Less risky than big-bang rewrite

## Next Steps

Once you approve this design:

1. Commit design documents
2. Install `shiny.router` package
3. Begin Phase 1 implementation:
   - Update DESCRIPTION with routing dependency
   - Create routing structure
   - Redesign main navigation
   - Build product list page
   - Create product detail page template
   - Update demo data
4. Test in demo mode
5. Iterate based on your feedback

Would you like me to proceed with Phase 1 implementation?
