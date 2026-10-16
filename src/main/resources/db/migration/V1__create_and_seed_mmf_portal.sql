-- MMF Portal baseline: schema, tables, keys, indexes and seed data.

-- ===== Schema and tables =====
CREATE SCHEMA IF NOT EXISTS mmf_portal;

CREATE TABLE mmf_portal.audit_events (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    actor_name text NOT NULL,
    action text NOT NULL,
    event_details text NOT NULL,
    CONSTRAINT audit_events_pkey PRIMARY KEY (id)
);

CREATE TABLE mmf_portal.business_units (
    code text NOT NULL,
    name text NOT NULL,
    has_countries boolean DEFAULT false NOT NULL,
    CONSTRAINT business_units_pkey PRIMARY KEY (code),
    CONSTRAINT business_units_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.campaign_playbook_parts (
    name text NOT NULL,
    description text NOT NULL,
    display_order smallint NOT NULL,
    CONSTRAINT campaign_playbook_parts_display_order_check CHECK ((display_order > 0)),
    CONSTRAINT campaign_playbook_parts_pkey PRIMARY KEY (name),
    CONSTRAINT campaign_playbook_parts_display_order_key UNIQUE (display_order)
);

CREATE TABLE mmf_portal.countries (
    name text NOT NULL,
    business_unit_code text NOT NULL,
    CONSTRAINT countries_pkey PRIMARY KEY (name),
    CONSTRAINT countries_name_business_unit_code_key UNIQUE (name, business_unit_code),
    CONSTRAINT countries_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code)
);

CREATE TABLE mmf_portal.data_source_connectors (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    connector_type text NOT NULL,
    credential_reference text,
    license_terms text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    used_by text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT data_source_connectors_pkey PRIMARY KEY (id),
    CONSTRAINT data_source_connectors_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.governance_actions (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    action text NOT NULL,
    owner_name text NOT NULL,
    due_date date NOT NULL,
    status text NOT NULL,
    CONSTRAINT governance_actions_status_check CHECK ((status = ANY (ARRAY['Open'::text, 'Closed'::text]))),
    CONSTRAINT governance_actions_pkey PRIMARY KEY (id)
);

CREATE TABLE mmf_portal.governance_councils (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    cadence text NOT NULL,
    scope text NOT NULL,
    next_meeting_date date NOT NULL,
    chair_role text NOT NULL,
    decision_count integer NOT NULL,
    action_count integer NOT NULL,
    CONSTRAINT governance_councils_action_count_check CHECK ((action_count >= 0)),
    CONSTRAINT governance_councils_decision_count_check CHECK ((decision_count >= 0)),
    CONSTRAINT governance_councils_scope_check CHECK ((scope = ANY (ARRAY['SBU'::text, 'BU'::text]))),
    CONSTRAINT governance_councils_pkey PRIMARY KEY (id),
    CONSTRAINT governance_councils_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.governance_decisions (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    decision text NOT NULL,
    owner_name text NOT NULL,
    decision_date date NOT NULL,
    status text NOT NULL,
    reference_type text,
    CONSTRAINT governance_decisions_status_check CHECK ((status = ANY (ARRAY['Open'::text, 'Ratified'::text]))),
    CONSTRAINT governance_decisions_pkey PRIMARY KEY (id)
);

CREATE TABLE mmf_portal.governance_meetings (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    meeting_date date NOT NULL,
    attendees text NOT NULL,
    notes text NOT NULL,
    decision_count integer NOT NULL,
    action_count integer NOT NULL,
    council_id bigint NOT NULL,
    CONSTRAINT governance_meetings_action_count_check CHECK ((action_count >= 0)),
    CONSTRAINT governance_meetings_decision_count_check CHECK ((decision_count >= 0)),
    CONSTRAINT governance_meetings_pkey PRIMARY KEY (id),
    CONSTRAINT governance_meetings_council_id_meeting_date_key UNIQUE (council_id, meeting_date),
    CONSTRAINT governance_meetings_council_id_fkey FOREIGN KEY (council_id) REFERENCES mmf_portal.governance_councils(id)
);

CREATE TABLE mmf_portal.kpi_definitions (
    name text NOT NULL,
    unit text NOT NULL,
    definition text NOT NULL,
    dimensions text[] NOT NULL,
    CONSTRAINT kpi_definitions_pkey PRIMARY KEY (name)
);

CREATE TABLE mmf_portal.kpi_snapshots (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    as_of timestamp with time zone NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    pipeline_millions numeric(12,2) NOT NULL,
    revenue_millions numeric(12,2) NOT NULL,
    coverage_percent numeric(5,2) NOT NULL,
    reuse_percent numeric(5,2) NOT NULL,
    signal_count integer NOT NULL,
    signal_conversion_percent numeric(5,2) NOT NULL,
    outreach_count integer NOT NULL,
    meeting_count integer NOT NULL,
    opportunities_created integer NOT NULL,
    stage_conversion_percent numeric(5,2) NOT NULL,
    pipeline_target_millions numeric(12,2) NOT NULL,
    revenue_target_millions numeric(12,2) NOT NULL,
    coverage_target_percent numeric(5,2) NOT NULL,
    client_count integer,
    target_account_count integer,
    active_account_count integer,
    active_campaign_count integer,
    active_partner_play_count integer,
    key_asset_count integer,
    smart_agent_count integer,
    qualified_lead_count integer,
    bookings_target_millions numeric(12,2),
    CONSTRAINT kpi_snapshots_coverage_percent_check CHECK (((coverage_percent >= (0)::numeric) AND (coverage_percent <= (100)::numeric))),
    CONSTRAINT kpi_snapshots_coverage_target_percent_check CHECK (((coverage_target_percent >= (0)::numeric) AND (coverage_target_percent <= (100)::numeric))),
    CONSTRAINT kpi_snapshots_reuse_percent_check CHECK (((reuse_percent >= (0)::numeric) AND (reuse_percent <= (100)::numeric))),
    CONSTRAINT kpi_snapshots_signal_conversion_percent_check CHECK (((signal_conversion_percent >= (0)::numeric) AND (signal_conversion_percent <= (100)::numeric))),
    CONSTRAINT kpi_snapshots_stage_conversion_percent_check CHECK (((stage_conversion_percent >= (0)::numeric) AND (stage_conversion_percent <= (100)::numeric))),
    CONSTRAINT kpi_snapshots_pkey PRIMARY KEY (id),
    CONSTRAINT kpi_snapshots_as_of_business_unit_code_country_name_key UNIQUE (as_of, business_unit_code, country_name),
    CONSTRAINT kpi_snapshots_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT kpi_snapshots_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name)
);

CREATE TABLE mmf_portal.modules (
    name text NOT NULL,
    CONSTRAINT modules_pkey PRIMARY KEY (name)
);

CREATE TABLE mmf_portal.mvp_outcomes (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    outcome text NOT NULL,
    status text NOT NULL,
    CONSTRAINT mvp_outcomes_pkey PRIMARY KEY (id),
    CONSTRAINT mvp_outcomes_outcome_key UNIQUE (outcome)
);

CREATE TABLE mmf_portal.partner_plays (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    partner_name text NOT NULL,
    partner_tier text NOT NULL,
    business_line text NOT NULL,
    theme text NOT NULL,
    eligible_country_codes text[] NOT NULL,
    status text NOT NULL,
    value_proposition text NOT NULL,
    influenced_pipeline_millions numeric(12,2) DEFAULT 0 NOT NULL,
    linked_campaign_count integer DEFAULT 0 NOT NULL,
    owner_name text NOT NULL,
    CONSTRAINT partner_plays_influenced_pipeline_millions_check CHECK ((influenced_pipeline_millions >= (0)::numeric)),
    CONSTRAINT partner_plays_linked_campaign_count_check CHECK ((linked_campaign_count >= 0)),
    CONSTRAINT partner_plays_status_check CHECK ((status = ANY (ARRAY['Draft'::text, 'Active'::text, 'Paused'::text, 'Closed'::text]))),
    CONSTRAINT partner_plays_pkey PRIMARY KEY (id),
    CONSTRAINT partner_plays_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.portal_views (
    name text NOT NULL,
    description text NOT NULL,
    navigation jsonb NOT NULL,
    CONSTRAINT portal_views_navigation_check CHECK ((jsonb_typeof(navigation) = 'array'::text)),
    CONSTRAINT portal_views_pkey PRIMARY KEY (name)
);

CREATE TABLE mmf_portal.prospect_upload_batches (
    id text NOT NULL,
    file_name text NOT NULL,
    business_unit_code text NOT NULL,
    uploaded_by text NOT NULL,
    uploaded_at timestamp with time zone NOT NULL,
    row_count integer NOT NULL,
    accepted_count integer NOT NULL,
    rejected_count integer NOT NULL,
    status text NOT NULL,
    CONSTRAINT prospect_upload_batches_accepted_count_check CHECK ((accepted_count >= 0)),
    CONSTRAINT prospect_upload_batches_check CHECK (((accepted_count + rejected_count) = row_count)),
    CONSTRAINT prospect_upload_batches_rejected_count_check CHECK ((rejected_count >= 0)),
    CONSTRAINT prospect_upload_batches_row_count_check CHECK ((row_count >= 0)),
    CONSTRAINT prospect_upload_batches_pkey PRIMARY KEY (id),
    CONSTRAINT prospect_upload_batches_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code)
);

CREATE TABLE mmf_portal.prospect_upload_records (
    batch_id text NOT NULL,
    row_number integer NOT NULL,
    company_name text,
    result text NOT NULL,
    reason text,
    CONSTRAINT prospect_upload_records_result_check CHECK ((result = ANY (ARRAY['Accepted'::text, 'Rejected'::text]))),
    CONSTRAINT prospect_upload_records_row_number_check CHECK ((row_number > 0)),
    CONSTRAINT prospect_upload_records_pkey PRIMARY KEY (batch_id, row_number),
    CONSTRAINT prospect_upload_records_batch_id_fkey FOREIGN KEY (batch_id) REFERENCES mmf_portal.prospect_upload_batches(id) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.raci_assignments (
    activity text NOT NULL,
    responsible text NOT NULL,
    accountable text NOT NULL,
    consulted text NOT NULL,
    informed text NOT NULL,
    CONSTRAINT raci_assignments_pkey PRIMARY KEY (activity)
);

CREATE TABLE mmf_portal.radar_engines (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    business_unit_code text NOT NULL,
    client_count integer NOT NULL,
    rule_count integer NOT NULL,
    schedule text NOT NULL,
    signal_count integer NOT NULL,
    prospect_set text DEFAULT 'Target prospects'::text NOT NULL,
    source_keys text[] DEFAULT '{}'::text[] NOT NULL,
    frequency text DEFAULT 'Daily'::text NOT NULL,
    run_at text DEFAULT '05:00 CET'::text NOT NULL,
    lookback_days integer DEFAULT 14 NOT NULL,
    minimum_score smallint DEFAULT 70 NOT NULL,
    auto_link_campaigns boolean DEFAULT true NOT NULL,
    CONSTRAINT radar_engines_client_count_check CHECK ((client_count >= 0)),
    CONSTRAINT radar_engines_lookback_days_check CHECK ((lookback_days > 0)),
    CONSTRAINT radar_engines_minimum_score_check CHECK (((minimum_score >= 0) AND (minimum_score <= 100))),
    CONSTRAINT radar_engines_prospect_set_check CHECK ((prospect_set = ANY (ARRAY['Target prospects'::text, 'Active campaign accounts'::text, 'Qualified leads'::text, 'Full mid-market master'::text, 'Custom upload'::text]))),
    CONSTRAINT radar_engines_rule_count_check CHECK ((rule_count >= 0)),
    CONSTRAINT radar_engines_signal_count_check CHECK ((signal_count >= 0)),
    CONSTRAINT radar_engines_pkey PRIMARY KEY (id),
    CONSTRAINT radar_engines_name_key UNIQUE (name),
    CONSTRAINT radar_engines_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code)
);

CREATE TABLE mmf_portal.radar_runs (
    id uuid NOT NULL,
    status text NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    failure_message text,
    radar_engine_id bigint NOT NULL,
    CONSTRAINT radar_runs_status_check CHECK ((status = ANY (ARRAY['Accepted'::text, 'Running'::text, 'Completed'::text, 'Failed'::text]))),
    CONSTRAINT radar_runs_pkey PRIMARY KEY (id),
    CONSTRAINT radar_runs_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines(id) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.reference_data (
    category text NOT NULL,
    values_text text NOT NULL,
    governance_status text NOT NULL,
    CONSTRAINT reference_data_pkey PRIMARY KEY (category)
);

CREATE TABLE mmf_portal.roles (
    name text NOT NULL,
    rights_description text NOT NULL,
    portal_view_name text NOT NULL,
    CONSTRAINT roles_pkey PRIMARY KEY (name),
    CONSTRAINT roles_portal_view_name_fkey FOREIGN KEY (portal_view_name) REFERENCES mmf_portal.portal_views(name)
);

CREATE TABLE mmf_portal.smart_agents (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    lifecycle_stage text NOT NULL,
    agent_type text NOT NULL,
    status text NOT NULL,
    version text NOT NULL,
    description text NOT NULL,
    grounding_sources text[] DEFAULT '{}'::text[] NOT NULL,
    owner_team text,
    best_used_for text,
    launches_this_quarter integer DEFAULT 0 NOT NULL,
    platform text,
    launch_url text,
    visibility_scopes text[] DEFAULT '{}'::text[] NOT NULL,
    recommended_trigger_categories text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT smart_agents_agent_type_check CHECK ((agent_type = ANY (ARRAY['Internal'::text, 'External'::text]))),
    CONSTRAINT smart_agents_launches_this_quarter_check CHECK ((launches_this_quarter >= 0)),
    CONSTRAINT smart_agents_status_check CHECK ((status = ANY (ARRAY['Published'::text, 'In-Test'::text, 'Draft'::text, 'Retired'::text]))),
    CONSTRAINT smart_agents_pkey PRIMARY KEY (id),
    CONSTRAINT smart_agents_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.solutions (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    solution_class text NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    maturity text NOT NULL,
    certification_status text NOT NULL,
    reuse_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT solutions_certification_status_check CHECK ((certification_status = ANY (ARRAY['Draft'::text, 'Submitted'::text, 'Certified & Published'::text]))),
    CONSTRAINT solutions_maturity_check CHECK ((maturity = ANY (ARRAY['Draft'::text, 'In-Development'::text, 'Industrialized'::text]))),
    CONSTRAINT solutions_reuse_count_check CHECK ((reuse_count >= 0)),
    CONSTRAINT solutions_solution_class_check CHECK ((solution_class = ANY (ARRAY['Industry'::text, 'Business Line'::text, 'Cross-Business Line'::text]))),
    CONSTRAINT solutions_pkey PRIMARY KEY (id),
    CONSTRAINT solutions_name_key UNIQUE (name)
);

CREATE TABLE mmf_portal.accounts (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    sector text NOT NULL,
    tier smallint NOT NULL,
    owner_name text NOT NULL,
    source text NOT NULL,
    CONSTRAINT accounts_tier_check CHECK ((tier = ANY (ARRAY[1, 2]))),
    CONSTRAINT accounts_pkey PRIMARY KEY (id),
    CONSTRAINT accounts_name_key UNIQUE (name),
    CONSTRAINT accounts_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT accounts_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name)
);

CREATE TABLE mmf_portal.agent_usage_metrics (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    measured_at timestamp with time zone NOT NULL,
    invocation_count integer NOT NULL,
    distinct_user_count integer NOT NULL,
    average_rating numeric(2,1) NOT NULL,
    output_count integer NOT NULL,
    invocations_by_business_unit jsonb NOT NULL,
    invocations_by_country jsonb NOT NULL,
    invocations_by_role jsonb NOT NULL,
    trend text NOT NULL,
    feedback text NOT NULL,
    agent_id bigint NOT NULL,
    CONSTRAINT agent_usage_metrics_average_rating_check CHECK (((average_rating >= (0)::numeric) AND (average_rating <= (5)::numeric))),
    CONSTRAINT agent_usage_metrics_distinct_user_count_check CHECK ((distinct_user_count >= 0)),
    CONSTRAINT agent_usage_metrics_invocation_count_check CHECK ((invocation_count >= 0)),
    CONSTRAINT agent_usage_metrics_output_count_check CHECK ((output_count >= 0)),
    CONSTRAINT agent_usage_metrics_pkey PRIMARY KEY (id),
    CONSTRAINT agent_usage_metrics_agent_id_measured_at_key UNIQUE (agent_id, measured_at),
    CONSTRAINT agent_usage_metrics_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES mmf_portal.smart_agents(id) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.assets (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    asset_type text NOT NULL,
    version text NOT NULL,
    certification_status text NOT NULL,
    carve_out_ready boolean DEFAULT false NOT NULL,
    source_type text DEFAULT 'Repository link'::text NOT NULL,
    repository_name text,
    source_url text,
    owner_name text DEFAULT 'Unassigned'::text NOT NULL,
    refresh_cycle_months integer DEFAULT 12 NOT NULL,
    last_reviewed_at date,
    next_review_at date,
    lifecycle_state text DEFAULT 'Draft'::text NOT NULL,
    visibility_scopes text[] DEFAULT '{}'::text[] NOT NULL,
    solution_id bigint NOT NULL,
    CONSTRAINT assets_certification_status_check CHECK ((certification_status = ANY (ARRAY['Draft'::text, 'Submitted'::text, 'Certified & Published'::text]))),
    CONSTRAINT assets_lifecycle_state_check CHECK ((lifecycle_state = ANY (ARRAY['Draft'::text, 'Submitted'::text, 'Certified'::text, 'In refresh'::text, 'Re-certified'::text, 'Retired'::text]))),
    CONSTRAINT assets_refresh_cycle_months_check CHECK ((refresh_cycle_months > 0)),
    CONSTRAINT assets_source_type_check CHECK ((source_type = ANY (ARRAY['Uploaded file'::text, 'Repository link'::text, 'External link'::text]))),
    CONSTRAINT assets_pkey PRIMARY KEY (id),
    CONSTRAINT assets_name_version_key UNIQUE (name, version),
    CONSTRAINT assets_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions(id)
);

CREATE TABLE mmf_portal.campaigns (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    status text NOT NULL,
    owner_name text NOT NULL,
    approver_name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    target_account_count integer NOT NULL,
    accounts_reached integer NOT NULL,
    outreach_count integer NOT NULL,
    meeting_count integer NOT NULL,
    pipeline_millions numeric(12,2) NOT NULL,
    opportunities_generated integer NOT NULL,
    wins_millions numeric(12,2) NOT NULL,
    signal_driven boolean NOT NULL,
    business_line text,
    theme text,
    partner_name text,
    campaign_description text,
    meetings_booked integer DEFAULT 0 NOT NULL,
    qualified_leads integer DEFAULT 0 NOT NULL,
    cxo_reach integer DEFAULT 0 NOT NULL,
    inbound_count integer DEFAULT 0 NOT NULL,
    audience_reach integer DEFAULT 0 NOT NULL,
    bookings_millions numeric(12,2) DEFAULT 0 NOT NULL,
    revenue_won_millions numeric(12,2) DEFAULT 0 NOT NULL,
    solution_id bigint NOT NULL,
    radar_engine_id bigint,
    CONSTRAINT campaigns_accounts_reached_check CHECK ((accounts_reached >= 0)),
    CONSTRAINT campaigns_audience_reach_check CHECK ((audience_reach >= 0)),
    CONSTRAINT campaigns_bookings_millions_check CHECK ((bookings_millions >= (0)::numeric)),
    CONSTRAINT campaigns_check CHECK ((end_date >= start_date)),
    CONSTRAINT campaigns_check1 CHECK ((accounts_reached <= target_account_count)),
    CONSTRAINT campaigns_cxo_reach_check CHECK ((cxo_reach >= 0)),
    CONSTRAINT campaigns_inbound_count_check CHECK ((inbound_count >= 0)),
    CONSTRAINT campaigns_meeting_count_check CHECK ((meeting_count >= 0)),
    CONSTRAINT campaigns_meetings_booked_check CHECK ((meetings_booked >= 0)),
    CONSTRAINT campaigns_opportunities_generated_check CHECK ((opportunities_generated >= 0)),
    CONSTRAINT campaigns_outreach_count_check CHECK ((outreach_count >= 0)),
    CONSTRAINT campaigns_pipeline_millions_check CHECK ((pipeline_millions >= (0)::numeric)),
    CONSTRAINT campaigns_qualified_leads_check CHECK ((qualified_leads >= 0)),
    CONSTRAINT campaigns_revenue_won_millions_check CHECK ((revenue_won_millions >= (0)::numeric)),
    CONSTRAINT campaigns_status_check CHECK ((status = ANY (ARRAY['Draft'::text, 'Planned'::text, 'Approved'::text, 'Active'::text, 'Paused'::text, 'Closed'::text, 'Review'::text]))),
    CONSTRAINT campaigns_target_account_count_check CHECK ((target_account_count >= 0)),
    CONSTRAINT campaigns_wins_millions_check CHECK ((wins_millions >= (0)::numeric)),
    CONSTRAINT campaigns_pkey PRIMARY KEY (id),
    CONSTRAINT campaigns_name_key UNIQUE (name),
    CONSTRAINT campaigns_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT campaigns_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name),
    CONSTRAINT campaigns_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines(id),
    CONSTRAINT campaigns_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions(id)
);

CREATE TABLE mmf_portal.play_templates (
    name text NOT NULL,
    channel text NOT NULL,
    step_count integer NOT NULL,
    solution_id bigint NOT NULL,
    CONSTRAINT play_templates_step_count_check CHECK ((step_count > 0)),
    CONSTRAINT play_templates_pkey PRIMARY KEY (name),
    CONSTRAINT play_templates_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions(id)
);

CREATE TABLE mmf_portal.prospects (
    id text NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    industry text NOT NULL,
    estimated_tcv_millions numeric(12,2) NOT NULL,
    lifecycle_stage text NOT NULL,
    owner_name text NOT NULL,
    expected_signing_quarter text NOT NULL,
    source text NOT NULL,
    upload_batch_id text,
    qualification_status text NOT NULL,
    account_id bigint NOT NULL,
    CONSTRAINT prospects_estimated_tcv_millions_check CHECK ((estimated_tcv_millions >= (0)::numeric)),
    CONSTRAINT prospects_expected_signing_quarter_check CHECK ((expected_signing_quarter ~ '^Q[1-4]-[0-9]{4}$'::text)),
    CONSTRAINT prospects_lifecycle_stage_check CHECK ((lifecycle_stage = ANY (ARRAY['Target Identified'::text, 'Research'::text, 'Outreach'::text, 'Meetings Scheduled / Delivered'::text, 'Qualified Lead'::text, 'Converted to Opportunity'::text]))),
    CONSTRAINT prospects_source_check CHECK ((source = ANY (ARRAY['Single form'::text, 'Excel upload'::text, 'Radar signal'::text, 'Campaign'::text]))),
    CONSTRAINT prospects_pkey PRIMARY KEY (id),
    CONSTRAINT prospects_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts(id),
    CONSTRAINT prospects_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT prospects_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name),
    CONSTRAINT prospects_upload_batch_id_fkey FOREIGN KEY (upload_batch_id) REFERENCES mmf_portal.prospect_upload_batches(id)
);

CREATE TABLE mmf_portal.radar_signals (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    title text NOT NULL,
    source text NOT NULL,
    score smallint NOT NULL,
    severity text NOT NULL,
    status text NOT NULL,
    summary text NOT NULL,
    signal_category text,
    published_at date,
    opportunity_hypothesis text,
    recommended_agents text[] DEFAULT '{}'::text[] NOT NULL,
    recommended_action text,
    scoring_inputs jsonb DEFAULT '{}'::jsonb NOT NULL,
    account_id bigint NOT NULL,
    radar_engine_id bigint NOT NULL,
    CONSTRAINT radar_signals_score_check CHECK (((score >= 0) AND (score <= 100))),
    CONSTRAINT radar_signals_severity_check CHECK ((severity = ANY (ARRAY['Low'::text, 'Medium'::text, 'High'::text, 'Critical'::text]))),
    CONSTRAINT radar_signals_status_check CHECK ((status = ANY (ARRAY['New'::text, 'Reviewed'::text, 'Dismissed'::text]))),
    CONSTRAINT radar_signals_pkey PRIMARY KEY (id),
    CONSTRAINT radar_signals_account_id_title_key UNIQUE (account_id, title),
    CONSTRAINT radar_signals_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts(id),
    CONSTRAINT radar_signals_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT radar_signals_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name),
    CONSTRAINT radar_signals_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines(id)
);

CREATE TABLE mmf_portal.role_permissions (
    role_name text NOT NULL,
    module_name text NOT NULL,
    access_level text NOT NULL,
    CONSTRAINT role_permissions_access_level_check CHECK ((access_level = ANY (ARRAY['NONE'::text, 'R'::text, 'RW'::text, 'RW_CERTIFY'::text]))),
    CONSTRAINT role_permissions_pkey PRIMARY KEY (role_name, module_name),
    CONSTRAINT role_permissions_module_name_fkey FOREIGN KEY (module_name) REFERENCES mmf_portal.modules(name) ON DELETE CASCADE,
    CONSTRAINT role_permissions_role_name_fkey FOREIGN KEY (role_name) REFERENCES mmf_portal.roles(name) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.uploaded_target_accounts (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    name text NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    sector text NOT NULL,
    owner_name text NOT NULL,
    salesforce_account_id text,
    match_confidence text NOT NULL,
    campaign_id bigint NOT NULL,
    CONSTRAINT uploaded_target_accounts_match_confidence_check CHECK ((match_confidence = ANY (ARRAY['Low'::text, 'Medium'::text, 'High'::text]))),
    CONSTRAINT uploaded_target_accounts_pkey PRIMARY KEY (id),
    CONSTRAINT uploaded_target_accounts_name_campaign_id_key UNIQUE (name, campaign_id),
    CONSTRAINT uploaded_target_accounts_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT uploaded_target_accounts_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns(id) ON DELETE CASCADE,
    CONSTRAINT uploaded_target_accounts_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name)
);

CREATE TABLE mmf_portal.campaign_history (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    changed_at timestamp with time zone NOT NULL,
    changed_by text NOT NULL,
    change_description text NOT NULL,
    campaign_id bigint NOT NULL,
    CONSTRAINT campaign_history_pkey PRIMARY KEY (id),
    CONSTRAINT campaign_history_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns(id) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.campaign_partner_plays (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    linked_by text DEFAULT 'migration'::text NOT NULL,
    campaign_id bigint NOT NULL,
    partner_play_id bigint NOT NULL,
    CONSTRAINT campaign_partner_plays_pkey PRIMARY KEY (id),
    CONSTRAINT campaign_partner_plays_campaign_partner_ids_key UNIQUE (campaign_id, partner_play_id),
    CONSTRAINT campaign_partner_plays_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns(id) ON DELETE CASCADE,
    CONSTRAINT campaign_partner_plays_partner_play_id_fkey FOREIGN KEY (partner_play_id) REFERENCES mmf_portal.partner_plays(id)
);

CREATE TABLE mmf_portal.opportunities (
    id text NOT NULL,
    name text NOT NULL,
    business_unit_code text NOT NULL,
    country_name text,
    industry text NOT NULL,
    value_millions numeric(12,2) NOT NULL,
    stage text NOT NULL,
    owner_name text NOT NULL,
    close_date date NOT NULL,
    status text NOT NULL,
    is_mm_factory boolean DEFAULT false NOT NULL,
    probability_percent smallint NOT NULL,
    competitor text,
    prospect_id text,
    account_id bigint NOT NULL,
    solution_id bigint,
    CONSTRAINT opportunities_probability_percent_check CHECK (((probability_percent >= 0) AND (probability_percent <= 100))),
    CONSTRAINT opportunities_status_check CHECK ((status = ANY (ARRAY['Open'::text, 'Won'::text, 'Lost'::text]))),
    CONSTRAINT opportunities_value_millions_check CHECK ((value_millions >= (0)::numeric)),
    CONSTRAINT opportunities_pkey PRIMARY KEY (id),
    CONSTRAINT opportunities_prospect_id_key UNIQUE (prospect_id),
    CONSTRAINT opportunities_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts(id),
    CONSTRAINT opportunities_business_unit_code_fkey FOREIGN KEY (business_unit_code) REFERENCES mmf_portal.business_units(code),
    CONSTRAINT opportunities_country_name_fkey FOREIGN KEY (country_name) REFERENCES mmf_portal.countries(name),
    CONSTRAINT opportunities_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES mmf_portal.prospects(id),
    CONSTRAINT opportunities_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions(id)
);

CREATE TABLE mmf_portal.prospect_interactions (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    prospect_id text NOT NULL,
    interaction_type text NOT NULL,
    interaction_date date NOT NULL,
    seller_name text NOT NULL,
    notes text NOT NULL,
    next_action text NOT NULL,
    status text NOT NULL,
    due_date date NOT NULL,
    CONSTRAINT prospect_interactions_interaction_type_check CHECK ((interaction_type = ANY (ARRAY['Outreach'::text, 'Call'::text, 'Meeting scheduled'::text, 'Meeting delivered'::text]))),
    CONSTRAINT prospect_interactions_status_check CHECK ((status = ANY (ARRAY['Open'::text, 'Closed'::text]))),
    CONSTRAINT prospect_interactions_pkey PRIMARY KEY (id),
    CONSTRAINT prospect_interactions_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES mmf_portal.prospects(id) ON DELETE CASCADE
);

CREATE TABLE mmf_portal.agent_launches (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    launched_at timestamp with time zone NOT NULL,
    launched_by text NOT NULL,
    prospect_id text,
    opportunity_id text,
    signal_id bigint,
    account_id bigint,
    campaign_id bigint,
    agent_id bigint NOT NULL,
    CONSTRAINT agent_launches_pkey PRIMARY KEY (id),
    CONSTRAINT agent_launches_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts(id),
    CONSTRAINT agent_launches_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES mmf_portal.smart_agents(id),
    CONSTRAINT agent_launches_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns(id),
    CONSTRAINT agent_launches_opportunity_id_fkey FOREIGN KEY (opportunity_id) REFERENCES mmf_portal.opportunities(id),
    CONSTRAINT agent_launches_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES mmf_portal.prospects(id),
    CONSTRAINT agent_launches_signal_id_fkey FOREIGN KEY (signal_id) REFERENCES mmf_portal.radar_signals(id)
);

-- ===== Indexes =====
CREATE INDEX agent_launches_account_id_idx ON mmf_portal.agent_launches USING btree (account_id);
CREATE INDEX agent_launches_agent_id_idx ON mmf_portal.agent_launches USING btree (agent_id);
CREATE INDEX agent_launches_campaign_id_idx ON mmf_portal.agent_launches USING btree (campaign_id);
CREATE INDEX agent_usage_metrics_agent_id_idx ON mmf_portal.agent_usage_metrics USING btree (agent_id);
CREATE INDEX assets_solution_id_idx ON mmf_portal.assets USING btree (solution_id);
CREATE INDEX audit_events_occurred_at_idx ON mmf_portal.audit_events USING btree (occurred_at DESC);
CREATE INDEX campaign_history_campaign_id_idx ON mmf_portal.campaign_history USING btree (campaign_id);
CREATE INDEX campaign_partner_plays_partner_play_id_idx ON mmf_portal.campaign_partner_plays USING btree (partner_play_id);
CREATE INDEX campaigns_radar_engine_id_idx ON mmf_portal.campaigns USING btree (radar_engine_id);
CREATE INDEX campaigns_scope_idx ON mmf_portal.campaigns USING btree (business_unit_code, country_name, status);
CREATE INDEX campaigns_solution_id_idx ON mmf_portal.campaigns USING btree (solution_id);
CREATE INDEX governance_meetings_council_id_idx ON mmf_portal.governance_meetings USING btree (council_id);
CREATE INDEX interactions_prospect_date_idx ON mmf_portal.prospect_interactions USING btree (prospect_id, interaction_date DESC);
CREATE INDEX opportunities_account_id_idx ON mmf_portal.opportunities USING btree (account_id);
CREATE INDEX opportunities_scope_idx ON mmf_portal.opportunities USING btree (business_unit_code, country_name, status);
CREATE INDEX opportunities_solution_id_idx ON mmf_portal.opportunities USING btree (solution_id);
CREATE INDEX play_templates_solution_id_idx ON mmf_portal.play_templates USING btree (solution_id);
CREATE INDEX prospects_account_id_idx ON mmf_portal.prospects USING btree (account_id);
CREATE INDEX prospects_scope_idx ON mmf_portal.prospects USING btree (business_unit_code, country_name, lifecycle_stage);
CREATE INDEX radar_runs_radar_engine_id_idx ON mmf_portal.radar_runs USING btree (radar_engine_id);
CREATE INDEX radar_signals_account_id_idx ON mmf_portal.radar_signals USING btree (account_id);
CREATE INDEX radar_signals_radar_engine_id_idx ON mmf_portal.radar_signals USING btree (radar_engine_id);
CREATE INDEX radar_signals_scope_idx ON mmf_portal.radar_signals USING btree (business_unit_code, country_name, status, score DESC);
CREATE INDEX uploaded_target_accounts_campaign_id_idx ON mmf_portal.uploaded_target_accounts USING btree (campaign_id);

-- ===== Trigger radar and event publication tables =====
-- Trigger radar ingestion and read-model tables
CREATE TABLE mmf_portal.trigger_ingestion (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trigger_id uuid NOT NULL,
    country text,
    account_name text,
    sector text,
    trigger_category text,
    relevance text,
    news_headline text,
    news_summary text,
    source_name text,
    source_url text,
    published_date date,
    recommended_action text,
    recommended_agent text,
    researcher text,
    validation_status text,
    reviewer_comments text,
    imported_at timestamp
);
CREATE INDEX trigger_ingestion_trigger_id_idx ON mmf_portal.trigger_ingestion (trigger_id);
CREATE TABLE mmf_portal.trigger_read_model (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trigger_id uuid,
    country text,
    account_name text,
    sector text,
    trigger_category text,
    relevance text,
    news_headline text,
    news_summary text,
    source_name text,
    source_url text,
    published_date date,
    recommended_action text,
    recommended_agent text,
    researcher text,
    validation_status text,
    reviewer_comments text,
    processed_at timestamp
);
CREATE INDEX trigger_read_model_trigger_id_idx ON mmf_portal.trigger_read_model (trigger_id);
-- Spring Modulith event publication tables
CREATE TABLE mmf_portal.event_publication (
    id uuid PRIMARY KEY,
    publication_date timestamptz NOT NULL,
    listener_id text NOT NULL,
    serialized_event text NOT NULL,
    event_type text NOT NULL,
    completion_date timestamptz,
    last_resubmission_date timestamptz,
    completion_attempts integer NOT NULL DEFAULT 0,
    status text
);
CREATE TABLE mmf_portal.event_publication_archive (
    id uuid PRIMARY KEY,
    publication_date timestamptz NOT NULL,
    listener_id text NOT NULL,
    serialized_event text NOT NULL,
    event_type text NOT NULL,
    completion_date timestamptz,
    last_resubmission_date timestamptz,
    completion_attempts integer NOT NULL DEFAULT 0,
    status text
);

-- ===== Seed data =====
INSERT INTO mmf_portal.business_units (code, name, has_countries) VALUES
	('UK', 'UK', false),
	('DE', 'Germany', false),
	('NL', 'Netherlands', false),
	('NO', 'Nordics', true);

INSERT INTO mmf_portal.countries (name, business_unit_code) VALUES
	('Sweden', 'NO'),
	('Finland', 'NO'),
	('Norway', 'NO'),
	('Denmark', 'NO');

INSERT INTO mmf_portal.accounts (name, business_unit_code, country_name, sector, tier, owner_name, source, id) OVERRIDING SYSTEM VALUE VALUES
	('Albion Foods', 'UK', NULL, 'CPG', 1, 'R. Patel', 'Salesforce', 1),
	('Thames Utilities', 'UK', NULL, 'E&U', 1, 'R. Patel', 'Salesforce', 2),
	('Pennine Manufacturing', 'UK', NULL, 'Manufacturing', 2, 'L. Murray', 'Portal upload', 3),
	('Mersey Care Group', 'UK', NULL, 'Life Sciences', 2, 'L. Murray', 'Portal upload', 4),
	('Rheinwerk AG', 'DE', NULL, 'Manufacturing', 1, 'K. Weber', 'Salesforce', 5),
	('BavariaTech GmbH', 'DE', NULL, 'TMT', 2, 'K. Weber', 'Salesforce', 6),
	('NordChem', 'DE', NULL, 'E&U', 1, 'T. Schmidt', 'Salesforce', 7),
	('Munich Retail Group', 'DE', NULL, 'Retail', 2, 'T. Schmidt', 'Portal upload', 8),
	('Sachsen Logistik', 'DE', NULL, 'Transport', 2, 'T. Schmidt', 'Portal upload', 9),
	('Delft Mobility', 'NL', NULL, 'Automotive', 2, 'M. Jansen', 'Salesforce', 10),
	('Rotterdam FoodCo', 'NL', NULL, 'CPG', 1, 'S. de Vries', 'Salesforce', 11),
	('Amstel Retail Group', 'NL', NULL, 'Retail', 2, 'J. Bakker', 'Portal upload', 12),
	('Van Oord Logistics', 'NL', NULL, 'Transport', 1, 'J. Bakker', 'Portal upload', 13),
	('Haarlem Insurance', 'NL', NULL, 'Financial Services', 2, 'J. Bakker', 'Derived from prospect mock data', 14),
	('Eindhoven Devices BV', 'NL', NULL, 'Manufacturing', 2, 'M. Jansen', 'Derived from prospect mock data', 15),
	('Nordic Steel AB', 'NO', 'Sweden', 'Manufacturing', 1, 'A. Lindqvist', 'Salesforce', 16),
	('Vasa Retail AB', 'NO', 'Sweden', 'Retail', 2, 'A. Lindqvist', 'Portal upload', 17),
	('Suomi Paper Oyj', 'NO', 'Finland', 'Manufacturing', 1, 'M. Virtanen', 'Salesforce', 18),
	('Fjord Energy ASA', 'NO', 'Norway', 'E&U', 1, 'E. Hansen', 'Portal upload', 19),
	('Copenhagen Logistics', 'NO', 'Denmark', 'Transport', 2, 'N. SÃ¸rensen', 'Portal upload', 20);

INSERT INTO mmf_portal.radar_engines (name, business_unit_code, client_count, rule_count, schedule, signal_count, prospect_set, source_keys, frequency, run_at, lookback_days, minimum_score, auto_link_campaigns, id) OVERRIDING SYSTEM VALUE VALUES
	('UK Â· Manufacturing & CPG', 'UK', 24, 5, 'Daily', 13, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 1),
	('UK Â· Energy & Utilities', 'UK', 14, 4, 'Daily', 7, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 2),
	('Germany Â· Industrial', 'DE', 28, 7, 'Daily', 18, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 3),
	('Germany Â· TMT & E&U', 'DE', 19, 5, 'Daily', 11, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 4),
	('Netherlands Â· Industrial', 'NL', 22, 6, 'Daily', 14, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 5),
	('Netherlands Â· Retail & CPG', 'NL', 16, 4, 'Daily', 9, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 6),
	('Nordics Â· Industrial', 'NO', 18, 4, 'Daily', 8, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 7),
	('Nordics Â· Energy', 'NO', 12, 3, 'Daily', 5, 'Target prospects', '{}', 'Daily', '05:00 CET', 14, 70, true, 8);

INSERT INTO mmf_portal.solutions (name, solution_class, tags, maturity, certification_status, reuse_count, id) OVERRIDING SYSTEM VALUE VALUES
	('IT Cost Takeout', 'Cross-Business Line', '{ADM,CIS}', 'Industrialized', 'Certified & Published', 34, 1),
	('SAP S/4 Rapid Migration', 'Business Line', '{ADM}', 'Industrialized', 'Certified & Published', 41, 2),
	('Hyperscaler Landing Zone', 'Cross-Business Line', '{CIS,I&D}', 'Industrialized', 'Certified & Published', 28, 3),
	('Manufacturing Smart Factory', 'Industry', '{Manufacturing}', 'Industrialized', 'Certified & Published', 22, 4),
	('E&U Grid Data Platform', 'Industry', '{E&U}', 'Industrialized', 'Certified & Published', 15, 5),
	('Retail Commerce Accelerator', 'Industry', '{Retail}', 'In-Development', 'Submitted', 9, 6),
	('Vendor Consolidation Play', 'Cross-Business Line', '{ADM,CIS}', 'In-Development', 'Submitted', 12, 7),
	('Cyber Baseline for Mid-Market', 'Cross-Business Line', '{CIS}', 'Draft', 'Draft', 3, 8);

INSERT INTO mmf_portal.campaigns (name, business_unit_code, country_name, status, owner_name, approver_name, start_date, end_date, target_account_count, accounts_reached, outreach_count, meeting_count, pipeline_millions, opportunities_generated, wins_millions, signal_driven, business_line, theme, partner_name, campaign_description, meetings_booked, qualified_leads, cxo_reach, inbound_count, audience_reach, bookings_millions, revenue_won_millions, id, solution_id, radar_engine_id) OVERRIDING SYSTEM VALUE VALUES
	('UK CPG â€” SAP S/4 Wave 1', 'UK', NULL, 'Approved', 'R. Patel', 'UK MM Leader', '2026-09-01', '2026-12-10', 9, 0, 0, 0, 0.00, 0, 0.00, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.00, 0.00, 3, 2, NULL),
	('UK Cross-sector â€” Cyber Baseline', 'UK', NULL, 'Draft', 'L. Murray', 'TBC', '2026-10-15', '2026-12-12', 5, 0, 0, 0, 0.00, 0, 0.00, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.00, 0.00, 4, 8, NULL),
	('DE Retail â€” Commerce Push', 'DE', NULL, 'Review', 'T. Schmidt', 'DE MM Leader', '2026-04-01', '2026-06-26', 7, 6, 44, 8, 4.10, 2, 0.00, false, NULL, NULL, NULL, NULL, 0, 2, 0, 0, 0, 2.30, 1.00, 8, 6, NULL),
	('NL Cross-sector â€” Vendor Consolidation', 'NL', NULL, 'Planned', 'M. Jansen', 'NL MM Leader', '2026-09-01', '2026-10-30', 10, 0, 0, 0, 0.00, 0, 0.00, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.00, 0.00, 12, 7, NULL),
	('NL SAP â€” S/4 Readiness', 'NL', NULL, 'Closed', 'S. de Vries', 'NL MM Leader', '2026-01-05', '2026-04-30', 6, 6, 35, 7, 3.20, 2, 1.80, false, NULL, NULL, NULL, NULL, 0, 2, 0, 0, 0, 1.80, 0.80, 13, 2, NULL),
	('DK Transport â€” Modernization', 'NO', 'Denmark', 'Planned', 'N. SÃ¸rensen', 'Nordics MM Leader', '2026-09-10', '2026-12-05', 6, 0, 0, 0, 0.00, 0, 0.00, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.00, 0.00, 17, 1, NULL),
	('UK Manufacturing â€” ADM Reboot', 'UK', NULL, 'Active', 'R. Patel', 'UK MM Leader', '2026-06-20', '2026-09-12', 13, 7, 64, 9, 5.50, 2, 0.00, true, 'ADM', NULL, NULL, NULL, 9, 2, 0, 0, 0, 3.00, 1.30, 1, 1, 1),
	('UK E&U â€” Grid Analytics', 'UK', NULL, 'Active', 'L. Murray', 'UK MM Leader', '2026-07-01', '2026-09-10', 7, 4, 38, 5, 3.80, 1, 0.00, true, 'I&D', NULL, NULL, NULL, 5, 1, 0, 0, 0, 2.10, 0.90, 2, 5, 2),
	('DE Industrial â€” Cost Takeout Q3', 'DE', NULL, 'Active', 'T. Schmidt', 'DE MM Leader', '2026-07-01', '2026-09-26', 16, 11, 92, 14, 9.60, 3, 5.20, true, 'ADM', NULL, NULL, NULL, 14, 3, 0, 0, 0, 5.30, 2.30, 5, 1, 3),
	('DE Manufacturing â€” Smart Factory', 'DE', NULL, 'Active', 'K. Weber', 'DE MM Leader', '2026-06-10', '2026-09-18', 12, 8, 71, 9, 8.20, 2, 0.00, true, 'CIS', NULL, NULL, NULL, 9, 2, 0, 0, 0, 4.50, 2.00, 6, 4, 3),
	('DE TMT â€” Cloud Migration', 'DE', NULL, 'Planned', 'K. Weber', 'DE MM Leader', '2026-09-01', '2026-11-12', 9, 0, 0, 0, 0.00, 0, 0.00, false, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.00, 0.00, 7, 3, 4),
	('DE E&U â€” Grid Data Platform', 'DE', NULL, 'Paused', 'K. Weber', 'DE MM Leader', '2026-05-15', '2026-09-30', 8, 3, 21, 2, 1.40, 0, 0.00, true, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0, 0.80, 0.30, 9, 5, 4),
	('NL Industrial â€” IT Cost Takeout', 'NL', NULL, 'Active', 'S. de Vries', 'NL MM Leader', '2026-07-01', '2026-09-26', 14, 9, 78, 11, 6.40, 2, 0.00, true, 'ADM', NULL, NULL, NULL, 11, 2, 0, 0, 0, 3.50, 1.50, 10, 1, 5),
	('NL Retail â€” Commerce Acceleration', 'NL', NULL, 'Active', 'J. Bakker', 'NL MM Leader', '2026-07-15', '2026-09-25', 8, 5, 41, 6, 2.90, 1, 0.00, true, 'DCX', NULL, NULL, NULL, 6, 1, 0, 0, 0, 1.60, 0.70, 11, 6, 6),
	('SE Industrial â€” Smart Factory', 'NO', 'Sweden', 'Active', 'A. Lindqvist', 'Nordics MM Leader', '2026-07-01', '2026-09-26', 9, 6, 44, 7, 4.40, 1, 0.00, true, 'CIS', NULL, NULL, NULL, 7, 1, 0, 0, 0, 2.40, 1.10, 14, 4, 7),
	('FI Manufacturing â€” ADM Consolidation', 'NO', 'Finland', 'Active', 'M. Virtanen', 'Nordics MM Leader', '2026-06-15', '2026-09-10', 8, 5, 36, 6, 3.00, 1, 0.00, true, 'ADM', NULL, NULL, NULL, 6, 1, 0, 0, 0, 1.70, 0.70, 15, 1, 7),
	('NO Energy â€” Cloud Foundation', 'NO', 'Norway', 'Active', 'E. Hansen', 'Nordics MM Leader', '2026-07-01', '2026-09-10', 7, 4, 29, 4, 2.60, 1, 0.00, true, 'CIS', NULL, NULL, NULL, 4, 1, 0, 0, 0, 1.40, 0.60, 16, 3, 8);

INSERT INTO mmf_portal.prospect_upload_batches (id, file_name, business_unit_code, uploaded_by, uploaded_at, row_count, accepted_count, rejected_count, status) VALUES
	('BATCH-0007', 'UK_manufacturing_wave2.xlsx', 'UK', 'R. Patel', '2026-09-01 12:30:00+05:30', 44, 38, 6, 'Validated - awaiting commit'),
	('BATCH-0006', 'NORDICS_wave1.xlsx', 'NO', 'A. Lindqvist', '2026-08-27 12:30:00+05:30', 36, 33, 3, 'Committed'),
	('BATCH-0005', 'NL_target_list_H2.xlsx', 'NL', 'S. de Vries', '2026-08-25 12:30:00+05:30', 62, 58, 4, 'Committed'),
	('BATCH-0004', 'DE_industrial_targets.xlsx', 'DE', 'K. Weber', '2026-08-18 12:30:00+05:30', 81, 74, 7, 'Committed');

INSERT INTO mmf_portal.prospects (id, business_unit_code, country_name, industry, estimated_tcv_millions, lifecycle_stage, owner_name, expected_signing_quarter, source, upload_batch_id, qualification_status, account_id) VALUES
	('PRS-UK-00013', 'UK', NULL, 'Manufacturing', 2.20, 'Research', 'L. Murray', 'Q1-2027', 'Excel upload', 'BATCH-0007', 'In research', 3),
	('PRS-UK-00016', 'UK', NULL, 'E&U', 4.80, 'Qualified Lead', 'R. Patel', 'Q4-2026', 'Radar signal', NULL, 'Qualified', 2),
	('PRS-UK-00019', 'UK', NULL, 'Life Sciences', 1.40, 'Meetings Scheduled / Delivered', 'L. Murray', 'Q2-2027', 'Single form', NULL, 'Engaged', 4),
	('PRS-UK-00021', 'UK', NULL, 'CPG', 5.50, 'Converted to Opportunity', 'R. Patel', 'Q1-2027', 'Campaign', NULL, 'Converted', 1),
	('PRS-DE-00042', 'DE', NULL, 'Manufacturing', 5.60, 'Converted to Opportunity', 'K. Weber', 'Q4-2026', 'Radar signal', NULL, 'Converted', 5),
	('PRS-DE-00045', 'DE', NULL, 'TMT', 2.10, 'Outreach', 'K. Weber', 'Q1-2027', 'Excel upload', 'BATCH-0004', 'Contacted', 6),
	('PRS-DE-00048', 'DE', NULL, 'Transport', 1.70, 'Target Identified', 'T. Schmidt', 'Q2-2027', 'Excel upload', 'BATCH-0004', 'Identified', 9),
	('PRS-DE-00051', 'DE', NULL, 'Retail', 3.40, 'Meetings Scheduled / Delivered', 'T. Schmidt', 'Q4-2026', 'Campaign', NULL, 'Engaged', 8),
	('PRS-NL-00021', 'NL', NULL, 'Transport', 2.40, 'Target Identified', 'J. Bakker', 'Q1-2027', 'Excel upload', 'BATCH-0005', 'Identified', 13),
	('PRS-NL-00024', 'NL', NULL, 'CPG', 3.10, 'Meetings Scheduled / Delivered', 'S. de Vries', 'Q4-2026', 'Radar signal', NULL, 'Engaged', 11),
	('PRS-NL-00029', 'NL', NULL, 'Financial Services', 2.90, 'Qualified Lead', 'J. Bakker', 'Q4-2026', 'Single form', NULL, 'Qualified', 14),
	('PRS-NL-00030', 'NL', NULL, 'Manufacturing', 4.20, 'Meetings Scheduled / Delivered', 'M. Jansen', 'Q1-2027', 'Campaign', NULL, 'Engaged', 15),
	('PRS-NO-00007', 'NO', 'Sweden', 'Retail', 2.00, 'Outreach', 'A. Lindqvist', 'Q1-2027', 'Excel upload', 'BATCH-0006', 'Contacted', 17),
	('PRS-NO-00009', 'NO', 'Sweden', 'Manufacturing', 3.60, 'Meetings Scheduled / Delivered', 'A. Lindqvist', 'Q4-2026', 'Campaign', NULL, 'Engaged', 16),
	('PRS-NO-00004', 'NO', 'Finland', 'Manufacturing', 2.80, 'Qualified Lead', 'M. Virtanen', 'Q4-2026', 'Radar signal', NULL, 'Qualified', 18),
	('PRS-NO-00003', 'NO', 'Norway', 'E&U', 3.90, 'Meetings Scheduled / Delivered', 'E. Hansen', 'Q1-2027', 'Single form', NULL, 'Engaged', 19),
	('PRS-NO-00002', 'NO', 'Denmark', 'Transport', 1.60, 'Outreach', 'N. SÃ¸rensen', 'Q1-2027', 'Excel upload', 'BATCH-0006', 'Contacted', 20);

INSERT INTO mmf_portal.opportunities (id, name, business_unit_code, country_name, industry, value_millions, stage, owner_name, close_date, status, is_mm_factory, probability_percent, competitor, prospect_id, account_id, solution_id) VALUES
	('0061t00000AbcU1', 'Albion â€” SAP S/4', 'UK', NULL, 'CPG', 5.50, 'Proposal', 'R. Patel', '2027-02-10', 'Open', true, 45, 'IBM', 'PRS-UK-00021', 1, 2),
	('0061t00000AbcU4', 'Thames â€” Grid analytics', 'UK', NULL, 'E&U', 3.80, 'Discovery', 'R. Patel', '2027-05-28', 'Open', true, 20, NULL, NULL, 2, 5),
	('0061t00000AbcU7', 'Pennine â€” Cost takeout', 'UK', NULL, 'Manufacturing', 2.40, 'Qualify', 'L. Murray', '2027-04-18', 'Open', false, 30, 'Atos', NULL, 3, 1),
	('0061t00000AbdK2', 'Rheinwerk â€” SAP S/4 migration', 'DE', NULL, 'Manufacturing', 8.20, 'Negotiation', 'K. Weber', '2026-12-12', 'Open', true, 60, 'Accenture', 'PRS-DE-00042', 5, 2),
	('0061t00000AbdK5', 'Rheinwerk â€” IT cost takeout', 'DE', NULL, 'Manufacturing', 3.40, 'Qualify', 'K. Weber', '2027-02-28', 'Open', true, 35, NULL, NULL, 5, 1),
	('0061t00000AbdK9', 'BavariaTech â€” Cloud migration', 'DE', NULL, 'TMT', 4.10, 'Discovery', 'K. Weber', '2027-04-30', 'Open', false, 20, 'Capita', NULL, 6, 3),
	('0061t00000AbdL1', 'NordChem â€” Data platform', 'DE', NULL, 'E&U', 6.00, 'Negotiation', 'T. Schmidt', '2026-11-15', 'Open', true, 75, 'Atos', NULL, 7, 5),
	('0061t00000AbdL4', 'NordChem â€” Managed services', 'DE', NULL, 'E&U', 5.20, 'Closed Won', 'T. Schmidt', '2026-07-02', 'Won', true, 100, NULL, NULL, 7, 1),
	('0061t00000AbeM2', 'Delft Mobility â€” ADM consolidation', 'NL', NULL, 'Automotive', 4.70, 'Proposal', 'M. Jansen', '2027-01-20', 'Open', true, 45, 'Sopra Steria', NULL, 10, 1),
	('0061t00000AbeM6', 'Amstel Retail â€” Commerce revamp', 'NL', NULL, 'Retail', 2.90, 'Qualify', 'J. Bakker', '2027-03-15', 'Open', true, 30, 'Valtech', NULL, 12, 6),
	('0061t00000AbeM9', 'Rotterdam FoodCo â€” Vendor consolidation', 'NL', NULL, 'CPG', 3.30, 'Discovery', 'S. de Vries', '2027-04-30', 'Open', true, 20, NULL, NULL, 11, 1),
	('0061t00000AbfN3', 'Nordic Steel â€” Smart factory', 'NO', 'Sweden', 'Manufacturing', 4.40, 'Proposal', 'A. Lindqvist', '2026-12-18', 'Open', true, 60, 'Tietoevry', NULL, 16, 4),
	('0061t00000AbfN7', 'Suomi Paper â€” ADM consolidation', 'NO', 'Finland', 'Manufacturing', 3.00, 'Discovery', 'M. Virtanen', '2027-06-12', 'Open', true, 20, 'Tietoevry', NULL, 18, 1),
	('0061t00000AbfP1', 'Fjord Energy â€” Cloud foundation', 'NO', 'Norway', 'E&U', 2.60, 'Qualify', 'E. Hansen', '2027-03-22', 'Open', false, 35, 'Sopra Steria', NULL, 19, 3),
	('0061t00000AbfP5', 'Copenhagen Logistics â€” Modernization', 'NO', 'Denmark', 'Transport', 2.10, 'Proposal', 'N. SÃ¸rensen', '2027-02-05', 'Open', true, 45, NULL, NULL, 20, 1);

INSERT INTO mmf_portal.radar_signals (id, business_unit_code, country_name, title, source, score, severity, status, summary, signal_category, published_at, opportunity_hypothesis, recommended_agents, recommended_action, scoring_inputs, account_id, radar_engine_id) OVERRIDING SYSTEM VALUE VALUES
	(1, 'UK', NULL, 'Ofwat AMP8 investment plan approved', 'Regulator', 92, 'High', 'New', 'Approved capital plan releases multi-year technology spend. Grid analytics and asset data are named workstreams - direct fit for the E&U Grid Data Platform.', NULL, NULL, NULL, '{}', NULL, '{}', 2, 2),
	(2, 'UK', NULL, 'Private-equity acquisition completed', 'News', 85, 'High', 'New', 'A new PE owner typically drives a 100-day cost agenda. Classic entry point for IT Cost Takeout and vendor consolidation.', NULL, NULL, NULL, '{}', NULL, '{}', 3, 1),
	(3, 'UK', NULL, 'Named in SAP mid-market reference programme', 'Partner feed', 77, 'Medium', 'Reviewed', 'SAP is actively working the account - coordinate joint outreach around the S/4 Rapid Migration solution.', NULL, NULL, NULL, '{}', NULL, '{}', 1, 1),
	(4, 'DE', NULL, 'Announces â‚¬400M plant modernization programme', 'Press release', 96, 'High', 'New', 'Three plants over 24 months, with legacy ERP named as a constraint. Strong fit for SAP S/4 Rapid Migration plus IT Cost Takeout.', NULL, NULL, NULL, '{}', NULL, '{}', 5, 3),
	(5, 'DE', NULL, 'CFO signals cost-reduction drive in H2 earnings call', 'Earnings call', 88, 'High', 'New', 'Management committed to an 8% opex reduction with IT named as a lever. Direct trigger for IT Cost Takeout outreach.', NULL, NULL, NULL, '{}', NULL, '{}', 7, 3),
	(6, 'DE', NULL, 'Hiring 40+ cloud & data engineers', 'Job boards', 81, 'Medium', 'New', 'A large AWS and data-platform hiring spike suggests a migration already in motion - landing-zone and managed-service opportunity.', NULL, NULL, NULL, '{}', NULL, '{}', 6, 4),
	(7, 'DE', NULL, 'New digital commerce tender published', 'Tender database', 83, 'High', 'Reviewed', 'Public tender for commerce replatforming with a six-week deadline - the pre-tender positioning window is open now.', NULL, NULL, NULL, '{}', NULL, '{}', 8, 3),
	(8, 'NL', NULL, 'Publishes tender for application support consolidation', 'Tender database', 94, 'High', 'New', 'Open tender to consolidate five application support vendors into one, closing in five weeks. Direct match for the Vendor Consolidation Play.', NULL, NULL, NULL, '{}', NULL, '{}', 11, 5),
	(9, 'NL', NULL, 'CFO commits to 7% opex reduction in trading update', 'Earnings call', 88, 'High', 'New', 'Management named IT and logistics as the two levers. Strong opening for IT Cost Takeout ahead of the FY planning cycle.', NULL, NULL, NULL, '{}', NULL, '{}', 12, 6),
	(10, 'NL', NULL, 'Hiring 25+ SAP and integration engineers', 'Job boards', 79, 'Medium', 'New', 'Concentrated SAP hiring suggests an S/4 programme being staffed internally - a positioning window for a managed alternative.', NULL, NULL, NULL, '{}', NULL, '{}', 15, 5),
	(11, 'NL', NULL, 'New Chief Digital Officer appointed', 'Leadership changes', 70, 'Medium', 'New', 'Leadership change often precedes transformation spend. Warm-intro opportunity for the account team.', NULL, NULL, NULL, '{}', NULL, '{}', 13, 5),
	(12, 'NO', 'Sweden', 'RFI issued for OT/IT integration partner', 'Tender database', 89, 'High', 'New', 'The RFI closes in three weeks. Direct fit for the Manufacturing Smart Factory solution.', NULL, NULL, NULL, '{}', NULL, '{}', 16, 7),
	(13, 'NO', 'Finland', 'Announces group-wide efficiency programme', 'Press release', 90, 'High', 'New', 'A â‚¬60M efficiency target over two years with shared services in scope - aligns to the ADM consolidation campaign already running.', NULL, NULL, NULL, '{}', NULL, '{}', 18, 7),
	(14, 'NO', 'Norway', 'Signs strategic cloud agreement with AWS', 'Partner feed', 86, 'High', 'New', 'Commitment made, capability not yet built. A strong opening for the Hyperscaler Landing Zone solution.', NULL, NULL, NULL, '{}', NULL, '{}', 19, 8),
	(15, 'NO', 'Denmark', 'Recruiting Head of Enterprise Architecture', 'Job boards', 72, 'Medium', 'New', 'A senior EA hire usually precedes a modernization mandate. Time outreach for 60-90 days after the appointment.', NULL, NULL, NULL, '{}', NULL, '{}', 20, 7);

INSERT INTO mmf_portal.smart_agents (name, lifecycle_stage, agent_type, status, version, description, grounding_sources, owner_team, best_used_for, launches_this_quarter, platform, launch_url, visibility_scopes, recommended_trigger_categories, id) OVERRIDING SYSTEM VALUE VALUES
	('Intelio', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Creates a 360-degree client intelligence view including business context, sector trends, financials, technology priorities and opportunity hypotheses.', '{"Radar signals","Public web"}', 'Clients & Innovation', 'Account planning, first outreach, meeting preparation and opportunity shaping.', 64, NULL, NULL, '{}', '{}', 1),
	('BritMap', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Builds UK-focused BuyerMaps, decision-maker context and likely opportunity areas.', '{"Radar signals","Public web"}', 'Clients & Innovation', 'UK mid-market account intelligence and targeted sales engagement.', 22, NULL, NULL, '{}', '{}', 2),
	('Helder', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Creates concise BuyerMaps for Netherlands mid-market clients.', '{"Radar signals","Public web"}', 'Clients & Innovation', 'Netherlands teams preparing account meetings.', 18, NULL, NULL, '{}', '{}', 3),
	('Rapport', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Builds stakeholder intelligence profiles and engagement approaches.', '{"Radar signals","Public web"}', 'Clients & Innovation', 'Preparing for senior stakeholder conversations.', 37, NULL, NULL, '{}', '{}', 4),
	('Stakeholder Profile', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Structures stakeholder profiles from public and contextual inputs.', '{"Public web"}', 'Clients & Innovation', 'Account or bid stakeholder mapping.', 15, NULL, NULL, '{}', '{}', 5),
	('LinkedIn CXO Voice', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Decodes leadership activity and public CXO voice.', '{"Public web"}', 'Clients & Innovation', 'When leadership signals or executive changes are identified.', 26, NULL, NULL, '{}', '{}', 6),
	('Market Intel in a Box', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Generates executive-ready market intelligence and client briefings.', '{"Public web"}', 'Clients & Innovation', 'Leadership-ready account and market briefings.', 29, NULL, NULL, '{}', '{}', 7),
	('Knowledge SPOC', 'Meeting preparation', 'Internal', 'Published', 'v1.0', 'Finds relevant capability decks, case studies, sales kits and guidance.', '{"Solutions & Assets (RAG)"}', 'Knowledge Management', 'Preparing meeting materials or proof points.', 51, NULL, NULL, '{}', '{}', 8),
	('Beacon', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Identifies and scores buying signals using public data and a structured taxonomy.', '{"Radar signals"}', 'Clients & Innovation', 'Validating whether a trigger is commercially meaningful.', 33, NULL, NULL, '{}', '{}', 9),
	('Triggers Orchestrator', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Processes trigger lists and applies regional governance rules.', '{"Radar signals"}', 'Clients & Innovation', 'Standardising batches of trigger signals.', 12, NULL, NULL, '{}', '{}', 10),
	('Financial Analyst', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Analyses financial stress and maps it to IT services opportunities.', '{"Public web","Radar signals"}', 'Clients & Innovation', 'Financial updates, margin pressure or restructuring signals.', 44, NULL, NULL, '{}', '{}', 11),
	('Spend Scout', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Identifies likely investment areas from financials and company actions.', '{"Public web","Radar signals"}', 'Clients & Innovation', 'Separating commercial opportunity from market noise.', 20, NULL, NULL, '{}', '{}', 12),
	('Sales TransFORM', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Explains sales pipeline, bookings, forecasting and governance rules.', '{Salesforce}', 'Sales Analytics Centre', 'Qualifying or progressing pipeline stages.', 17, NULL, NULL, '{}', '{}', 13),
	('Deal Risk Sentinel', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Surfaces commercial, delivery, compliance and governance risks across deals.', '{Salesforce}', 'Wincentre', 'Qualification, go/no-go and deal review.', 25, NULL, NULL, '{}', '{}', 14),
	('Nexus', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Turns relevant innovation into client-ready value stories.', '{"Solutions & Assets (RAG)","Radar signals"}', 'Clients & Innovation', 'Shaping innovation-led proposals and solution angles.', 39, NULL, NULL, '{}', '{}', 15),
	('Researcher', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Conducts deep research on competitors, markets, clients and partnerships.', '{"Public web","Radar signals"}', 'Clients & Innovation', 'Market and competitor research during shaping.', 47, NULL, NULL, '{}', '{}', 16),
	('Horizon', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Anticipates public-sector tender opportunities before formal publication.', '{"Public web"}', 'Clients & Innovation', 'Pre-tender positioning.', 14, NULL, NULL, '{}', '{}', 17),
	('CompeteIQ', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Builds competitor overviews and compete strategy.', '{"Public web"}', 'Clients & Innovation', 'Strengthening differentiation and win themes.', 21, NULL, NULL, '{}', '{}', 18),
	('GCC Advisor', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Provides GCC market intelligence, talent and operating model insights.', '{"Public web"}', 'Clients & Innovation', 'GCC-related advisory opportunities.', 8, NULL, NULL, '{}', '{}', 19),
	('Beat The Competition', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Creates competitive intelligence newsletters and market briefs.', '{"Public web"}', 'Clients & Innovation', 'Competitive monitoring and strategy.', 16, NULL, NULL, '{}', '{}', 20),
	('RFx Shredder', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Extracts RFP and RFI requirements, risks, gaps and evaluation criteria.', '{"Uploaded RFP"}', 'Wincentre', 'Day one of a bid or tender review.', 46, NULL, NULL, '{}', '{}', 21),
	('Bid Support Copilot', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Guides bid lifecycle activities, checklists, prompts and compliance.', '{"Uploaded RFP"}', 'Wincentre', 'Bid and presales teams during an RFx response.', 34, NULL, NULL, '{}', '{}', 22),
	('Winplan Navigator', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Builds win strategy, value proposition and competitive positioning.', '{Salesforce}', 'Wincentre', 'Pursuit strategy and win planning.', 28, NULL, NULL, '{}', '{}', 23),
	('RedTeam Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Critically reviews tender and bid content.', '{"Uploaded RFP"}', 'Wincentre', 'Before formal proposal review.', 19, NULL, NULL, '{}', '{}', 24),
	('Cognitive Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Reviews proposals for clarity, logic, trust and decision effectiveness.', '{"Uploaded RFP"}', 'Wincentre', 'Sharpening executive-ready proposal content.', 13, NULL, NULL, '{}', '{}', 25),
	('Proposal Matcher', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Compares RFx requirements with proposal content.', '{"Uploaded RFP"}', 'Proposal Centre', 'Validating proposal fit against customer requirements.', 23, NULL, NULL, '{}', '{}', 26),
	('Final Checker', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Checks RFP responses for consistency, grammar, formatting and compliance.', '{"Uploaded RFP"}', 'Proposal Centre', 'Before submission.', 30, NULL, NULL, '{}', '{}', 27),
	('Proposal Development', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Creates structured proposal documents from RFP content.', '{"Uploaded RFP"}', 'Proposal Centre', 'Accelerating drafting.', 26, NULL, NULL, '{}', '{}', 28),
	('FAQ / Response Draft - UK', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Finds standard responses and bid essentials from UK knowledge sources.', '{"Solutions & Assets (RAG)"}', 'Wincentre', 'Questionnaires, FAQs and standard response drafting.', 11, NULL, NULL, '{}', '{}', 29);

INSERT INTO mmf_portal.assets (id, name, asset_type, version, certification_status, carve_out_ready, source_type, repository_name, source_url, owner_name, refresh_cycle_months, last_reviewed_at, next_review_at, lifecycle_state, visibility_scopes, solution_id) OVERRIDING SYSTEM VALUE VALUES
	(1, 'Cost takeout â€” solution blueprint', 'Blueprint', 'v3', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 1),
	(2, 'Cost takeout â€” value case model', 'Reusable template', 'v2', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 1),
	(3, 'Reference win â€” NordChem', 'Case study', 'v1', 'Certified & Published', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 1),
	(4, 'Cost takeout â€” client pitch deck', 'Deck', 'v4', 'Certified & Published', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 1),
	(5, 'S/4 readiness assessment', 'Reusable template', 'v2', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 2),
	(6, 'S/4 migration blueprint', 'Blueprint', 'v5', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 2),
	(7, 'S/4 RFP response library', 'RFP response', 'v3', 'Certified & Published', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 2),
	(8, 'Landing zone reference architecture', 'Blueprint', 'v3', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 3),
	(9, 'Landing zone proof-of-value pack', 'Reusable template', 'v1', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 3),
	(10, 'Smart factory reference architecture', 'Blueprint', 'v2', 'Certified & Published', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 4),
	(11, 'Grid data platform â€” case study', 'Case study', 'v1', 'Certified & Published', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Certified', '{}', 5),
	(12, 'Commerce accelerator demo pack', 'Deck', 'v2', 'Submitted', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Submitted', '{}', 6),
	(13, 'Vendor consolidation battle card', 'Reusable template', 'v1', 'Submitted', true, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Submitted', '{}', 7),
	(14, 'Cyber baseline offer 1-pager', 'Deck', 'v1', 'Draft', false, 'Repository link', NULL, NULL, 'Unassigned', 12, NULL, NULL, 'Draft', '{}', 8);

INSERT INTO mmf_portal.audit_events (id, occurred_at, actor_name, action, event_details) OVERRIDING SYSTEM VALUE VALUES
	(1, '2026-09-02 12:44:00+05:30', 'R. Patel', 'Upload validated', 'BATCH-0007 Â· 38 accepted, 6 rejected'),
	(2, '2026-09-01 20:12:00+05:30', 'K. Weber', 'Prospect converted', 'PRS-DE-00042 â†’ 0061t00000AbdK2'),
	(3, '2026-09-01 14:37:00+05:30', 'System', 'Salesforce sync', 'Accounts 412 upserted Â· Opportunities 268 upserted'),
	(4, '2026-08-31 21:25:00+05:30', 'T. Schmidt', 'Campaign edited', 'DE Industrial â€” Cost Takeout Q3 Â· 4 accounts added'),
	(5, '2026-08-29 17:50:00+05:30', 'Factory S&A Lead', 'Asset published', 'S/4 migration blueprint v5'),
	(6, '2026-08-28 12:01:00+05:30', 'Admin', 'Connector deactivated', 'Job boards / hiring feed - pending procurement review');

INSERT INTO mmf_portal.campaign_history (id, changed_at, changed_by, change_description, campaign_id) OVERRIDING SYSTEM VALUE VALUES
	(1, '2026-08-28 12:30:00+05:30', 'T. Schmidt', 'Added 4 accounts from BATCH-0004 upload', 5),
	(2, '2026-08-14 12:30:00+05:30', 'DE MM Leader', 'Status Planned â†’ Approved â†’ Active', 5),
	(3, '2026-08-26 12:30:00+05:30', 'R. Patel', 'End date extended to 12 Sep 2026', 1),
	(4, '2026-08-12 12:30:00+05:30', 'R. Patel', 'Objective updated after the joint plan review', 1),
	(5, '2026-08-22 12:30:00+05:30', 'J. Bakker', 'Linked Radar engine Netherlands Â· Retail & CPG', 11);

INSERT INTO mmf_portal.partner_plays (name, partner_name, partner_tier, business_line, theme, eligible_country_codes, status, value_proposition, influenced_pipeline_millions, linked_campaign_count, owner_name, id) OVERRIDING SYSTEM VALUE VALUES
	('SAP RISE for Mid-Market', 'SAP', 'Platinum', 'ADM', 'SAP / Cloud', '{NL,DE,UK,SE,FI}', 'Active', 'Fixed-scope RISE migration with Capgemini mid-market accelerators and SAP funding support.', 9.40, 3, 'S. de Vries', 1),
	('AWS Landing Zone Fast Start', 'AWS', 'Premier', 'CIS', 'SAP / Cloud', '{DE,UK,NO,DK}', 'Active', 'Six-week landing zone with AWS MAP funding; ideal entry play for new logos.', 6.70, 3, 'K. Weber', 2),
	('Microsoft Data & AI Jumpstart', 'Microsoft', 'Premier', 'I&D', 'Data & AI', '{NL,DE,UK,SE,FI,NO,DK}', 'Active', 'Fabric-based data platform starter with joint Microsoft investment and a four-week proof of value.', 8.10, 4, 'L. Murray', 3),
	('Adobe Commerce for Mid-Market Retail', 'Adobe', 'Gold', 'DCX', 'Sector play', '{NL,DE,SE}', 'Active', 'Pre-configured commerce stack for retailers under EUR 3B revenue, with Adobe co-marketing.', 4.20, 3, 'J. Bakker', 4),
	('Siemens Smart Factory Accelerator', 'Siemens', 'Gold', 'CIS', 'Sector play', '{DE,SE}', 'Active', 'OT/IT convergence play for discrete manufacturers, co-delivered with Siemens.', 5.30, 2, 'A. Lindqvist', 5),
	('ServiceNow ITSM Consolidation', 'ServiceNow', 'Gold', 'ADM', 'Vendor Consolidation', '{NL,UK}', 'Active', 'Consolidate fragmented tooling onto a single ITSM platform with a strong cost-takeout narrative.', 3.10, 2, 'M. Jansen', 6),
	('Google Cloud Modernization Sprint', 'Google Cloud', 'Silver', 'CIS', 'Enterprise Technology Modernization', '{UK,DK}', 'Draft', 'Application modernization sprint with Google funding, pending the mid-market pricing model.', 0.00, 0, 'R. Patel', 7);

INSERT INTO mmf_portal.campaign_playbook_parts (name, description, display_order) VALUES
	('Campaign Brief', 'Why now, the market context, the objective and the target segment', 1),
	('Messaging & Narrative', 'The story arc, proof points and the three things a seller must land', 2),
	('Buyer Personas', 'Who buys, who blocks, what each cares about and how they are measured', 3),
	('Value Proposition', 'The quantified outcome, the value case model and the reference wins', 4),
	('Objection Handling', 'The eight objections that recur, and the answer to each', 5);

INSERT INTO mmf_portal.data_source_connectors (name, connector_type, credential_reference, license_terms, is_active, used_by, id) OVERRIDING SYSTEM VALUE VALUES
	('Open web search', 'public_web', NULL, 'Public sources', true, '{Radar,Agents}', 1),
	('Company news & press releases', 'public_web', NULL, 'Public sources', true, '{Radar}', 2),
	('Regulatory filings', 'public_web', NULL, 'Public sources', true, '{Radar}', 3),
	('Tender database (EU/TED)', 'subscription', 'kv://mmf/ted-api-key', 'Seat-limited; no redistribution', true, '{Radar}', 4),
	('Job boards / hiring feed', 'subscription', 'kv://mmf/hiring-feed', 'Pending procurement review', false, '{Radar}', 5),
	('Leadership change monitor', 'public_web', NULL, 'Public sources', true, '{Radar}', 6),
	('Salesforce (CRM)', 'crm', 'kv://mmf/sfdc-jwt', 'Internal', true, '{"Data model",Agents}', 7),
	('Solutions & Assets index', 'in_house', 'kv://mmf/sharepoint-app', 'Internal', true, '{"Agents (RAG)"}', 8);

INSERT INTO mmf_portal.governance_actions (id, action, owner_name, due_date, status) OVERRIDING SYSTEM VALUE VALUES
	(1, 'Finalize Q4 target accounts for the Industrial engine', 'BU MM Leader', '2026-09-12', 'Open'),
	(2, 'Certify Retail Commerce Accelerator assets', 'Factory S&A Lead', '2026-09-19', 'Open'),
	(3, 'Register the tender-database subscription source', 'Factory Agentic Lead', '2026-09-26', 'Open'),
	(4, 'Confirm sector/segment taxonomy as reference data', 'Admin', '2026-09-30', 'Open'),
	(5, 'Assemble the Rotterdam tender bid team', 'BU Factory Leader', '2026-09-04', 'Open'),
	(6, 'Configure E&U engine subscription source', 'Factory Agentic Lead', '2026-08-22', 'Closed');

INSERT INTO mmf_portal.governance_councils (name, cadence, scope, next_meeting_date, chair_role, decision_count, action_count, id) OVERRIDING SYSTEM VALUE VALUES
	('Quarterly SBU Steering', 'Quarterly', 'SBU', '2026-10-02', 'SBU Factory Leader', 4, 6, 1),
	('Monthly BU GTM Squad', 'Monthly', 'BU', '2026-09-05', 'BU MM Leader', 3, 8, 2),
	('Weekly Deal & Solutions Review', 'Weekly', 'BU', '2026-09-05', 'BU Factory Leader', 2, 5, 3);

INSERT INTO mmf_portal.governance_decisions (id, decision, owner_name, decision_date, status, reference_type) OVERRIDING SYSTEM VALUE VALUES
	(1, 'Approve SAP S/4 Wave 1 campaign for UK CPG', 'UK MM Leader', '2026-08-28', 'Ratified', 'Campaign'),
	(2, 'Certify Retail Commerce Accelerator at In-Development', 'Factory S&A Lead', '2026-08-21', 'Ratified', 'Solution'),
	(3, 'Bid on the Rotterdam FoodCo consolidation tender', 'BU Factory Leader', '2026-08-29', 'Ratified', 'Prospect'),
	(4, 'Defer Cyber Baseline solution to Q4', 'SBU Factory Leader', '2026-07-03', 'Open', 'Solution'),
	(5, 'Adopt daily Salesforce sync cadence for MVP', 'SBU Factory Leader', '2026-07-03', 'Ratified', NULL);

INSERT INTO mmf_portal.governance_meetings (id, meeting_date, attendees, notes, decision_count, action_count, council_id) OVERRIDING SYSTEM VALUE VALUES
	(1, '2026-08-05', 'BU MM Leader, BU Factory Leader, Campaign Lead, 3 sellers', 'Reviewed Q3 campaign pipeline. Cost Takeout ahead of plan; Commerce Push behind on meetings. Agreed to move two sellers onto the tender response.', 2, 3, 2),
	(2, '2026-08-29', 'Solution Architect, 4 sellers, BU Factory Leader', 'Rheinwerk workshop pack reviewed and approved. Rotterdam tender: bid/no-bid taken as bid, subject to partner confirmation.', 1, 2, 3),
	(3, '2026-07-03', 'SBU Factory Leader, 4 BU MM Leaders', 'Q3 objectives set per BU. Agreed the daily Salesforce sync cadence for MVP and deferred the Cyber Baseline solution to Q4.', 3, 4, 1);

INSERT INTO mmf_portal.kpi_definitions (name, unit, definition, dimensions) VALUES
	('Qualified pipeline', 'â‚¬', 'Sum of open MM-Factory-classified opportunities in scope', '{BU,Country,Campaign}'),
	('Revenue booked', 'â‚¬', 'Sum of closed-won MM-Factory-classified opportunities in scope', '{BU,Country,Campaign}'),
	('Coverage', '%', 'Target accounts with an interaction or open opportunity divided by target accounts', '{BU,Country}'),
	('% Industrialized', '%', 'Reuse events on certified assets divided by total asset usage', '{BU,SBU}'),
	('Outreach activities completed', '#', 'ProspectInteraction records of type outreach or call in the period', '{BU,Country,Campaign,Seller}'),
	('Meetings secured', '#', 'ProspectInteraction records of type meeting scheduled or delivered', '{BU,Country,Campaign,Seller}'),
	('Opportunities created', '#', 'ProspectOpportunityLink records created in the period', '{BU,Country,Campaign}'),
	('Campaign stage conversion', '%', 'CampaignAccount progression between adjacent stages', '{Campaign}'),
	('Signal â†’ opportunity conversion', '%', 'Signals whose account opened an opportunity within the attribution window', '{BU,Engine}'),
	('Agent adoption', '#', 'Distinct users invoking an agent in the period', '{BU,Country,Agent}');

INSERT INTO mmf_portal.kpi_snapshots (id, as_of, business_unit_code, country_name, pipeline_millions, revenue_millions, coverage_percent, reuse_percent, signal_count, signal_conversion_percent, outreach_count, meeting_count, opportunities_created, stage_conversion_percent, pipeline_target_millions, revenue_target_millions, coverage_target_percent, client_count, target_account_count, active_account_count, active_campaign_count, active_partner_play_count, key_asset_count, smart_agent_count, qualified_lead_count, bookings_target_millions) OVERRIDING SYSTEM VALUE VALUES
	(9, '2026-08-11 05:30:00+05:30', 'NL', NULL, 38.40, 45.00, 62.00, 71.00, 92, 7.00, 31, 12, 12, 31.00, 50.00, 60.00, 70.00, 150, 50, 31, 4, 12, 55, 29, 7, 60.00),
	(10, '2026-08-11 05:30:00+05:30', 'DE', NULL, 47.10, 52.60, 64.00, 68.00, 118, 11.00, 41, 18, 18, 36.00, 60.00, 70.00, 70.00, 210, 64, 41, 5, 9, 62, 29, 11, 70.00),
	(11, '2026-08-11 05:30:00+05:30', 'UK', NULL, 33.70, 38.20, 53.00, 64.00, 87, 8.00, 29, 14, 14, 34.00, 45.00, 55.00, 65.00, 180, 55, 29, 4, 8, 48, 29, 8, 55.00),
	(12, '2026-08-11 05:30:00+05:30', 'NO', 'Sweden', 16.20, 19.40, 53.00, 60.00, 51, 5.00, 17, 8, 6, 31.00, 22.00, 26.00, 62.00, 95, 32, 17, 3, 6, 34, 29, 5, 26.00),
	(13, '2026-08-11 05:30:00+05:30', 'NO', 'Finland', 12.80, 14.10, 54.00, 58.00, 44, 4.00, 14, 7, 5, 29.00, 17.00, 18.00, 60.00, 70, 26, 14, 2, 5, 28, 29, 4, 18.00),
	(14, '2026-08-11 05:30:00+05:30', 'NO', 'Norway', 9.60, 11.30, 45.00, 55.00, 36, 3.00, 10, 5, 4, 28.00, 14.00, 15.00, 60.00, 62, 22, 10, 2, 4, 24, 29, 3, 15.00),
	(15, '2026-08-11 05:30:00+05:30', 'NO', 'Denmark', 8.40, 9.80, 45.00, 56.00, 31, 3.00, 9, 4, 3, 27.00, 12.00, 13.00, 60.00, 58, 20, 9, 2, 4, 22, 29, 3, 13.00);

INSERT INTO mmf_portal.modules (name) VALUES
	('Prospects'),
	('Campaigns'),
	('Solutions & Assets'),
	('Triggers Radar'),
	('Dashboard'),
	('Governance'),
	('Smart Agents'),
	('Admin');

INSERT INTO mmf_portal.mvp_outcomes (id, outcome, status) OVERRIDING SYSTEM VALUE VALUES
	(1, 'MVP clearly supports the overall mid-market growth objectives, and the MVP scope is signed off by leadership', 'Open'),
	(2, 'Data quality, compliance and launch readiness confirmed', 'Open'),
	(3, 'No critical issues or gaps at go-live', 'Open');

INSERT INTO mmf_portal.play_templates (name, channel, step_count, solution_id) VALUES
	('Cost Takeout outreach sequence', 'Email', 4, 1),
	('Value workshop play', 'Direct', 3, 1),
	('S/4 readiness assessment play', 'Direct', 3, 2),
	('Landing-zone proof of value', 'Webinar', 5, 3),
	('Smart factory discovery play', 'Direct', 4, 4);

INSERT INTO mmf_portal.portal_views (name, description, navigation) VALUES
	('Leadership', 'Executive performance, BU/SBU roll-ups, objectives, pipeline and campaign outcomes', '["dashboard", "prospects", "campaigns", "governance", "scope"]'),
	('Factory / Operations', 'Campaign, prospect, asset, trigger, agent and governance operations', '["dashboard", "prospects", "campaigns", "solutions", "radar", "agents", "governance", "admin", "scope"]'),
	('Seller', 'Assigned prospects and accounts, signals, interactions, campaigns, opportunities and Smart Agents', '["dashboard", "prospects", "campaigns", "solutions", "radar", "agents", "scope"]');

INSERT INTO mmf_portal.prospect_interactions (id, prospect_id, interaction_type, interaction_date, seller_name, notes, next_action, status, due_date) OVERRIDING SYSTEM VALUE VALUES
	(1, 'PRS-DE-00042', 'Meeting delivered', '2026-08-21', 'K. Weber', 'CIO confirmed the plant modernization programme; legacy ERP named as the blocker.', 'Send value case and book a workshop', 'Closed', '2026-08-28'),
	(2, 'PRS-DE-00042', 'Meeting scheduled', '2026-09-04', 'K. Weber', 'Value workshop with CIO and Head of Applications.', 'Prepare workshop pack', 'Open', '2026-09-03'),
	(3, 'PRS-UK-00016', 'Call', '2026-08-26', 'R. Patel', 'AMP8 plan approved; asset data is a named workstream.', 'Introduce grid analytics reference', 'Open', '2026-09-05'),
	(4, 'PRS-NL-00024', 'Meeting delivered', '2026-08-28', 'S. de Vries', 'Tender for application support consolidation confirmed, closing in five weeks.', 'Assemble bid team', 'Open', '2026-09-04'),
	(5, 'PRS-NO-00004', 'Outreach', '2026-08-19', 'M. Virtanen', 'Efficiency programme announced; shared services in scope.', 'Request discovery session', 'Open', '2026-09-08');

INSERT INTO mmf_portal.prospect_upload_records (batch_id, row_number, company_name, result, reason) VALUES
	('BATCH-0007', 3, 'Yorkshire Precision Ltd', 'Accepted', NULL),
	('BATCH-0007', 4, 'Tyne Components plc', 'Accepted', NULL),
	('BATCH-0007', 19, 'Midlands Tooling', 'Rejected', 'Sector code missing - must match the governed Industry list'),
	('BATCH-0007', 22, 'Pennine Manufacturing', 'Rejected', 'Duplicate - matches existing prospect PRS-UK-00013 (name + BU)'),
	('BATCH-0007', 27, 'Clyde Fabrication', 'Rejected', 'Owner not a provisioned user in this BU'),
	('BATCH-0007', 31, NULL, 'Rejected', 'Company name empty'),
	('BATCH-0007', 33, 'Solent Marine Ltd', 'Rejected', 'Estimated TCV is not numeric'),
	('BATCH-0007', 38, 'Anglia Foods Ltd', 'Rejected', 'Country supplied for a BU that is not split');

INSERT INTO mmf_portal.raci_assignments (activity, responsible, accountable, consulted, informed) VALUES
	('Set BU quarterly objectives & targets', 'BU MM Leader', 'SBU Factory Leader', 'BU Factory Leader', 'Sellers'),
	('Create & upload target prospects', 'Seller', 'BU MM Leader', 'Campaign Lead', 'BU Factory Leader'),
	('Qualify & convert a prospect', 'Seller', 'BU MM Leader', 'Solution Architect', 'Campaign Lead'),
	('Build & industrialize solutions/assets', 'Solution Architect', 'Factory S&A Lead', 'BU Factory Leader', 'BU MM Leader'),
	('Certify & publish solution/asset', 'Factory S&A Lead', 'Factory S&A Lead', 'Solution Architect', 'BUs'),
	('Configure radar engines & rules', 'Factory Agentic Lead', 'BU Factory Leader', 'Sellers', 'BU MM Leader'),
	('Plan & approve a campaign', 'Campaign Lead', 'BU MM Leader', 'Solution Architect', 'Sellers'),
	('Execute campaign / work accounts', 'Seller', 'Campaign Lead', 'Factory Agentic Lead', 'BU MM Leader'),
	('Author/register & govern agents', 'Factory Agentic Lead', 'Factory Agentic Lead', 'Admin', 'Sellers'),
	('Manage users, roles & connectors', 'Admin', 'Admin', 'â€”', 'All');

INSERT INTO mmf_portal.reference_data (category, values_text, governance_status) VALUES
	('Business Line', 'CCA Â· PBS Â· ADM Â· CIS Â· Invent Â· DCX Â· I&D Â· Sogeti', 'Locked'),
	('Industry / sector', 'Manufacturing Â· Retail Â· CPG Â· Automotive Â· TMT Â· E&U Â· Transport Â· Financial Services Â· Life Sciences', 'Open - action A4'),
	('Segment', 'Mid-market revenue bands within â‚¬500Mâ€“â‚¬3B', 'Open - action A4'),
	('Prospect lifecycle stage', 'Target Identified Â· Research Â· Outreach Â· Meetings Scheduled / Delivered Â· Qualified Lead Â· Converted to Opportunity', 'Locked'),
	('Prospect source', 'Single form Â· Excel upload Â· Radar signal Â· Campaign', 'Locked'),
	('Campaign status', 'Draft Â· Planned Â· Approved Â· Active Â· Paused Â· Closed Â· Review', 'Locked'),
	('Solution class', 'Industry Â· Business Line Â· Cross-Business Line', 'Locked'),
	('Certification status', 'Draft Â· Submitted Â· Certified & Published', 'Locked'),
	('Signal status', 'New Â· Reviewed Â· Dismissed', 'Locked');

INSERT INTO mmf_portal.roles (name, rights_description, portal_view_name) VALUES
	('SBU Factory Leader', 'Read-all roll-up across BUs; owns shared/SBU objectives and SBU governance', 'Leadership'),
	('BU Factory Leader', 'Owns Factory activation for their BU: solutions, campaigns, triggers and BU governance', 'Factory / Operations'),
	('BU MM (Business) Leader', 'Owns BU targets, accounts, target lists and team; chairs the BU joint plan', 'Leadership'),
	('Seller / Client Partner', 'Works accounts; consumes signals and assets; flags MM-Factory opportunities; runs agents and campaigns', 'Seller'),
	('Solution Architect / SME', 'Creates and maintains solutions and assets', 'Factory / Operations'),
	('Campaign Lead', 'Creates and manages campaigns and plays', 'Factory / Operations'),
	('Factory Agentic Lead', 'Configures radar engines, rules and sources; authors, registers and governs Smart Agents', 'Factory / Operations'),
	('Factory Solution & Assets Lead', 'Owns the Solutions & Assets library; certifies and publishes', 'Factory / Operations'),
	('Admin', 'Manages users, roles, permissions, reference data, connectors and integrations', 'Factory / Operations');

INSERT INTO mmf_portal.role_permissions (role_name, module_name, access_level) VALUES
	('SBU Factory Leader', 'Prospects', 'R'),
	('SBU Factory Leader', 'Campaigns', 'R'),
	('SBU Factory Leader', 'Solutions & Assets', 'R'),
	('SBU Factory Leader', 'Triggers Radar', 'R'),
	('SBU Factory Leader', 'Dashboard', 'RW'),
	('SBU Factory Leader', 'Governance', 'RW'),
	('SBU Factory Leader', 'Smart Agents', 'R'),
	('SBU Factory Leader', 'Admin', 'NONE'),
	('BU Factory Leader', 'Prospects', 'RW'),
	('BU Factory Leader', 'Campaigns', 'RW'),
	('BU Factory Leader', 'Solutions & Assets', 'R'),
	('BU Factory Leader', 'Triggers Radar', 'RW'),
	('BU Factory Leader', 'Dashboard', 'R'),
	('BU Factory Leader', 'Governance', 'RW'),
	('BU Factory Leader', 'Smart Agents', 'R'),
	('BU Factory Leader', 'Admin', 'NONE'),
	('BU MM (Business) Leader', 'Prospects', 'RW'),
	('BU MM (Business) Leader', 'Campaigns', 'RW'),
	('BU MM (Business) Leader', 'Solutions & Assets', 'R'),
	('BU MM (Business) Leader', 'Triggers Radar', 'R'),
	('BU MM (Business) Leader', 'Dashboard', 'R'),
	('BU MM (Business) Leader', 'Governance', 'RW'),
	('BU MM (Business) Leader', 'Smart Agents', 'R'),
	('BU MM (Business) Leader', 'Admin', 'NONE'),
	('Seller / Client Partner', 'Prospects', 'RW'),
	('Seller / Client Partner', 'Campaigns', 'R'),
	('Seller / Client Partner', 'Solutions & Assets', 'R'),
	('Seller / Client Partner', 'Triggers Radar', 'RW'),
	('Seller / Client Partner', 'Dashboard', 'R'),
	('Seller / Client Partner', 'Governance', 'NONE'),
	('Seller / Client Partner', 'Smart Agents', 'RW'),
	('Seller / Client Partner', 'Admin', 'NONE'),
	('Solution Architect / SME', 'Prospects', 'R'),
	('Solution Architect / SME', 'Campaigns', 'R'),
	('Solution Architect / SME', 'Solutions & Assets', 'RW'),
	('Solution Architect / SME', 'Triggers Radar', 'R'),
	('Solution Architect / SME', 'Dashboard', 'R'),
	('Solution Architect / SME', 'Governance', 'NONE'),
	('Solution Architect / SME', 'Smart Agents', 'RW'),
	('Solution Architect / SME', 'Admin', 'NONE'),
	('Campaign Lead', 'Prospects', 'RW'),
	('Campaign Lead', 'Campaigns', 'RW'),
	('Campaign Lead', 'Solutions & Assets', 'R'),
	('Campaign Lead', 'Triggers Radar', 'R'),
	('Campaign Lead', 'Dashboard', 'R'),
	('Campaign Lead', 'Governance', 'NONE'),
	('Campaign Lead', 'Smart Agents', 'RW'),
	('Campaign Lead', 'Admin', 'NONE'),
	('Factory Agentic Lead', 'Prospects', 'R'),
	('Factory Agentic Lead', 'Campaigns', 'R');
INSERT INTO mmf_portal.role_permissions (role_name, module_name, access_level) VALUES
	('Factory Agentic Lead', 'Solutions & Assets', 'R'),
	('Factory Agentic Lead', 'Triggers Radar', 'RW'),
	('Factory Agentic Lead', 'Dashboard', 'R'),
	('Factory Agentic Lead', 'Governance', 'NONE'),
	('Factory Agentic Lead', 'Smart Agents', 'RW'),
	('Factory Agentic Lead', 'Admin', 'NONE'),
	('Factory Solution & Assets Lead', 'Prospects', 'R'),
	('Factory Solution & Assets Lead', 'Campaigns', 'R'),
	('Factory Solution & Assets Lead', 'Solutions & Assets', 'RW_CERTIFY'),
	('Factory Solution & Assets Lead', 'Triggers Radar', 'R'),
	('Factory Solution & Assets Lead', 'Dashboard', 'R'),
	('Factory Solution & Assets Lead', 'Governance', 'NONE'),
	('Factory Solution & Assets Lead', 'Smart Agents', 'R'),
	('Factory Solution & Assets Lead', 'Admin', 'NONE'),
	('Admin', 'Prospects', 'R'),
	('Admin', 'Campaigns', 'R'),
	('Admin', 'Solutions & Assets', 'R'),
	('Admin', 'Triggers Radar', 'R'),
	('Admin', 'Dashboard', 'R'),
	('Admin', 'Governance', 'RW'),
	('Admin', 'Smart Agents', 'R'),
	('Admin', 'Admin', 'RW');

INSERT INTO mmf_portal.uploaded_target_accounts (id, name, business_unit_code, country_name, sector, owner_name, salesforce_account_id, match_confidence, campaign_id) OVERRIDING SYSTEM VALUE VALUES
	(1, 'Yorkshire Precision Ltd', 'UK', NULL, 'Manufacturing', 'L. Murray', NULL, 'Medium', 1),
	(2, 'Tyne Components plc', 'UK', NULL, 'Manufacturing', 'L. Murray', NULL, 'Low', 1),
	(3, 'Sachsen Logistik', 'DE', NULL, 'Transport', 'T. Schmidt', NULL, 'Medium', 5),
	(4, 'Munich Retail Group', 'DE', NULL, 'Retail', 'T. Schmidt', '0011t00000XyZ12', 'High', 8),
	(5, 'Van Oord Logistics', 'NL', NULL, 'Transport', 'J. Bakker', NULL, 'High', 10),
	(6, 'Vasa Retail AB', 'NO', 'Sweden', 'Retail', 'A. Lindqvist', NULL, 'Medium', 14);

SELECT pg_catalog.setval('mmf_portal.accounts_id_seq', 20, true);

SELECT pg_catalog.setval('mmf_portal.agent_launches_id_seq', 1, false);

SELECT pg_catalog.setval('mmf_portal.agent_usage_metrics_id_seq', 6, true);

SELECT pg_catalog.setval('mmf_portal.assets_id_seq', 14, true);

SELECT pg_catalog.setval('mmf_portal.audit_events_id_seq', 6, true);

SELECT pg_catalog.setval('mmf_portal.campaign_history_id_seq', 5, true);

SELECT pg_catalog.setval('mmf_portal.campaign_partner_plays_id_seq', 1, false);

SELECT pg_catalog.setval('mmf_portal.campaigns_id_seq', 17, true);

SELECT pg_catalog.setval('mmf_portal.data_source_connectors_id_seq', 8, true);

SELECT pg_catalog.setval('mmf_portal.governance_actions_id_seq', 6, true);

SELECT pg_catalog.setval('mmf_portal.governance_councils_id_seq', 3, true);

SELECT pg_catalog.setval('mmf_portal.governance_decisions_id_seq', 5, true);

SELECT pg_catalog.setval('mmf_portal.governance_meetings_id_seq', 3, true);

SELECT pg_catalog.setval('mmf_portal.kpi_snapshots_id_seq', 15, true);

SELECT pg_catalog.setval('mmf_portal.mvp_outcomes_id_seq', 3, true);

SELECT pg_catalog.setval('mmf_portal.partner_plays_id_seq', 7, true);

SELECT pg_catalog.setval('mmf_portal.prospect_interactions_id_seq', 5, true);

SELECT pg_catalog.setval('mmf_portal.radar_engines_id_seq', 8, true);

SELECT pg_catalog.setval('mmf_portal.radar_signals_id_seq', 15, true);

SELECT pg_catalog.setval('mmf_portal.smart_agents_id_seq', 29, true);

SELECT pg_catalog.setval('mmf_portal.solutions_id_seq', 8, true);

SELECT pg_catalog.setval('mmf_portal.uploaded_target_accounts_id_seq', 6, true);
