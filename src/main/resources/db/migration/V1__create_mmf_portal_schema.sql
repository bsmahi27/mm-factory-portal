CREATE TABLE business_units (
    code text PRIMARY KEY,
    name text NOT NULL UNIQUE,
    has_countries boolean NOT NULL DEFAULT false
);

CREATE TABLE countries (
    name text PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    UNIQUE (name, business_unit_code)
);

CREATE TABLE portal_views (
    name text PRIMARY KEY,
    description text NOT NULL,
    navigation jsonb NOT NULL CHECK (jsonb_typeof(navigation) = 'array')
);

CREATE TABLE roles (
    name text PRIMARY KEY,
    rights_description text NOT NULL,
    portal_view_name text NOT NULL REFERENCES portal_views(name)
);

CREATE TABLE modules (
    name text PRIMARY KEY
);

CREATE TABLE role_permissions (
    role_name text NOT NULL REFERENCES roles(name) ON DELETE CASCADE,
    module_name text NOT NULL REFERENCES modules(name) ON DELETE CASCADE,
    access_level text NOT NULL CHECK (access_level IN ('NONE', 'R', 'RW', 'RW_CERTIFY')),
    PRIMARY KEY (role_name, module_name)
);

CREATE TABLE accounts (
    name text PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    sector text NOT NULL,
    tier smallint NOT NULL CHECK (tier IN (1, 2)),
    owner_name text NOT NULL,
    source text NOT NULL
);

CREATE TABLE prospect_upload_batches (
    id text PRIMARY KEY,
    file_name text NOT NULL,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    uploaded_by text NOT NULL,
    uploaded_at timestamptz NOT NULL,
    row_count integer NOT NULL CHECK (row_count >= 0),
    accepted_count integer NOT NULL CHECK (accepted_count >= 0),
    rejected_count integer NOT NULL CHECK (rejected_count >= 0),
    status text NOT NULL,
    CHECK (accepted_count + rejected_count = row_count)
);

CREATE TABLE prospect_upload_records (
    batch_id text NOT NULL REFERENCES prospect_upload_batches(id) ON DELETE CASCADE,
    row_number integer NOT NULL CHECK (row_number > 0),
    company_name text,
    result text NOT NULL CHECK (result IN ('Accepted', 'Rejected')),
    reason text,
    PRIMARY KEY (batch_id, row_number)
);

CREATE TABLE prospects (
    id text PRIMARY KEY,
    account_name text NOT NULL REFERENCES accounts(name),
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    industry text NOT NULL,
    estimated_tcv_millions numeric(12,2) NOT NULL CHECK (estimated_tcv_millions >= 0),
    lifecycle_stage text NOT NULL CHECK (lifecycle_stage IN (
        'Target Identified', 'Research', 'Outreach',
        'Meetings Scheduled / Delivered', 'Qualified Lead', 'Converted to Opportunity'
    )),
    owner_name text NOT NULL,
    expected_signing_quarter text NOT NULL CHECK (expected_signing_quarter ~ '^Q[1-4]-[0-9]{4}$'),
    source text NOT NULL CHECK (source IN ('Single form', 'Excel upload', 'Radar signal', 'Campaign')),
    upload_batch_id text REFERENCES prospect_upload_batches(id),
    qualification_status text NOT NULL
);

CREATE TABLE prospect_interactions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prospect_id text NOT NULL REFERENCES prospects(id) ON DELETE CASCADE,
    interaction_type text NOT NULL CHECK (interaction_type IN ('Outreach', 'Call', 'Meeting scheduled', 'Meeting delivered')),
    interaction_date date NOT NULL,
    seller_name text NOT NULL,
    notes text NOT NULL,
    next_action text NOT NULL,
    status text NOT NULL CHECK (status IN ('Open', 'Closed')),
    due_date date NOT NULL
);

CREATE TABLE solutions (
    name text PRIMARY KEY,
    solution_class text NOT NULL CHECK (solution_class IN ('Industry', 'Business Line', 'Cross-Business Line')),
    tags text[] NOT NULL DEFAULT '{}',
    maturity text NOT NULL CHECK (maturity IN ('Draft', 'In-Development', 'Industrialized')),
    certification_status text NOT NULL CHECK (certification_status IN ('Draft', 'Submitted', 'Certified & Published')),
    reuse_count integer NOT NULL DEFAULT 0 CHECK (reuse_count >= 0)
);

CREATE TABLE assets (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    asset_type text NOT NULL,
    version text NOT NULL,
    certification_status text NOT NULL CHECK (certification_status IN ('Draft', 'Submitted', 'Certified & Published')),
    solution_name text NOT NULL REFERENCES solutions(name),
    carve_out_ready boolean NOT NULL DEFAULT false,
    UNIQUE (name, version)
);

CREATE TABLE play_templates (
    name text PRIMARY KEY,
    channel text NOT NULL,
    step_count integer NOT NULL CHECK (step_count > 0),
    solution_name text NOT NULL REFERENCES solutions(name)
);

CREATE TABLE radar_engines (
    name text PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    client_count integer NOT NULL CHECK (client_count >= 0),
    rule_count integer NOT NULL CHECK (rule_count >= 0),
    schedule text NOT NULL,
    signal_count integer NOT NULL CHECK (signal_count >= 0)
);

CREATE TABLE campaigns (
    name text PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    status text NOT NULL CHECK (status IN ('Draft', 'Planned', 'Approved', 'Active', 'Paused', 'Closed', 'Review')),
    solution_name text NOT NULL REFERENCES solutions(name),
    radar_engine_name text REFERENCES radar_engines(name),
    owner_name text NOT NULL,
    approver_name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    target_account_count integer NOT NULL CHECK (target_account_count >= 0),
    accounts_reached integer NOT NULL CHECK (accounts_reached >= 0),
    outreach_count integer NOT NULL CHECK (outreach_count >= 0),
    meeting_count integer NOT NULL CHECK (meeting_count >= 0),
    pipeline_millions numeric(12,2) NOT NULL CHECK (pipeline_millions >= 0),
    opportunities_generated integer NOT NULL CHECK (opportunities_generated >= 0),
    wins_millions numeric(12,2) NOT NULL CHECK (wins_millions >= 0),
    signal_driven boolean NOT NULL,
    CHECK (end_date >= start_date),
    CHECK (accounts_reached <= target_account_count)
);

CREATE TABLE campaign_playbook_parts (
    name text PRIMARY KEY,
    description text NOT NULL,
    display_order smallint NOT NULL UNIQUE CHECK (display_order > 0)
);

CREATE TABLE uploaded_target_accounts (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    sector text NOT NULL,
    campaign_name text NOT NULL REFERENCES campaigns(name) ON DELETE CASCADE,
    owner_name text NOT NULL,
    salesforce_account_id text,
    match_confidence text NOT NULL CHECK (match_confidence IN ('Low', 'Medium', 'High')),
    UNIQUE (name, campaign_name)
);

CREATE TABLE campaign_history (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    campaign_name text NOT NULL REFERENCES campaigns(name) ON DELETE CASCADE,
    changed_at timestamptz NOT NULL,
    changed_by text NOT NULL,
    change_description text NOT NULL
);

CREATE TABLE opportunities (
    id text PRIMARY KEY,
    name text NOT NULL,
    account_name text NOT NULL REFERENCES accounts(name),
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    industry text NOT NULL,
    value_millions numeric(12,2) NOT NULL CHECK (value_millions >= 0),
    stage text NOT NULL,
    owner_name text NOT NULL,
    close_date date NOT NULL,
    status text NOT NULL CHECK (status IN ('Open', 'Won', 'Lost')),
    is_mm_factory boolean NOT NULL DEFAULT false,
    solution_name text REFERENCES solutions(name),
    probability_percent smallint NOT NULL CHECK (probability_percent BETWEEN 0 AND 100),
    competitor text,
    prospect_id text UNIQUE REFERENCES prospects(id)
);

CREATE TABLE radar_signals (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    account_name text NOT NULL REFERENCES accounts(name),
    radar_engine_name text NOT NULL REFERENCES radar_engines(name),
    title text NOT NULL,
    source text NOT NULL,
    score smallint NOT NULL CHECK (score BETWEEN 0 AND 100),
    severity text NOT NULL CHECK (severity IN ('Low', 'Medium', 'High')),
    status text NOT NULL CHECK (status IN ('New', 'Reviewed', 'Dismissed')),
    summary text NOT NULL,
    UNIQUE (account_name, title)
);

CREATE TABLE data_source_connectors (
    name text PRIMARY KEY,
    connector_type text NOT NULL,
    credential_reference text,
    license_terms text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    used_by text[] NOT NULL DEFAULT '{}'
);

CREATE TABLE smart_agents (
    name text PRIMARY KEY,
    lifecycle_stage text NOT NULL,
    agent_type text NOT NULL CHECK (agent_type IN ('Internal', 'External')),
    status text NOT NULL CHECK (status IN ('Published', 'In-Test', 'Draft', 'Retired')),
    version text NOT NULL,
    description text NOT NULL,
    grounding_sources text[] NOT NULL DEFAULT '{}'
);

CREATE TABLE agent_usage_metrics (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name text NOT NULL REFERENCES smart_agents(name) ON DELETE CASCADE,
    measured_at timestamptz NOT NULL,
    invocation_count integer NOT NULL CHECK (invocation_count >= 0),
    distinct_user_count integer NOT NULL CHECK (distinct_user_count >= 0),
    average_rating numeric(2,1) NOT NULL CHECK (average_rating BETWEEN 0 AND 5),
    output_count integer NOT NULL CHECK (output_count >= 0),
    invocations_by_business_unit jsonb NOT NULL,
    invocations_by_country jsonb NOT NULL,
    invocations_by_role jsonb NOT NULL,
    trend text NOT NULL,
    feedback text NOT NULL,
    UNIQUE (agent_name, measured_at)
);

CREATE TABLE governance_councils (
    name text PRIMARY KEY,
    cadence text NOT NULL,
    scope text NOT NULL CHECK (scope IN ('SBU', 'BU')),
    next_meeting_date date NOT NULL,
    chair_role text NOT NULL,
    decision_count integer NOT NULL CHECK (decision_count >= 0),
    action_count integer NOT NULL CHECK (action_count >= 0)
);

CREATE TABLE governance_meetings (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    council_name text NOT NULL REFERENCES governance_councils(name),
    meeting_date date NOT NULL,
    attendees text NOT NULL,
    notes text NOT NULL,
    decision_count integer NOT NULL CHECK (decision_count >= 0),
    action_count integer NOT NULL CHECK (action_count >= 0),
    UNIQUE (council_name, meeting_date)
);

CREATE TABLE governance_decisions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    decision text NOT NULL,
    owner_name text NOT NULL,
    decision_date date NOT NULL,
    status text NOT NULL CHECK (status IN ('Open', 'Ratified')),
    reference_type text
);

CREATE TABLE governance_actions (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action text NOT NULL,
    owner_name text NOT NULL,
    due_date date NOT NULL,
    status text NOT NULL CHECK (status IN ('Open', 'Closed'))
);

CREATE TABLE raci_assignments (
    activity text PRIMARY KEY,
    responsible text NOT NULL,
    accountable text NOT NULL,
    consulted text NOT NULL,
    informed text NOT NULL
);

CREATE TABLE mvp_outcomes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    outcome text NOT NULL UNIQUE,
    status text NOT NULL
);

CREATE TABLE reference_data (
    category text PRIMARY KEY,
    values_text text NOT NULL,
    governance_status text NOT NULL
);

CREATE TABLE kpi_definitions (
    name text PRIMARY KEY,
    unit text NOT NULL,
    definition text NOT NULL,
    dimensions text[] NOT NULL
);

CREATE TABLE kpi_snapshots (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    as_of timestamptz NOT NULL,
    business_unit_code text NOT NULL REFERENCES business_units(code),
    country_name text REFERENCES countries(name),
    pipeline_millions numeric(12,2) NOT NULL,
    revenue_millions numeric(12,2) NOT NULL,
    coverage_percent numeric(5,2) NOT NULL CHECK (coverage_percent BETWEEN 0 AND 100),
    reuse_percent numeric(5,2) NOT NULL CHECK (reuse_percent BETWEEN 0 AND 100),
    signal_count integer NOT NULL,
    signal_conversion_percent numeric(5,2) NOT NULL CHECK (signal_conversion_percent BETWEEN 0 AND 100),
    outreach_count integer NOT NULL,
    meeting_count integer NOT NULL,
    opportunities_created integer NOT NULL,
    stage_conversion_percent numeric(5,2) NOT NULL CHECK (stage_conversion_percent BETWEEN 0 AND 100),
    pipeline_target_millions numeric(12,2) NOT NULL,
    revenue_target_millions numeric(12,2) NOT NULL,
    coverage_target_percent numeric(5,2) NOT NULL CHECK (coverage_target_percent BETWEEN 0 AND 100),
    UNIQUE (as_of, business_unit_code, country_name)
);

CREATE TABLE audit_events (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at timestamptz NOT NULL,
    actor_name text NOT NULL,
    action text NOT NULL,
    event_details text NOT NULL
);

CREATE INDEX prospects_scope_idx ON prospects (business_unit_code, country_name, lifecycle_stage);
CREATE INDEX opportunities_scope_idx ON opportunities (business_unit_code, country_name, status);
CREATE INDEX campaigns_scope_idx ON campaigns (business_unit_code, country_name, status);
CREATE INDEX radar_signals_scope_idx ON radar_signals (business_unit_code, country_name, status, score DESC);
CREATE INDEX interactions_prospect_date_idx ON prospect_interactions (prospect_id, interaction_date DESC);
CREATE INDEX audit_events_occurred_at_idx ON audit_events (occurred_at DESC);