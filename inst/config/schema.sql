-- PHS Dashboard Governance Database Schema
-- Version: 1.0.0
-- Description: Complete schema for dashboard registry, compliance, approvals, and analytics

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'governance', 'team_lead', 'owner', 'viewer')),
    team VARCHAR(100),
    department VARCHAR(100),
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE
);

-- Dashboard registry
CREATE TABLE IF NOT EXISTS dashboards (
    dashboard_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    url TEXT NOT NULL,
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('posit_connect', 'shinyapps_io', 'other')),
    type VARCHAR(50) CHECK (type IN ('shiny', 'rmarkdown', 'quarto', 'plumber', 'other')),

    -- Ownership
    owner_id UUID REFERENCES users(user_id),
    team VARCHAR(100),
    department VARCHAR(100),

    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'published', 'deprecated', 'archived')),
    visibility VARCHAR(50) CHECK (visibility IN ('public', 'internal', 'restricted')),

    -- Deployment
    deployment_date TIMESTAMP WITH TIME ZONE,
    last_updated TIMESTAMP WITH TIME ZONE,
    update_frequency VARCHAR(50),

    -- Links
    repository_url TEXT,
    documentation_url TEXT,

    -- Metadata
    tags TEXT[],
    keywords TEXT[],
    metadata JSONB,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    UNIQUE(platform, external_id)
);

-- Approval workflow
CREATE TABLE IF NOT EXISTS approvals (
    approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(dashboard_id) ON DELETE CASCADE,

    -- Submission
    submitted_by UUID NOT NULL REFERENCES users(user_id),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Justification
    business_justification TEXT NOT NULL,
    target_audience TEXT,
    data_sources TEXT,
    update_schedule TEXT,
    support_plan TEXT,

    -- Approval status
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'requires_changes')),

    -- Review
    reviewed_by UUID REFERENCES users(user_id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,

    -- Sign-off
    governance_signoff BOOLEAN DEFAULT FALSE,
    governance_signoff_by UUID REFERENCES users(user_id),
    governance_signoff_at TIMESTAMP WITH TIME ZONE,

    technical_signoff BOOLEAN DEFAULT FALSE,
    technical_signoff_by UUID REFERENCES users(user_id),
    technical_signoff_at TIMESTAMP WITH TIME ZONE,

    security_signoff BOOLEAN DEFAULT FALSE,
    security_signoff_by UUID REFERENCES users(user_id),
    security_signoff_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Compliance tracking
CREATE TABLE IF NOT EXISTS compliance_checks (
    check_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(dashboard_id) ON DELETE CASCADE,
    check_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Compliance metrics
    accessibility_score DECIMAL(5,2),
    accessibility_notes TEXT,
    accessibility_wcag_level VARCHAR(10),

    documentation_score DECIMAL(5,2),
    documentation_notes TEXT,
    documentation_complete BOOLEAN,

    repository_score DECIMAL(5,2),
    repository_notes TEXT,
    repository_linked BOOLEAN,
    repository_active BOOLEAN,

    testing_score DECIMAL(5,2),
    testing_notes TEXT,
    testing_coverage DECIMAL(5,2),

    security_score DECIMAL(5,2),
    security_notes TEXT,
    security_vulnerabilities INTEGER DEFAULT 0,

    -- Overall
    overall_score DECIMAL(5,2),
    grade VARCHAR(20),

    -- Status
    compliant BOOLEAN,
    exemptions JSONB,

    -- Metadata
    checked_by VARCHAR(50) DEFAULT 'system',
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Analytics data
CREATE TABLE IF NOT EXISTS analytics (
    analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(dashboard_id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,

    -- Usage metrics
    page_views INTEGER DEFAULT 0,
    unique_users INTEGER DEFAULT 0,
    sessions INTEGER DEFAULT 0,
    avg_session_duration INTERVAL,
    bounce_rate DECIMAL(5,2),

    -- Engagement
    interactions INTEGER DEFAULT 0,
    downloads INTEGER DEFAULT 0,

    -- Performance
    avg_load_time DECIMAL(10,2),
    error_rate DECIMAL(5,2),
    uptime_percentage DECIMAL(5,2),

    -- Source
    data_source VARCHAR(50),

    -- Metadata
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(dashboard_id, metric_date, data_source)
);

-- Audit log
CREATE TABLE IF NOT EXISTS audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    performed_by UUID REFERENCES users(user_id),
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    details JSONB,
    ip_address INET,
    user_agent TEXT
);

-- Exemptions
CREATE TABLE IF NOT EXISTS compliance_exemptions (
    exemption_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(dashboard_id) ON DELETE CASCADE,
    metric_name VARCHAR(100) NOT NULL,
    reason TEXT NOT NULL,

    -- Approval
    requested_by UUID NOT NULL REFERENCES users(user_id),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    approved_by UUID REFERENCES users(user_id),
    approved_at TIMESTAMP WITH TIME ZONE,

    -- Validity
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP WITH TIME ZONE,

    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_team ON users(team);

-- Dashboards
CREATE INDEX idx_dashboards_owner ON dashboards(owner_id);
CREATE INDEX idx_dashboards_status ON dashboards(status);
CREATE INDEX idx_dashboards_platform ON dashboards(platform);
CREATE INDEX idx_dashboards_team ON dashboards(team);
CREATE INDEX idx_dashboards_department ON dashboards(department);
CREATE INDEX idx_dashboards_tags ON dashboards USING GIN(tags);
CREATE INDEX idx_dashboards_created ON dashboards(created_at);

-- Approvals
CREATE INDEX idx_approvals_dashboard ON approvals(dashboard_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_submitted_by ON approvals(submitted_by);
CREATE INDEX idx_approvals_submitted_at ON approvals(submitted_at);

-- Compliance
CREATE INDEX idx_compliance_dashboard ON compliance_checks(dashboard_id);
CREATE INDEX idx_compliance_date ON compliance_checks(check_date);
CREATE INDEX idx_compliance_grade ON compliance_checks(grade);
CREATE INDEX idx_compliance_compliant ON compliance_checks(compliant);

-- Analytics
CREATE INDEX idx_analytics_dashboard ON analytics(dashboard_id);
CREATE INDEX idx_analytics_date ON analytics(metric_date);
CREATE INDEX idx_analytics_source ON analytics(data_source);

-- Audit log
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_performed_by ON audit_log(performed_by);
CREATE INDEX idx_audit_performed_at ON audit_log(performed_at);

-- Exemptions
CREATE INDEX idx_exemptions_dashboard ON compliance_exemptions(dashboard_id);
CREATE INDEX idx_exemptions_status ON compliance_exemptions(status);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Dashboard overview with latest compliance
CREATE OR REPLACE VIEW vw_dashboard_overview AS
SELECT
    d.dashboard_id,
    d.name,
    d.description,
    d.url,
    d.platform,
    d.type,
    d.status,
    d.owner_id,
    u.full_name as owner_name,
    u.email as owner_email,
    d.team,
    d.department,
    d.deployment_date,
    d.last_updated,
    c.overall_score,
    c.grade,
    c.compliant,
    c.check_date as last_compliance_check,
    d.created_at,
    d.updated_at
FROM dashboards d
LEFT JOIN users u ON d.owner_id = u.user_id
LEFT JOIN LATERAL (
    SELECT * FROM compliance_checks
    WHERE dashboard_id = d.dashboard_id
    ORDER BY check_date DESC
    LIMIT 1
) c ON TRUE;

-- Team compliance summary
CREATE OR REPLACE VIEW vw_team_compliance AS
SELECT
    team,
    COUNT(DISTINCT dashboard_id) as total_dashboards,
    COUNT(DISTINCT CASE WHEN compliant THEN dashboard_id END) as compliant_dashboards,
    ROUND(AVG(overall_score), 2) as avg_compliance_score,
    COUNT(DISTINCT CASE WHEN grade = 'excellent' THEN dashboard_id END) as excellent_count,
    COUNT(DISTINCT CASE WHEN grade = 'good' THEN dashboard_id END) as good_count,
    COUNT(DISTINCT CASE WHEN grade = 'acceptable' THEN dashboard_id END) as acceptable_count,
    COUNT(DISTINCT CASE WHEN grade = 'poor' THEN dashboard_id END) as poor_count
FROM vw_dashboard_overview
WHERE status IN ('approved', 'published')
GROUP BY team;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update timestamp triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dashboards_updated_at BEFORE UPDATE ON dashboards
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_approvals_updated_at BEFORE UPDATE ON approvals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exemptions_updated_at BEFORE UPDATE ON compliance_exemptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit log trigger function
CREATE OR REPLACE FUNCTION audit_log_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (entity_type, entity_id, action, details)
        VALUES (TG_TABLE_NAME, OLD.dashboard_id, 'DELETE', row_to_json(OLD));
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (entity_type, entity_id, action, details)
        VALUES (TG_TABLE_NAME, NEW.dashboard_id, 'UPDATE',
                jsonb_build_object('old', row_to_json(OLD), 'new', row_to_json(NEW)));
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (entity_type, entity_id, action, details)
        VALUES (TG_TABLE_NAME, NEW.dashboard_id, 'INSERT', row_to_json(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers
CREATE TRIGGER audit_dashboards AFTER INSERT OR UPDATE OR DELETE ON dashboards
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

CREATE TRIGGER audit_approvals AFTER INSERT OR UPDATE OR DELETE ON approvals
    FOR EACH ROW EXECUTE FUNCTION audit_log_trigger();

-- ============================================================================
-- SAMPLE DATA (for development)
-- ============================================================================

-- Sample users
INSERT INTO users (username, email, full_name, role, team, department) VALUES
('admin', 'admin@phs.scot', 'System Administrator', 'admin', 'IT', 'Infrastructure'),
('governance', 'governance@phs.scot', 'Governance Officer', 'governance', 'Governance', 'Quality'),
('lead1', 'lead1@phs.scot', 'Team Lead One', 'team_lead', 'Analytics', 'Data Science'),
('owner1', 'owner1@phs.scot', 'Dashboard Owner One', 'owner', 'Analytics', 'Data Science'),
('viewer1', 'viewer1@phs.scot', 'Viewer One', 'viewer', 'Operations', 'Management')
ON CONFLICT DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO phs_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO phs_user;
