# PHS Dashboard Compliance & Analytics Hub

A centralized governance dashboard for tracking, monitoring, and reporting on dashboard publications across Public Health Scotland. This application automates compliance checking, integrates usage analytics, and manages approval workflows.

## 🎯 Features

### 📊 Dashboard Registry
- **Automated Discovery**: Automatically discover and register dashboards from Posit Connect and ShinyApps.io
- **Manual Registration**: Add dashboards from other platforms manually
- **Comprehensive Metadata**: Track ownership, deployment dates, documentation links, and more
- **Multi-platform Support**: Posit Connect, ShinyApps.io, and custom platforms

### ✅ Approval Workflow
- **Structured Submission**: Dashboard owners submit dashboards with business justification
- **Multi-stage Review**: Governance, technical, and security sign-offs
- **Status Tracking**: Track approval status from submission to publication
- **Audit Trail**: Complete history of all approval decisions

### 🛡️ Compliance Tracking
- **Automated Checks**: Automatic compliance assessment against organizational standards
- **Multiple Metrics**:
  - Accessibility (WCAG compliance)
  - Documentation completeness
  - Repository health
  - Testing coverage
  - Security vulnerabilities
- **Scoring System**: Overall compliance scores and grades (Excellent, Good, Acceptable, Poor)
- **Exemption Management**: Request and track compliance exemptions

### 📈 Analytics & Reporting
- **Organization Overview**: High-level metrics and trends
- **Team Performance**: Team-level scorecards and benchmarking
- **Best Practices**: Identify and showcase top-performing dashboards
- **Custom Reports**: Generate executive summaries, compliance reports, and audits

### 🔐 Role-Based Access Control
- **Admin**: Full system access and configuration
- **Governance**: Approval and compliance management
- **Team Lead**: Team-level oversight and approvals
- **Owner**: Manage own dashboards
- **Viewer**: Read-only access to summaries

## 🚀 Getting Started

### Prerequisites

- R >= 4.3.0
- PostgreSQL >= 14
- Access to Posit Connect (optional)
- GitHub personal access token
- ShinyApps.io credentials (optional)

### Quick Start

```r
# Install the package
devtools::install()

# Run the application
phsgovernance::run_app()
```

See the full documentation in the `/docs` folder for detailed setup instructions.

## 📖 Project Structure

```
phsgovernance/
├── R/                          # Application code
│   ├── app_ui.R               # Main UI definition
│   ├── app_server.R           # Main server logic
│   ├── mod_*.R                # Shiny modules
│   ├── svc_*.R                # API services
│   └── utils_*.R              # Utility functions
├── inst/
│   ├── app/www/               # Static assets
│   └── config/                # Configuration files
├── app.R                       # Deployment entry point
└── DESCRIPTION                 # Package metadata
```

## 📚 Documentation

- [Project Overview](docs/00_overview.md) - High-level project description
- [Requirements](docs/01_requirements.md) - Detailed requirements specification
- [Solution Design](docs/02_solution_design.md) - Technical architecture
- [Implementation Plan](docs/03_implementation_plan.md) - Development roadmap

## 🔧 Configuration

1. Copy `.Renviron.example` to `.Renviron`
2. Configure your database and API credentials
3. Customize `inst/config/config.yml` for your environment

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/Public-Health-Scotland/phs-publishing-dashboard/issues)
- **Email**: governance@phs.scot

---

**Version**: 0.1.0 | **Maintained by**: PHS Digital Team
