-- PHS Governance Dashboard - Database Schema v2
-- Reflects proper workflow: Approval → Development → Audit → Deployment → Reviews

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Products: ALL information products regardless of stage
CREATE TABLE IF NOT EXISTS products (
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50) NOT NULL, -- shiny_dashboard, quarto_report, dash_app, api_service, other
  department VARCHAR(100),
  team VARCHAR(100),
  lifecycle_stage VARCHAR(50) NOT NULL DEFAULT 'approved',
    -- approved, in_development, in_audit, deployed, archived
  current_status VARCHAR(50), -- Stage-specific status
  created_by VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb,
  tags TEXT[],
  CONSTRAINT valid_lifecycle_stage CHECK (lifecycle_stage IN (
    'approved', 'in_development', 'in_audit', 'deployed', 'archived'
  )),
  CONSTRAINT valid_product_type CHECK (type IN (
    'shiny_dashboard', 'quarto_report', 'dash_app', 'api_service', 'other'
  ))
);

CREATE INDEX idx_products_lifecycle_stage ON products(lifecycle_stage);
CREATE INDEX idx_products_type ON products(type);
CREATE INDEX idx_products_department ON products(department);
CREATE INDEX idx_products_team ON products(team);
CREATE INDEX idx_products_tags ON products USING GIN(tags);

-- ============================================================================
-- APPROVAL WORKFLOW (Stage 1: BEFORE Development)
-- ============================================================================

CREATE TABLE IF NOT EXISTS approvals (
  approval_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

  -- Submission details
  submitted_by VARCHAR(100) NOT NULL,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- Approval form data
  business_justification TEXT NOT NULL,
  target_audience TEXT,
  data_sources TEXT,
  update_schedule VARCHAR(100),
  support_plan TEXT,
  developers JSONB DEFAULT '[]'::jsonb, -- Array of developer names/IDs
  maintenance_plan TEXT,
  estimated_users INTEGER,
  data_sensitivity VARCHAR(50), -- public, internal, sensitive, restricted

  -- Sign-offs (three-stage approval)
  governance_signoff BOOLEAN DEFAULT FALSE,
  governance_signoff_by VARCHAR(100),
  governance_signoff_at TIMESTAMP WITH TIME ZONE,
  governance_notes TEXT,

  technical_signoff BOOLEAN DEFAULT FALSE,
  technical_signoff_by VARCHAR(100),
  technical_signoff_at TIMESTAMP WITH TIME ZONE,
  technical_notes TEXT,

  security_signoff BOOLEAN DEFAULT FALSE,
  security_signoff_by VARCHAR(100),
  security_signoff_at TIMESTAMP WITH TIME ZONE,
  security_notes TEXT,

  -- Overall approval status
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending, approved, rejected, changes_requested
  reviewed_by VARCHAR(100),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  review_notes TEXT,

  metadata JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_approval_status CHECK (status IN (
    'pending', 'approved', 'rejected', 'changes_requested'
  )),
  CONSTRAINT valid_data_sensitivity CHECK (data_sensitivity IN (
    'public', 'internal', 'sensitive', 'restricted'
  ))
);

CREATE INDEX idx_approvals_product ON approvals(product_id);
CREATE INDEX idx_approvals_status ON approvals(status);
CREATE INDEX idx_approvals_submitted_by ON approvals(submitted_by);

-- ============================================================================
-- AUDIT SYSTEM (Stage 3: AFTER Development, BEFORE Deployment)
-- ============================================================================

CREATE TABLE IF NOT EXISTS audits (
  audit_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  audit_type VARCHAR(50) NOT NULL, -- pre_deployment, quarterly_review, monthly_review

  -- Audit management
  initiated_by VARCHAR(100) NOT NULL,
  initiated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  coordinator VARCHAR(100), -- Person managing the audit
  completed_at TIMESTAMP WITH TIME ZONE,

  -- Scoring
  overall_score DECIMAL(5,2),
  pass_threshold DECIMAL(5,2) DEFAULT 70.00,

  -- Status tracking
  status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    -- in_progress, passed, failed, changes_requested

  -- Summary
  summary TEXT,
  recommendations TEXT,

  metadata JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_audit_type CHECK (audit_type IN (
    'pre_deployment', 'quarterly_review', 'monthly_review', 'manual_review'
  )),
  CONSTRAINT valid_audit_status CHECK (status IN (
    'in_progress', 'passed', 'failed', 'changes_requested'
  ))
);

CREATE INDEX idx_audits_product ON audits(product_id);
CREATE INDEX idx_audits_status ON audits(status);
CREATE INDEX idx_audits_type ON audits(audit_type);

-- Audit checklist items (collaborative, assigned to different people)
CREATE TABLE IF NOT EXISTS audit_checklist_items (
  item_id SERIAL PRIMARY KEY,
  audit_id INTEGER NOT NULL REFERENCES audits(audit_id) ON DELETE CASCADE,

  -- Item definition
  category VARCHAR(100) NOT NULL,
    -- governance, design, metadata, accessibility, security, testing, documentation, etc.
  item_name VARCHAR(255) NOT NULL,
  description TEXT,
  guidance TEXT, -- How to check this item
  weight DECIMAL(3,2) DEFAULT 1.00, -- Importance weighting

  -- Assignment
  assigned_to VARCHAR(100), -- User responsible for checking this item
  assigned_at TIMESTAMP WITH TIME ZONE,

  -- Check results
  status VARCHAR(50) DEFAULT 'pending',
    -- pending, in_progress, passed, failed, not_applicable
  score DECIMAL(5,2), -- 0-100 or NULL if N/A
  evidence_url VARCHAR(500), -- Link to screenshot, report, etc.
  evidence_type VARCHAR(50), -- screenshot, document, test_report, automated
  notes TEXT,
  checked_by VARCHAR(100),
  checked_at TIMESTAMP WITH TIME ZONE,

  -- Automation flags
  can_automate BOOLEAN DEFAULT FALSE,
  automation_source VARCHAR(100), -- 'accessibility_scanner', 'test_coverage', etc.

  CONSTRAINT valid_checklist_status CHECK (status IN (
    'pending', 'in_progress', 'passed', 'failed', 'not_applicable'
  ))
);

CREATE INDEX idx_checklist_audit ON audit_checklist_items(audit_id);
CREATE INDEX idx_checklist_category ON audit_checklist_items(category);
CREATE INDEX idx_checklist_assigned ON audit_checklist_items(assigned_to);
CREATE INDEX idx_checklist_status ON audit_checklist_items(status);

-- Audit checklist templates (reusable templates for different audit types)
CREATE TABLE IF NOT EXISTS audit_templates (
  template_id SERIAL PRIMARY KEY,
  template_name VARCHAR(255) NOT NULL,
  audit_type VARCHAR(50) NOT NULL,
  description TEXT,
  product_types TEXT[], -- Which product types this applies to
  items JSONB NOT NULL, -- Array of checklist item definitions
  created_by VARCHAR(100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_audit_templates_type ON audit_templates(audit_type);

-- ============================================================================
-- DEPLOYMENT (Stage 4: Product Goes Live)
-- ============================================================================

CREATE TABLE IF NOT EXISTS deployments (
  deployment_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

  -- Platform details
  platform VARCHAR(50) NOT NULL, -- posit_connect, shinyapps_io, github_pages, other
  external_id VARCHAR(255), -- ID from the platform API
  url VARCHAR(500) NOT NULL,

  -- Deployment metadata
  deployed_by VARCHAR(100),
  deployed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  version VARCHAR(50),

  -- API integration
  api_data JSONB DEFAULT '{}'::jsonb, -- Raw data from platform API
  last_synced_at TIMESTAMP WITH TIME ZONE,
  sync_status VARCHAR(50), -- success, failed, pending

  -- Data reconciliation
  reconciliation_status VARCHAR(50) DEFAULT 'matched',
    -- matched, discrepancy, unlinked, needs_review
  reconciliation_notes TEXT,
  reconciled_by VARCHAR(100),
  reconciled_at TIMESTAMP WITH TIME ZONE,

  -- Current status
  is_active BOOLEAN DEFAULT TRUE,
  deactivated_at TIMESTAMP WITH TIME ZONE,
  deactivated_by VARCHAR(100),
  deactivation_reason TEXT,

  metadata JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_platform CHECK (platform IN (
    'posit_connect', 'shinyapps_io', 'github_pages', 'other'
  )),
  CONSTRAINT valid_reconciliation_status CHECK (reconciliation_status IN (
    'matched', 'discrepancy', 'unlinked', 'needs_review'
  ))
);

CREATE INDEX idx_deployments_product ON deployments(product_id);
CREATE INDEX idx_deployments_platform ON deployments(platform);
CREATE INDEX idx_deployments_reconciliation ON deployments(reconciliation_status);
CREATE INDEX idx_deployments_active ON deployments(is_active);

-- ============================================================================
-- ONGOING REVIEWS (Stage 5: Periodic Quality Checks)
-- ============================================================================

CREATE TABLE IF NOT EXISTS reviews (
  review_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

  -- Review trigger
  review_type VARCHAR(50) NOT NULL, -- scheduled, manual, version_triggered, flagged
  triggered_by VARCHAR(100), -- User ID if manual, 'system' if scheduled
  triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- Scheduling
  due_date DATE,
  completed_at TIMESTAMP WITH TIME ZONE,

  -- Review details
  reviewer VARCHAR(100),
  checklist_items JSONB DEFAULT '[]'::jsonb, -- Subset of audit checklist
  overall_score DECIMAL(5,2),

  -- Status
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending, in_progress, passed, flagged, overdue

  -- Results
  notes TEXT,
  action_items TEXT,
  next_review_date DATE,

  metadata JSONB DEFAULT '{}'::jsonb,

  CONSTRAINT valid_review_type CHECK (review_type IN (
    'scheduled', 'manual', 'version_triggered', 'flagged'
  )),
  CONSTRAINT valid_review_status CHECK (status IN (
    'pending', 'in_progress', 'passed', 'flagged', 'overdue'
  ))
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_status ON reviews(status);
CREATE INDEX idx_reviews_due_date ON reviews(due_date);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer);

-- Review schedules (automated review triggers)
CREATE TABLE IF NOT EXISTS review_schedules (
  schedule_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

  -- Schedule configuration
  frequency_days INTEGER NOT NULL, -- Review every X days
  next_review_date DATE NOT NULL,
  last_review_date DATE,

  -- Status
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- Automation
  auto_create_review BOOLEAN DEFAULT TRUE, -- Automatically create review on due date
  assigned_reviewer VARCHAR(100), -- Default reviewer for auto-created reviews

  notes TEXT
);

CREATE INDEX idx_review_schedules_product ON review_schedules(product_id);
CREATE INDEX idx_review_schedules_next_date ON review_schedules(next_review_date);
CREATE INDEX idx_review_schedules_active ON review_schedules(active);

-- ============================================================================
-- ANALYTICS (Google Analytics Integration)
-- ============================================================================

CREATE TABLE IF NOT EXISTS google_analytics (
  ga_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,

  -- GA4 Configuration
  property_id VARCHAR(100), -- GA4 property ID
  measurement_id VARCHAR(100), -- GA4 measurement ID

  -- Daily metrics
  date DATE NOT NULL,
  page_views INTEGER DEFAULT 0,
  unique_users INTEGER DEFAULT 0,
  new_users INTEGER DEFAULT 0,
  sessions INTEGER DEFAULT 0,
  avg_session_duration DECIMAL(10,2), -- seconds
  bounce_rate DECIMAL(5,2), -- percentage

  -- Events
  custom_events JSONB DEFAULT '{}'::jsonb,

  -- Sync metadata
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  sync_status VARCHAR(50) DEFAULT 'success',

  CONSTRAINT unique_product_date UNIQUE(product_id, date)
);

CREATE INDEX idx_ga_product ON google_analytics(product_id);
CREATE INDEX idx_ga_date ON google_analytics(date);
CREATE INDEX idx_ga_synced ON google_analytics(synced_at);

-- ============================================================================
-- AUDIT LOG (Track all changes)
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log (
  log_id SERIAL PRIMARY KEY,
  table_name VARCHAR(100) NOT NULL,
  record_id INTEGER NOT NULL,
  action VARCHAR(50) NOT NULL, -- insert, update, delete
  changed_by VARCHAR(100),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  old_values JSONB,
  new_values JSONB,
  change_summary TEXT
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_changed_by ON audit_log(changed_by);
CREATE INDEX idx_audit_log_changed_at ON audit_log(changed_at);

-- ============================================================================
-- VIEWS (Convenience queries)
-- ============================================================================

-- Product overview with latest status from each stage
CREATE OR REPLACE VIEW vw_product_overview AS
SELECT
  p.product_id,
  p.name,
  p.description,
  p.type,
  p.department,
  p.team,
  p.lifecycle_stage,
  p.current_status,
  p.created_at,
  p.updated_at,

  -- Approval info
  a.approval_id,
  a.status as approval_status,
  a.submitted_by,
  a.submitted_at,
  (a.governance_signoff AND a.technical_signoff AND
   COALESCE(a.security_signoff, TRUE)) as fully_approved,

  -- Audit info
  aud.audit_id,
  aud.audit_type as latest_audit_type,
  aud.status as audit_status,
  aud.overall_score as audit_score,
  aud.completed_at as audit_completed_at,

  -- Deployment info
  d.deployment_id,
  d.platform,
  d.url,
  d.deployed_at,
  d.reconciliation_status,

  -- Review info
  rs.next_review_date,
  rs.frequency_days as review_frequency,

  -- Analytics summary
  (SELECT COUNT(*) FROM google_analytics ga
   WHERE ga.product_id = p.product_id AND ga.date >= CURRENT_DATE - 30) as analytics_days,
  (SELECT SUM(page_views) FROM google_analytics ga
   WHERE ga.product_id = p.product_id AND ga.date >= CURRENT_DATE - 30) as page_views_30d

FROM products p
LEFT JOIN approvals a ON p.product_id = a.product_id
LEFT JOIN LATERAL (
  SELECT * FROM audits
  WHERE product_id = p.product_id
  ORDER BY initiated_at DESC LIMIT 1
) aud ON true
LEFT JOIN LATERAL (
  SELECT * FROM deployments
  WHERE product_id = p.product_id AND is_active = TRUE
  ORDER BY deployed_at DESC LIMIT 1
) d ON true
LEFT JOIN review_schedules rs ON p.product_id = rs.product_id AND rs.active = TRUE;

-- Products needing attention
CREATE OR REPLACE VIEW vw_products_needing_attention AS
SELECT
  p.product_id,
  p.name,
  p.lifecycle_stage,
  'Approval pending' as attention_reason,
  a.submitted_at as date_relevant,
  1 as priority
FROM products p
JOIN approvals a ON p.product_id = a.product_id
WHERE a.status = 'pending' AND p.lifecycle_stage = 'approved'

UNION ALL

SELECT
  p.product_id,
  p.name,
  p.lifecycle_stage,
  'Audit in progress' as attention_reason,
  aud.initiated_at as date_relevant,
  2 as priority
FROM products p
JOIN audits aud ON p.product_id = aud.product_id
WHERE aud.status = 'in_progress' AND p.lifecycle_stage = 'in_audit'

UNION ALL

SELECT
  p.product_id,
  p.name,
  p.lifecycle_stage,
  'Review overdue' as attention_reason,
  rs.next_review_date as date_relevant,
  1 as priority
FROM products p
JOIN review_schedules rs ON p.product_id = rs.product_id
WHERE rs.next_review_date < CURRENT_DATE AND rs.active = TRUE

UNION ALL

SELECT
  p.product_id,
  p.name,
  p.lifecycle_stage,
  'Reconciliation needed' as attention_reason,
  d.last_synced_at as date_relevant,
  3 as priority
FROM products p
JOIN deployments d ON p.product_id = d.product_id
WHERE d.reconciliation_status IN ('discrepancy', 'needs_review')

ORDER BY priority, date_relevant;

-- ============================================================================
-- TRIGGERS (Automatic updates)
-- ============================================================================

-- Update timestamp on row update
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Audit logging trigger
CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log(table_name, record_id, action, new_values)
    VALUES (TG_TABLE_NAME, NEW.product_id, 'insert', to_jsonb(NEW));
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values, new_values)
    VALUES (TG_TABLE_NAME, NEW.product_id, 'update', to_jsonb(OLD), to_jsonb(NEW));
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log(table_name, record_id, action, old_values)
    VALUES (TG_TABLE_NAME, OLD.product_id, 'delete', to_jsonb(OLD));
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_audit_trail
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW
  EXECUTE FUNCTION log_audit_trail();
