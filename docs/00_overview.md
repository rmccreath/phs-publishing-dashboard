# Project Overview

**Project Name**: PHS Dashboard Compliance & Analytics Hub

## 1. Summary

A centralized web application that provides comprehensive tracking, monitoring, and reporting capabilities for all dashboard publications across Public Health Scotland. The platform automates compliance checking against organizational standards, integrates usage analytics, and promotes best practices through benchmarking and knowledge sharing.

The system leverages APIs from Posit Connect, GitHub/Gitea, and Google Analytics to automate data collection, reducing manual reporting burden while providing real-time insights into dashboard performance, compliance status, and user engagement.

**Expected Impact**:
- Improved governance oversight
- Accelerated adoption of new standards
- 75% reduction in compliance reporting effort
- Establishment of a data-driven culture around dashboard quality and usage

## 2. Goals & Objectives

### Primary Goals
- Establish single source of truth for all deployed dashboards across PHS
- Automate compliance monitoring against defined organizational standards
- Provide dashboard owners with actionable insights on usage and performance
- Reduce manual effort in compliance reporting and governance activities
- Accelerate adoption of new Posit Connect platform and associated processes

### Secondary Objectives
- Identify and showcase best practices across teams
- Enable data-driven decision making about dashboard investments
- Build foundation for cross-organization benchmarking
- Support capacity planning through resource utilization tracking
- Foster community of practice through shared learning

## 3. Scope

### In Scope
✅ Dashboard registry with automated discovery via Posit Connect API
✅ Compliance tracking against defined metrics (accessibility, documentation, testing, security)
✅ Google Analytics integration for usage statistics
✅ Automated data collection from GitHub/Gitea repositories
✅ Role-based access control with Azure AD integration
✅ Reporting dashboards for various stakeholder levels
✅ API endpoints for system integration
✅ Historical trend analysis and benchmarking

### Out of Scope
❌ Direct modification of tracked dashboards
❌ Content quality assessment (only technical compliance)
❌ Financial cost allocation/chargeback
❌ Cross-NHS Scotland integration (Phase 1)
❌ Machine learning powered recommendations (Phase 1)
❌ Automated remediation of compliance issues

## 4. Key Features

### Dashboard Registry
- Automated discovery from Posit Connect and ShinyApps.io
- Manual registration for other platforms
- Comprehensive metadata management
- Multi-platform support

### Approval Workflow
- Structured submission with business justification
- Multi-stage review process (governance, technical, security)
- Status tracking and audit trail
- Email notifications

### Compliance Tracking
- Five key metrics: Accessibility, Documentation, Repository, Testing, Security
- Weighted scoring algorithm
- Automated checks with exemption management
- Trend analysis and reporting

### Analytics & Reporting
- Organization-wide dashboards
- Team performance scorecards
- Benchmarking capabilities
- Custom report generation

### Role-Based Access Control
- **Admin**: Full system access
- **Governance**: Approval and compliance management
- **Team Lead**: Team-level oversight
- **Owner**: Manage own dashboards
- **Viewer**: Read-only access

## 5. Success Metrics

- **Adoption**: 90% of dashboards registered within 6 months
- **Compliance**: Average compliance score >75% within 12 months
- **Efficiency**: 75% reduction in manual compliance reporting time
- **Engagement**: >80% user satisfaction score
- **Coverage**: 100% visibility of dashboard landscape

## 6. Technology Stack

- **Frontend**: Shiny, bslib, echarts4r, reactable, DT
- **Backend**: R 4.3+, PostgreSQL 14+
- **APIs**: Posit Connect, GitHub, ShinyApps.io, Google Analytics
- **Infrastructure**: Azure cloud services
- **Deployment**: Posit Connect

## 7. Project Timeline

- **Phase 1**: Foundation & Registry (Weeks 1-4) ✅
- **Phase 2**: Compliance Framework (Weeks 5-8) ✅
- **Phase 3**: Analytics Integration (Weeks 9-12) ✅
- **Phase 4**: Automation & APIs (Weeks 13-15) ✅
- **Phase 5**: Testing & Deployment (Weeks 16-18)

## 8. Contact

- **Project Lead**: governance@phs.scot
- **Support**: [GitHub Issues](https://github.com/Public-Health-Scotland/phs-publishing-dashboard/issues)
