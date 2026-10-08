BEGIN;
CREATE SCHEMA IF NOT EXISTS mmf_portal;

-- Consolidated from V1__create_mmf_portal_schema.sql

CREATE TABLE mmf_portal.business_units
(
    code          text PRIMARY KEY,
    name          text    NOT NULL UNIQUE,
    has_countries boolean NOT NULL DEFAULT false
);

CREATE TABLE mmf_portal.countries
(
    name               text PRIMARY KEY,
    business_unit_code text NOT NULL REFERENCES mmf_portal.business_units (code),
    UNIQUE (name, business_unit_code)
);

CREATE TABLE mmf_portal.portal_views
(
    name        text PRIMARY KEY,
    description text  NOT NULL,
    navigation  jsonb NOT NULL CHECK (jsonb_typeof(navigation) = 'array')
);

CREATE TABLE mmf_portal.roles
(
    name               text PRIMARY KEY,
    rights_description text NOT NULL,
    portal_view_name   text NOT NULL REFERENCES mmf_portal.portal_views (name)
);

CREATE TABLE mmf_portal.modules
(
    name text PRIMARY KEY
);

CREATE TABLE mmf_portal.role_permissions
(
    role_name    text NOT NULL REFERENCES mmf_portal.roles (name) ON DELETE CASCADE,
    module_name  text NOT NULL REFERENCES mmf_portal.modules (name) ON DELETE CASCADE,
    access_level text NOT NULL CHECK (access_level IN ('NONE', 'R', 'RW', 'RW_CERTIFY')),
    PRIMARY KEY (role_name, module_name)
);

CREATE TABLE mmf_portal.accounts
(
    name               text PRIMARY KEY,
    business_unit_code text     NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name       text REFERENCES mmf_portal.countries (name),
    sector             text     NOT NULL,
    tier               smallint NOT NULL CHECK (tier IN (1, 2)),
    owner_name         text     NOT NULL,
    source             text     NOT NULL
);

CREATE TABLE mmf_portal.prospect_upload_batches
(
    id                 text PRIMARY KEY,
    file_name          text        NOT NULL,
    business_unit_code text        NOT NULL REFERENCES mmf_portal.business_units (code),
    uploaded_by        text        NOT NULL,
    uploaded_at        timestamptz NOT NULL,
    row_count          integer     NOT NULL CHECK (row_count >= 0),
    accepted_count     integer     NOT NULL CHECK (accepted_count >= 0),
    rejected_count     integer     NOT NULL CHECK (rejected_count >= 0),
    status             text        NOT NULL,
    CHECK (accepted_count + rejected_count = row_count)
);

CREATE TABLE mmf_portal.prospect_upload_records
(
    batch_id     text    NOT NULL REFERENCES mmf_portal.prospect_upload_batches (id) ON DELETE CASCADE,
    row_number   integer NOT NULL CHECK (row_number > 0),
    company_name text,
    result       text    NOT NULL CHECK (result IN ('Accepted', 'Rejected')),
    reason       text,
    PRIMARY KEY (batch_id, row_number)
);

CREATE TABLE mmf_portal.prospects
(
    id                       text PRIMARY KEY,
    account_name             text           NOT NULL REFERENCES mmf_portal.accounts (name),
    business_unit_code       text           NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name             text REFERENCES mmf_portal.countries (name),
    industry                 text           NOT NULL,
    estimated_tcv_millions   numeric(12, 2) NOT NULL CHECK (estimated_tcv_millions >= 0),
    lifecycle_stage          text           NOT NULL CHECK (lifecycle_stage IN (
                                                                                'Target Identified', 'Research',
                                                                                'Outreach',
                                                                                'Meetings Scheduled / Delivered',
                                                                                'Qualified Lead',
                                                                                'Converted to Opportunity'
        )),
    owner_name               text           NOT NULL,
    expected_signing_quarter text           NOT NULL CHECK (expected_signing_quarter ~ '^Q[1-4]-[0-9]{4}$'
) ,
    source text NOT NULL CHECK (source IN ('Single form', 'Excel upload', 'Radar signal', 'Campaign')),
    upload_batch_id text REFERENCES mmf_portal.prospect_upload_batches(id),
    qualification_status text NOT NULL
);

CREATE TABLE mmf_portal.prospect_interactions
(
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prospect_id      text NOT NULL REFERENCES mmf_portal.prospects (id) ON DELETE CASCADE,
    interaction_type text NOT NULL CHECK (interaction_type IN
                                          ('Outreach', 'Call', 'Meeting scheduled', 'Meeting delivered')),
    interaction_date date NOT NULL,
    seller_name      text NOT NULL,
    notes            text NOT NULL,
    next_action      text NOT NULL,
    status           text NOT NULL CHECK (status IN ('Open', 'Closed')),
    due_date         date NOT NULL
);

CREATE TABLE mmf_portal.solutions
(
    name                 text PRIMARY KEY,
    solution_class       text    NOT NULL CHECK (solution_class IN ('Industry', 'Business Line', 'Cross-Business Line')),
    tags                 text[] NOT NULL DEFAULT '{}',
    maturity             text    NOT NULL CHECK (maturity IN ('Draft', 'In-Development', 'Industrialized')),
    certification_status text    NOT NULL CHECK (certification_status IN ('Draft', 'Submitted', 'Certified & Published')),
    reuse_count          integer NOT NULL DEFAULT 0 CHECK (reuse_count >= 0)
);

CREATE TABLE mmf_portal.assets
(
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                 text    NOT NULL,
    asset_type           text    NOT NULL,
    version              text    NOT NULL,
    certification_status text    NOT NULL CHECK (certification_status IN ('Draft', 'Submitted', 'Certified & Published')),
    solution_name        text    NOT NULL REFERENCES mmf_portal.solutions (name),
    carve_out_ready      boolean NOT NULL DEFAULT false,
    UNIQUE (name, version)
);

CREATE TABLE mmf_portal.play_templates
(
    name          text PRIMARY KEY,
    channel       text    NOT NULL,
    step_count    integer NOT NULL CHECK (step_count > 0),
    solution_name text    NOT NULL REFERENCES mmf_portal.solutions (name)
);

CREATE TABLE mmf_portal.radar_engines
(
    name               text PRIMARY KEY,
    business_unit_code text    NOT NULL REFERENCES mmf_portal.business_units (code),
    client_count       integer NOT NULL CHECK (client_count >= 0),
    rule_count         integer NOT NULL CHECK (rule_count >= 0),
    schedule           text    NOT NULL,
    signal_count       integer NOT NULL CHECK (signal_count >= 0)
);

CREATE TABLE mmf_portal.campaigns
(
    name                    text PRIMARY KEY,
    business_unit_code      text           NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name            text REFERENCES mmf_portal.countries (name),
    status                  text           NOT NULL CHECK (status IN
                                                           ('Draft', 'Planned', 'Approved', 'Active', 'Paused',
                                                            'Closed', 'Review')),
    solution_name           text           NOT NULL REFERENCES mmf_portal.solutions (name),
    radar_engine_name       text REFERENCES mmf_portal.radar_engines (name),
    owner_name              text           NOT NULL,
    approver_name           text           NOT NULL,
    start_date              date           NOT NULL,
    end_date                date           NOT NULL,
    target_account_count    integer        NOT NULL CHECK (target_account_count >= 0),
    accounts_reached        integer        NOT NULL CHECK (accounts_reached >= 0),
    outreach_count          integer        NOT NULL CHECK (outreach_count >= 0),
    meeting_count           integer        NOT NULL CHECK (meeting_count >= 0),
    pipeline_millions       numeric(12, 2) NOT NULL CHECK (pipeline_millions >= 0),
    opportunities_generated integer        NOT NULL CHECK (opportunities_generated >= 0),
    wins_millions           numeric(12, 2) NOT NULL CHECK (wins_millions >= 0),
    signal_driven           boolean        NOT NULL,
    CHECK (end_date >= start_date),
    CHECK (accounts_reached <= target_account_count)
);

CREATE TABLE mmf_portal.campaign_playbook_parts
(
    name          text PRIMARY KEY,
    description   text     NOT NULL,
    display_order smallint NOT NULL UNIQUE CHECK (display_order > 0)
);

CREATE TABLE mmf_portal.uploaded_target_accounts
(
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name                  text NOT NULL,
    business_unit_code    text NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name          text REFERENCES mmf_portal.countries (name),
    sector                text NOT NULL,
    campaign_name         text NOT NULL REFERENCES mmf_portal.campaigns (name) ON DELETE CASCADE,
    owner_name            text NOT NULL,
    salesforce_account_id text,
    match_confidence      text NOT NULL CHECK (match_confidence IN ('Low', 'Medium', 'High')),
    UNIQUE (name, campaign_name)
);

CREATE TABLE mmf_portal.campaign_history
(
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    campaign_name      text        NOT NULL REFERENCES mmf_portal.campaigns (name) ON DELETE CASCADE,
    changed_at         timestamptz NOT NULL,
    changed_by         text        NOT NULL,
    change_description text        NOT NULL
);

CREATE TABLE mmf_portal.opportunities
(
    id                  text PRIMARY KEY,
    name                text           NOT NULL,
    account_name        text           NOT NULL REFERENCES mmf_portal.accounts (name),
    business_unit_code  text           NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name        text REFERENCES mmf_portal.countries (name),
    industry            text           NOT NULL,
    value_millions      numeric(12, 2) NOT NULL CHECK (value_millions >= 0),
    stage               text           NOT NULL,
    owner_name          text           NOT NULL,
    close_date          date           NOT NULL,
    status              text           NOT NULL CHECK (status IN ('Open', 'Won', 'Lost')),
    is_mm_factory       boolean        NOT NULL DEFAULT false,
    solution_name       text REFERENCES mmf_portal.solutions (name),
    probability_percent smallint       NOT NULL CHECK (probability_percent BETWEEN 0 AND 100),
    competitor          text,
    prospect_id         text UNIQUE REFERENCES mmf_portal.prospects (id)
);

CREATE TABLE mmf_portal.radar_signals
(
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_unit_code text     NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name       text REFERENCES mmf_portal.countries (name),
    account_name       text     NOT NULL REFERENCES mmf_portal.accounts (name),
    radar_engine_name  text     NOT NULL REFERENCES mmf_portal.radar_engines (name),
    title              text     NOT NULL,
    source             text     NOT NULL,
    score              smallint NOT NULL CHECK (score BETWEEN 0 AND 100),
    severity           text     NOT NULL CHECK (severity IN ('Low', 'Medium', 'High')),
    status             text     NOT NULL CHECK (status IN ('New', 'Reviewed', 'Dismissed')),
    summary            text     NOT NULL,
    UNIQUE (account_name, title)
);

CREATE TABLE mmf_portal.data_source_connectors
(
    name                 text PRIMARY KEY,
    connector_type       text    NOT NULL,
    credential_reference text,
    license_terms        text    NOT NULL,
    is_active            boolean NOT NULL DEFAULT true,
    used_by              text[] NOT NULL DEFAULT '{}'
);

CREATE TABLE mmf_portal.smart_agents
(
    name              text PRIMARY KEY,
    lifecycle_stage   text NOT NULL,
    agent_type        text NOT NULL CHECK (agent_type IN ('Internal', 'External')),
    status            text NOT NULL CHECK (status IN ('Published', 'In-Test', 'Draft', 'Retired')),
    version           text NOT NULL,
    description       text NOT NULL,
    grounding_sources text[] NOT NULL DEFAULT '{}'
);

CREATE TABLE mmf_portal.agent_usage_metrics
(
    id                           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name                   text          NOT NULL REFERENCES mmf_portal.smart_agents (name) ON DELETE CASCADE,
    measured_at                  timestamptz   NOT NULL,
    invocation_count             integer       NOT NULL CHECK (invocation_count >= 0),
    distinct_user_count          integer       NOT NULL CHECK (distinct_user_count >= 0),
    average_rating               numeric(2, 1) NOT NULL CHECK (average_rating BETWEEN 0 AND 5),
    output_count                 integer       NOT NULL CHECK (output_count >= 0),
    invocations_by_business_unit jsonb         NOT NULL,
    invocations_by_country       jsonb         NOT NULL,
    invocations_by_role          jsonb         NOT NULL,
    trend                        text          NOT NULL,
    feedback                     text          NOT NULL,
    UNIQUE (agent_name, measured_at)
);

CREATE TABLE mmf_portal.governance_councils
(
    name              text PRIMARY KEY,
    cadence           text    NOT NULL,
    scope             text    NOT NULL CHECK (scope IN ('SBU', 'BU')),
    next_meeting_date date    NOT NULL,
    chair_role        text    NOT NULL,
    decision_count    integer NOT NULL CHECK (decision_count >= 0),
    action_count      integer NOT NULL CHECK (action_count >= 0)
);

CREATE TABLE mmf_portal.governance_meetings
(
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    council_name   text    NOT NULL REFERENCES mmf_portal.governance_councils (name),
    meeting_date   date    NOT NULL,
    attendees      text    NOT NULL,
    notes          text    NOT NULL,
    decision_count integer NOT NULL CHECK (decision_count >= 0),
    action_count   integer NOT NULL CHECK (action_count >= 0),
    UNIQUE (council_name, meeting_date)
);

CREATE TABLE mmf_portal.governance_decisions
(
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    decision       text NOT NULL,
    owner_name     text NOT NULL,
    decision_date  date NOT NULL,
    status         text NOT NULL CHECK (status IN ('Open', 'Ratified')),
    reference_type text
);

CREATE TABLE mmf_portal.governance_actions
(
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action     text NOT NULL,
    owner_name text NOT NULL,
    due_date   date NOT NULL,
    status     text NOT NULL CHECK (status IN ('Open', 'Closed'))
);

CREATE TABLE mmf_portal.raci_assignments
(
    activity    text PRIMARY KEY,
    responsible text NOT NULL,
    accountable text NOT NULL,
    consulted   text NOT NULL,
    informed    text NOT NULL
);

CREATE TABLE mmf_portal.mvp_outcomes
(
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    outcome text NOT NULL UNIQUE,
    status  text NOT NULL
);

CREATE TABLE mmf_portal.reference_data
(
    category          text PRIMARY KEY,
    values_text       text NOT NULL,
    governance_status text NOT NULL
);

CREATE TABLE mmf_portal.kpi_definitions
(
    name       text PRIMARY KEY,
    unit       text NOT NULL,
    definition text NOT NULL,
    dimensions text[] NOT NULL
);

CREATE TABLE mmf_portal.kpi_snapshots
(
    id                        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    as_of                     timestamptz    NOT NULL,
    business_unit_code        text           NOT NULL REFERENCES mmf_portal.business_units (code),
    country_name              text REFERENCES mmf_portal.countries (name),
    pipeline_millions         numeric(12, 2) NOT NULL,
    revenue_millions          numeric(12, 2) NOT NULL,
    coverage_percent          numeric(5, 2)  NOT NULL CHECK (coverage_percent BETWEEN 0 AND 100),
    reuse_percent             numeric(5, 2)  NOT NULL CHECK (reuse_percent BETWEEN 0 AND 100),
    signal_count              integer        NOT NULL,
    signal_conversion_percent numeric(5, 2)  NOT NULL CHECK (signal_conversion_percent BETWEEN 0 AND 100),
    outreach_count            integer        NOT NULL,
    meeting_count             integer        NOT NULL,
    opportunities_created     integer        NOT NULL,
    stage_conversion_percent  numeric(5, 2)  NOT NULL CHECK (stage_conversion_percent BETWEEN 0 AND 100),
    pipeline_target_millions  numeric(12, 2) NOT NULL,
    revenue_target_millions   numeric(12, 2) NOT NULL,
    coverage_target_percent   numeric(5, 2)  NOT NULL CHECK (coverage_target_percent BETWEEN 0 AND 100),
    UNIQUE (as_of, business_unit_code, country_name)
);

CREATE TABLE mmf_portal.audit_events
(
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occurred_at   timestamptz NOT NULL,
    actor_name    text        NOT NULL,
    action        text        NOT NULL,
    event_details text        NOT NULL
);

CREATE INDEX prospects_scope_idx ON mmf_portal.prospects (business_unit_code, country_name, lifecycle_stage);
CREATE INDEX opportunities_scope_idx ON mmf_portal.opportunities (business_unit_code, country_name, status);
CREATE INDEX campaigns_scope_idx ON mmf_portal.campaigns (business_unit_code, country_name, status);
CREATE INDEX radar_signals_scope_idx ON mmf_portal.radar_signals (business_unit_code, country_name, status, score DESC);
CREATE INDEX interactions_prospect_date_idx ON mmf_portal.prospect_interactions (prospect_id, interaction_date DESC);
CREATE INDEX audit_events_occurred_at_idx ON mmf_portal.audit_events (occurred_at DESC);

-- Consolidated from V2__seed_mmf_portal_data.sql

-- Illustrative development data migrated from database/seed.sql.
-- This migration intentionally runs once; do not place mutable test data here.
INSERT INTO mmf_portal.business_units(code, name, has_countries)
VALUES ('UK', 'UK', false),
       ('DE', 'Germany', false),
       ('NL', 'Netherlands', false),
       ('NO', 'Nordics', true);

INSERT INTO mmf_portal.countries(name, business_unit_code)
VALUES ('Sweden', 'NO'),
       ('Finland', 'NO'),
       ('Norway', 'NO'),
       ('Denmark', 'NO');

INSERT INTO mmf_portal.portal_views(name, description, navigation)
VALUES ('Leadership', 'Executive performance, BU/SBU roll-ups, objectives, pipeline and campaign outcomes', '[
  "dashboard",
  "prospects",
  "campaigns",
  "governance",
  "scope"
]'),
       ('Factory / Operations', 'Campaign, prospect, asset, trigger, agent and governance operations', '[
         "dashboard",
         "prospects",
         "campaigns",
         "solutions",
         "radar",
         "agents",
         "governance",
         "admin",
         "scope"
       ]'),
       ('Seller', 'Assigned prospects and accounts, signals, interactions, campaigns, opportunities and Smart Agents',
        '[
          "dashboard",
          "prospects",
          "campaigns",
          "solutions",
          "radar",
          "agents",
          "scope"
        ]');

INSERT INTO mmf_portal.roles(name, rights_description, portal_view_name)
VALUES ('SBU Factory Leader', 'Read-all roll-up across BUs; owns shared/SBU objectives and SBU governance',
        'Leadership'),
       ('BU Factory Leader', 'Owns Factory activation for their BU: solutions, campaigns, triggers and BU governance',
        'Factory / Operations'),
       ('BU MM (Business) Leader', 'Owns BU targets, accounts, target lists and team; chairs the BU joint plan',
        'Leadership'),
       ('Seller / Client Partner',
        'Works accounts; consumes signals and assets; flags MM-Factory opportunities; runs agents and campaigns',
        'Seller'),
       ('Solution Architect / SME', 'Creates and maintains solutions and assets', 'Factory / Operations'),
       ('Campaign Lead', 'Creates and manages campaigns and plays', 'Factory / Operations'),
       ('Factory Agentic Lead',
        'Configures radar engines, rules and sources; authors, registers and governs Smart Agents',
        'Factory / Operations'),
       ('Factory Solution & Assets Lead', 'Owns the Solutions & Assets library; certifies and publishes',
        'Factory / Operations'),
       ('Admin', 'Manages users, roles, permissions, reference data, connectors and integrations',
        'Factory / Operations');

INSERT INTO mmf_portal.modules(name)
VALUES ('Prospects'),
       ('Campaigns'),
       ('Solutions & Assets'),
       ('Triggers Radar'),
       ('Dashboard'),
       ('Governance'),
       ('Smart Agents'),
       ('Admin');

INSERT INTO mmf_portal.role_permissions(role_name, module_name, access_level)
SELECT role_name,
       module_name,
       CASE raw_access WHEN '—' THEN 'NONE' WHEN 'RW*' THEN 'RW_CERTIFY' ELSE raw_access END
FROM (VALUES ('SBU Factory Leader', ARRAY['R', 'R', 'R', 'R', 'RW', 'RW', 'R', '—']),
             ('BU Factory Leader', ARRAY['RW', 'RW', 'R', 'RW', 'R', 'RW', 'R', '—']),
             ('BU MM (Business) Leader', ARRAY['RW', 'RW', 'R', 'R', 'R', 'RW', 'R', '—']),
             ('Seller / Client Partner', ARRAY['RW', 'R', 'R', 'RW', 'R', '—', 'RW', '—']),
             ('Solution Architect / SME', ARRAY['R', 'R', 'RW', 'R', 'R', '—', 'RW', '—']),
             ('Campaign Lead', ARRAY['RW', 'RW', 'R', 'R', 'R', '—', 'RW', '—']),
             ('Factory Agentic Lead', ARRAY['R', 'R', 'R', 'RW', 'R', '—', 'RW', '—']),
             ('Factory Solution & Assets Lead', ARRAY['R', 'R', 'RW*', 'R', 'R', '—', 'R', '—']),
             ('Admin', ARRAY['R', 'R', 'R', 'R', 'R', 'RW', 'R', 'RW'])) AS permission_rows(role_name, access_values)
         CROSS JOIN LATERAL unnest(access_values) WITH ORDINALITY AS access(raw_access, position)
JOIN (VALUES
    (1, 'Prospects'), (2, 'Campaigns'), (3, 'Solutions & Assets'), (4, 'Triggers Radar'),
    (5, 'Dashboard'), (6, 'Governance'), (7, 'Smart Agents'), (8, 'Admin')
) AS module_rows(position, module_name) USING (position);

INSERT INTO mmf_portal.accounts(name, business_unit_code, country_name, sector, tier, owner_name, source)
VALUES ('Albion Foods', 'UK', NULL, 'CPG', 1, 'R. Patel', 'Salesforce'),
       ('Thames Utilities', 'UK', NULL, 'E&U', 1, 'R. Patel', 'Salesforce'),
       ('Pennine Manufacturing', 'UK', NULL, 'Manufacturing', 2, 'L. Murray', 'Portal upload'),
       ('Mersey Care Group', 'UK', NULL, 'Life Sciences', 2, 'L. Murray', 'Portal upload'),
       ('Rheinwerk AG', 'DE', NULL, 'Manufacturing', 1, 'K. Weber', 'Salesforce'),
       ('BavariaTech GmbH', 'DE', NULL, 'TMT', 2, 'K. Weber', 'Salesforce'),
       ('NordChem', 'DE', NULL, 'E&U', 1, 'T. Schmidt', 'Salesforce'),
       ('Munich Retail Group', 'DE', NULL, 'Retail', 2, 'T. Schmidt', 'Portal upload'),
       ('Sachsen Logistik', 'DE', NULL, 'Transport', 2, 'T. Schmidt', 'Portal upload'),
       ('Delft Mobility', 'NL', NULL, 'Automotive', 2, 'M. Jansen', 'Salesforce'),
       ('Rotterdam FoodCo', 'NL', NULL, 'CPG', 1, 'S. de Vries', 'Salesforce'),
       ('Amstel Retail Group', 'NL', NULL, 'Retail', 2, 'J. Bakker', 'Portal upload'),
       ('Van Oord Logistics', 'NL', NULL, 'Transport', 1, 'J. Bakker', 'Portal upload'),
       ('Haarlem Insurance', 'NL', NULL, 'Financial Services', 2, 'J. Bakker', 'Derived from prospect mock data'),
       ('Eindhoven Devices BV', 'NL', NULL, 'Manufacturing', 2, 'M. Jansen', 'Derived from prospect mock data'),
       ('Nordic Steel AB', 'NO', 'Sweden', 'Manufacturing', 1, 'A. Lindqvist', 'Salesforce'),
       ('Vasa Retail AB', 'NO', 'Sweden', 'Retail', 2, 'A. Lindqvist', 'Portal upload'),
       ('Suomi Paper Oyj', 'NO', 'Finland', 'Manufacturing', 1, 'M. Virtanen', 'Salesforce'),
       ('Fjord Energy ASA', 'NO', 'Norway', 'E&U', 1, 'E. Hansen', 'Portal upload'),
       ('Copenhagen Logistics', 'NO', 'Denmark', 'Transport', 2, 'N. Sørensen', 'Portal upload');

INSERT INTO mmf_portal.prospect_upload_batches
(id, file_name, business_unit_code, uploaded_by, uploaded_at, row_count, accepted_count, rejected_count, status)
VALUES ('BATCH-0007', 'UK_manufacturing_wave2.xlsx', 'UK', 'R. Patel', '2026-09-01 09:00:00+02', 44, 38, 6,
        'Validated - awaiting commit'),
       ('BATCH-0006', 'NORDICS_wave1.xlsx', 'NO', 'A. Lindqvist', '2026-08-27 09:00:00+02', 36, 33, 3, 'Committed'),
       ('BATCH-0005', 'NL_target_list_H2.xlsx', 'NL', 'S. de Vries', '2026-08-25 09:00:00+02', 62, 58, 4, 'Committed'),
       ('BATCH-0004', 'DE_industrial_targets.xlsx', 'DE', 'K. Weber', '2026-08-18 09:00:00+02', 81, 74, 7, 'Committed');

INSERT INTO mmf_portal.prospect_upload_records (batch_id, row_number, company_name, result, reason)
VALUES ('BATCH-0007', 3, 'Yorkshire Precision Ltd', 'Accepted', NULL),
       ('BATCH-0007', 4, 'Tyne Components plc', 'Accepted', NULL),
       ('BATCH-0007', 19, 'Midlands Tooling', 'Rejected',
        'Sector code missing - must match the governed Industry list'),
       ('BATCH-0007', 22, 'Pennine Manufacturing', 'Rejected',
        'Duplicate - matches existing prospect PRS-UK-00013 (name + BU)'),
       ('BATCH-0007', 27, 'Clyde Fabrication', 'Rejected', 'Owner not a provisioned user in this BU'),
       ('BATCH-0007', 31, NULL, 'Rejected', 'Company name empty'),
       ('BATCH-0007', 33, 'Solent Marine Ltd', 'Rejected', 'Estimated TCV is not numeric'),
       ('BATCH-0007', 38, 'Anglia Foods Ltd', 'Rejected', 'Country supplied for a BU that is not split');

INSERT INTO mmf_portal.prospects
(id, account_name, business_unit_code, country_name, industry, estimated_tcv_millions, lifecycle_stage, owner_name,
 expected_signing_quarter, source, upload_batch_id, qualification_status)
VALUES ('PRS-UK-00013', 'Pennine Manufacturing', 'UK', NULL, 'Manufacturing', 2.2, 'Research', 'L. Murray', 'Q1-2027',
        'Excel upload', 'BATCH-0007', 'In research'),
       ('PRS-UK-00016', 'Thames Utilities', 'UK', NULL, 'E&U', 4.8, 'Qualified Lead', 'R. Patel', 'Q4-2026',
        'Radar signal', NULL, 'Qualified'),
       ('PRS-UK-00019', 'Mersey Care Group', 'UK', NULL, 'Life Sciences', 1.4, 'Meetings Scheduled / Delivered',
        'L. Murray', 'Q2-2027', 'Single form', NULL, 'Engaged'),
       ('PRS-UK-00021', 'Albion Foods', 'UK', NULL, 'CPG', 5.5, 'Converted to Opportunity', 'R. Patel', 'Q1-2027',
        'Campaign', NULL, 'Converted'),
       ('PRS-DE-00042', 'Rheinwerk AG', 'DE', NULL, 'Manufacturing', 5.6, 'Converted to Opportunity', 'K. Weber',
        'Q4-2026', 'Radar signal', NULL, 'Converted'),
       ('PRS-DE-00045', 'BavariaTech GmbH', 'DE', NULL, 'TMT', 2.1, 'Outreach', 'K. Weber', 'Q1-2027', 'Excel upload',
        'BATCH-0004', 'Contacted'),
       ('PRS-DE-00048', 'Sachsen Logistik', 'DE', NULL, 'Transport', 1.7, 'Target Identified', 'T. Schmidt', 'Q2-2027',
        'Excel upload', 'BATCH-0004', 'Identified'),
       ('PRS-DE-00051', 'Munich Retail Group', 'DE', NULL, 'Retail', 3.4, 'Meetings Scheduled / Delivered',
        'T. Schmidt', 'Q4-2026', 'Campaign', NULL, 'Engaged'),
       ('PRS-NL-00021', 'Van Oord Logistics', 'NL', NULL, 'Transport', 2.4, 'Target Identified', 'J. Bakker', 'Q1-2027',
        'Excel upload', 'BATCH-0005', 'Identified'),
       ('PRS-NL-00024', 'Rotterdam FoodCo', 'NL', NULL, 'CPG', 3.1, 'Meetings Scheduled / Delivered', 'S. de Vries',
        'Q4-2026', 'Radar signal', NULL, 'Engaged'),
       ('PRS-NL-00029', 'Haarlem Insurance', 'NL', NULL, 'Financial Services', 2.9, 'Qualified Lead', 'J. Bakker',
        'Q4-2026', 'Single form', NULL, 'Qualified'),
       ('PRS-NL-00030', 'Eindhoven Devices BV', 'NL', NULL, 'Manufacturing', 4.2, 'Meetings Scheduled / Delivered',
        'M. Jansen', 'Q1-2027', 'Campaign', NULL, 'Engaged'),
       ('PRS-NO-00007', 'Vasa Retail AB', 'NO', 'Sweden', 'Retail', 2.0, 'Outreach', 'A. Lindqvist', 'Q1-2027',
        'Excel upload', 'BATCH-0006', 'Contacted'),
       ('PRS-NO-00009', 'Nordic Steel AB', 'NO', 'Sweden', 'Manufacturing', 3.6, 'Meetings Scheduled / Delivered',
        'A. Lindqvist', 'Q4-2026', 'Campaign', NULL, 'Engaged'),
       ('PRS-NO-00004', 'Suomi Paper Oyj', 'NO', 'Finland', 'Manufacturing', 2.8, 'Qualified Lead', 'M. Virtanen',
        'Q4-2026', 'Radar signal', NULL, 'Qualified'),
       ('PRS-NO-00003', 'Fjord Energy ASA', 'NO', 'Norway', 'E&U', 3.9, 'Meetings Scheduled / Delivered', 'E. Hansen',
        'Q1-2027', 'Single form', NULL, 'Engaged'),
       ('PRS-NO-00002', 'Copenhagen Logistics', 'NO', 'Denmark', 'Transport', 1.6, 'Outreach', 'N. Sørensen', 'Q1-2027',
        'Excel upload', 'BATCH-0006', 'Contacted');

INSERT INTO mmf_portal.prospect_interactions
(prospect_id, interaction_type, interaction_date, seller_name, notes, next_action, status, due_date)
VALUES ('PRS-DE-00042', 'Meeting delivered', '2026-08-21', 'K. Weber',
        'CIO confirmed the plant modernization programme; legacy ERP named as the blocker.',
        'Send value case and book a workshop', 'Closed', '2026-08-28'),
       ('PRS-DE-00042', 'Meeting scheduled', '2026-09-04', 'K. Weber',
        'Value workshop with CIO and Head of Applications.', 'Prepare workshop pack', 'Open', '2026-09-03'),
       ('PRS-UK-00016', 'Call', '2026-08-26', 'R. Patel', 'AMP8 plan approved; asset data is a named workstream.',
        'Introduce grid analytics reference', 'Open', '2026-09-05'),
       ('PRS-NL-00024', 'Meeting delivered', '2026-08-28', 'S. de Vries',
        'Tender for application support consolidation confirmed, closing in five weeks.', 'Assemble bid team', 'Open',
        '2026-09-04'),
       ('PRS-NO-00004', 'Outreach', '2026-08-19', 'M. Virtanen',
        'Efficiency programme announced; shared services in scope.', 'Request discovery session', 'Open', '2026-09-08');

INSERT INTO mmf_portal.solutions (name, solution_class, tags, maturity, certification_status, reuse_count)
VALUES ('IT Cost Takeout', 'Cross-Business Line', ARRAY['ADM', 'CIS'], 'Industrialized', 'Certified & Published', 34),
       ('SAP S/4 Rapid Migration', 'Business Line', ARRAY['ADM'], 'Industrialized', 'Certified & Published', 41),
       ('Hyperscaler Landing Zone', 'Cross-Business Line', ARRAY['CIS', 'I&D'], 'Industrialized',
        'Certified & Published', 28),
       ('Manufacturing Smart Factory', 'Industry', ARRAY['Manufacturing'], 'Industrialized', 'Certified & Published',
        22),
       ('E&U Grid Data Platform', 'Industry', ARRAY['E&U'], 'Industrialized', 'Certified & Published', 15),
       ('Retail Commerce Accelerator', 'Industry', ARRAY['Retail'], 'In-Development', 'Submitted', 9),
       ('Vendor Consolidation Play', 'Cross-Business Line', ARRAY['ADM', 'CIS'], 'In-Development', 'Submitted', 12),
       ('Cyber Baseline for Mid-Market', 'Cross-Business Line', ARRAY['CIS'], 'Draft', 'Draft', 3);

INSERT INTO mmf_portal.radar_engines (name, business_unit_code, client_count, rule_count, schedule, signal_count)
VALUES ('UK · Manufacturing & CPG', 'UK', 24, 5, 'Daily', 13),
       ('UK · Energy & Utilities', 'UK', 14, 4, 'Daily', 7),
       ('Germany · Industrial', 'DE', 28, 7, 'Daily', 18),
       ('Germany · TMT & E&U', 'DE', 19, 5, 'Daily', 11),
       ('Netherlands · Industrial', 'NL', 22, 6, 'Daily', 14),
       ('Netherlands · Retail & CPG', 'NL', 16, 4, 'Daily', 9),
       ('Nordics · Industrial', 'NO', 18, 4, 'Daily', 8),
       ('Nordics · Energy', 'NO', 12, 3, 'Daily', 5);

INSERT INTO mmf_portal.campaigns
(name, business_unit_code, country_name, status, solution_name, radar_engine_name, owner_name, approver_name,
 start_date, end_date, target_account_count, accounts_reached, outreach_count, meeting_count, pipeline_millions,
 opportunities_generated, wins_millions, signal_driven)
VALUES ('UK Manufacturing — ADM Reboot', 'UK', NULL, 'Active', 'IT Cost Takeout', 'UK · Manufacturing & CPG',
        'R. Patel', 'UK MM Leader', '2026-06-20', '2026-09-12', 13, 7, 64, 9, 5.5, 2, 0, true),
       ('UK E&U — Grid Analytics', 'UK', NULL, 'Active', 'E&U Grid Data Platform', 'UK · Energy & Utilities',
        'L. Murray', 'UK MM Leader', '2026-07-01', '2026-09-10', 7, 4, 38, 5, 3.8, 1, 0, true),
       ('UK CPG — SAP S/4 Wave 1', 'UK', NULL, 'Approved', 'SAP S/4 Rapid Migration', NULL, 'R. Patel', 'UK MM Leader',
        '2026-09-01', '2026-12-10', 9, 0, 0, 0, 0, 0, 0, false),
       ('UK Cross-sector — Cyber Baseline', 'UK', NULL, 'Draft', 'Cyber Baseline for Mid-Market', NULL, 'L. Murray',
        'TBC', '2026-10-15', '2026-12-12', 5, 0, 0, 0, 0, 0, 0, false),
       ('DE Industrial — Cost Takeout Q3', 'DE', NULL, 'Active', 'IT Cost Takeout', 'Germany · Industrial',
        'T. Schmidt', 'DE MM Leader', '2026-07-01', '2026-09-26', 16, 11, 92, 14, 9.6, 3, 5.2, true),
       ('DE Manufacturing — Smart Factory', 'DE', NULL, 'Active', 'Manufacturing Smart Factory', 'Germany · Industrial',
        'K. Weber', 'DE MM Leader', '2026-06-10', '2026-09-18', 12, 8, 71, 9, 8.2, 2, 0, true),
       ('DE TMT — Cloud Migration', 'DE', NULL, 'Planned', 'Hyperscaler Landing Zone', 'Germany · TMT & E&U',
        'K. Weber', 'DE MM Leader', '2026-09-01', '2026-11-12', 9, 0, 0, 0, 0, 0, 0, false),
       ('DE Retail — Commerce Push', 'DE', NULL, 'Review', 'Retail Commerce Accelerator', NULL, 'T. Schmidt',
        'DE MM Leader', '2026-04-01', '2026-06-26', 7, 6, 44, 8, 4.1, 2, 0, false),
       ('DE E&U — Grid Data Platform', 'DE', NULL, 'Paused', 'E&U Grid Data Platform', 'Germany · TMT & E&U',
        'K. Weber', 'DE MM Leader', '2026-05-15', '2026-09-30', 8, 3, 21, 2, 1.4, 0, 0, true),
       ('NL Industrial — IT Cost Takeout', 'NL', NULL, 'Active', 'IT Cost Takeout', 'Netherlands · Industrial',
        'S. de Vries', 'NL MM Leader', '2026-07-01', '2026-09-26', 14, 9, 78, 11, 6.4, 2, 0, true),
       ('NL Retail — Commerce Acceleration', 'NL', NULL, 'Active', 'Retail Commerce Accelerator',
        'Netherlands · Retail & CPG', 'J. Bakker', 'NL MM Leader', '2026-07-15', '2026-09-25', 8, 5, 41, 6, 2.9, 1, 0,
        true),
       ('NL Cross-sector — Vendor Consolidation', 'NL', NULL, 'Planned', 'Vendor Consolidation Play', NULL, 'M. Jansen',
        'NL MM Leader', '2026-09-01', '2026-10-30', 10, 0, 0, 0, 0, 0, 0, false),
       ('NL SAP — S/4 Readiness', 'NL', NULL, 'Closed', 'SAP S/4 Rapid Migration', NULL, 'S. de Vries', 'NL MM Leader',
        '2026-01-05', '2026-04-30', 6, 6, 35, 7, 3.2, 2, 1.8, false),
       ('SE Industrial — Smart Factory', 'NO', 'Sweden', 'Active', 'Manufacturing Smart Factory',
        'Nordics · Industrial', 'A. Lindqvist', 'Nordics MM Leader', '2026-07-01', '2026-09-26', 9, 6, 44, 7, 4.4, 1, 0,
        true),
       ('FI Manufacturing — ADM Consolidation', 'NO', 'Finland', 'Active', 'IT Cost Takeout', 'Nordics · Industrial',
        'M. Virtanen', 'Nordics MM Leader', '2026-06-15', '2026-09-10', 8, 5, 36, 6, 3.0, 1, 0, true),
       ('NO Energy — Cloud Foundation', 'NO', 'Norway', 'Active', 'Hyperscaler Landing Zone', 'Nordics · Energy',
        'E. Hansen', 'Nordics MM Leader', '2026-07-01', '2026-09-10', 7, 4, 29, 4, 2.6, 1, 0, true),
       ('DK Transport — Modernization', 'NO', 'Denmark', 'Planned', 'IT Cost Takeout', NULL, 'N. Sørensen',
        'Nordics MM Leader', '2026-09-10', '2026-12-05', 6, 0, 0, 0, 0, 0, 0, false);

INSERT INTO mmf_portal.opportunities
(id, name, account_name, business_unit_code, country_name, industry, value_millions, stage, owner_name, close_date,
 status, is_mm_factory, solution_name, probability_percent, competitor, prospect_id)
VALUES ('0061t00000AbcU1', 'Albion — SAP S/4', 'Albion Foods', 'UK', NULL, 'CPG', 5.5, 'Proposal', 'R. Patel',
        '2027-02-10', 'Open', true, 'SAP S/4 Rapid Migration', 45, 'IBM', 'PRS-UK-00021'),
       ('0061t00000AbcU4', 'Thames — Grid analytics', 'Thames Utilities', 'UK', NULL, 'E&U', 3.8, 'Discovery',
        'R. Patel', '2027-05-28', 'Open', true, 'E&U Grid Data Platform', 20, NULL, NULL),
       ('0061t00000AbcU7', 'Pennine — Cost takeout', 'Pennine Manufacturing', 'UK', NULL, 'Manufacturing', 2.4,
        'Qualify', 'L. Murray', '2027-04-18', 'Open', false, 'IT Cost Takeout', 30, 'Atos', NULL),
       ('0061t00000AbdK2', 'Rheinwerk — SAP S/4 migration', 'Rheinwerk AG', 'DE', NULL, 'Manufacturing', 8.2,
        'Negotiation', 'K. Weber', '2026-12-12', 'Open', true, 'SAP S/4 Rapid Migration', 60, 'Accenture',
        'PRS-DE-00042'),
       ('0061t00000AbdK5', 'Rheinwerk — IT cost takeout', 'Rheinwerk AG', 'DE', NULL, 'Manufacturing', 3.4, 'Qualify',
        'K. Weber', '2027-02-28', 'Open', true, 'IT Cost Takeout', 35, NULL, NULL),
       ('0061t00000AbdK9', 'BavariaTech — Cloud migration', 'BavariaTech GmbH', 'DE', NULL, 'TMT', 4.1, 'Discovery',
        'K. Weber', '2027-04-30', 'Open', false, 'Hyperscaler Landing Zone', 20, 'Capita', NULL),
       ('0061t00000AbdL1', 'NordChem — Data platform', 'NordChem', 'DE', NULL, 'E&U', 6.0, 'Negotiation', 'T. Schmidt',
        '2026-11-15', 'Open', true, 'E&U Grid Data Platform', 75, 'Atos', NULL),
       ('0061t00000AbdL4', 'NordChem — Managed services', 'NordChem', 'DE', NULL, 'E&U', 5.2, 'Closed Won',
        'T. Schmidt', '2026-07-02', 'Won', true, 'IT Cost Takeout', 100, NULL, NULL),
       ('0061t00000AbeM2', 'Delft Mobility — ADM consolidation', 'Delft Mobility', 'NL', NULL, 'Automotive', 4.7,
        'Proposal', 'M. Jansen', '2027-01-20', 'Open', true, 'IT Cost Takeout', 45, 'Sopra Steria', NULL),
       ('0061t00000AbeM6', 'Amstel Retail — Commerce revamp', 'Amstel Retail Group', 'NL', NULL, 'Retail', 2.9,
        'Qualify', 'J. Bakker', '2027-03-15', 'Open', true, 'Retail Commerce Accelerator', 30, 'Valtech', NULL),
       ('0061t00000AbeM9', 'Rotterdam FoodCo — Vendor consolidation', 'Rotterdam FoodCo', 'NL', NULL, 'CPG', 3.3,
        'Discovery', 'S. de Vries', '2027-04-30', 'Open', true, 'IT Cost Takeout', 20, NULL, NULL),
       ('0061t00000AbfN3', 'Nordic Steel — Smart factory', 'Nordic Steel AB', 'NO', 'Sweden', 'Manufacturing', 4.4,
        'Proposal', 'A. Lindqvist', '2026-12-18', 'Open', true, 'Manufacturing Smart Factory', 60, 'Tietoevry', NULL),
       ('0061t00000AbfN7', 'Suomi Paper — ADM consolidation', 'Suomi Paper Oyj', 'NO', 'Finland', 'Manufacturing', 3.0,
        'Discovery', 'M. Virtanen', '2027-06-12', 'Open', true, 'IT Cost Takeout', 20, 'Tietoevry', NULL),
       ('0061t00000AbfP1', 'Fjord Energy — Cloud foundation', 'Fjord Energy ASA', 'NO', 'Norway', 'E&U', 2.6, 'Qualify',
        'E. Hansen', '2027-03-22', 'Open', false, 'Hyperscaler Landing Zone', 35, 'Sopra Steria', NULL),
       ('0061t00000AbfP5', 'Copenhagen Logistics — Modernization', 'Copenhagen Logistics', 'NO', 'Denmark', 'Transport',
        2.1, 'Proposal', 'N. Sørensen', '2027-02-05', 'Open', true, 'IT Cost Takeout', 45, NULL, NULL);

INSERT INTO mmf_portal.assets (name, asset_type, version, certification_status, solution_name, carve_out_ready)
VALUES ('Cost takeout — solution blueprint', 'Blueprint', 'v3', 'Certified & Published', 'IT Cost Takeout', true),
       ('Cost takeout — value case model', 'Reusable template', 'v2', 'Certified & Published', 'IT Cost Takeout', true),
       ('Reference win — NordChem', 'Case study', 'v1', 'Certified & Published', 'IT Cost Takeout', false),
       ('Cost takeout — client pitch deck', 'Deck', 'v4', 'Certified & Published', 'IT Cost Takeout', false),
       ('S/4 readiness assessment', 'Reusable template', 'v2', 'Certified & Published', 'SAP S/4 Rapid Migration',
        true),
       ('S/4 migration blueprint', 'Blueprint', 'v5', 'Certified & Published', 'SAP S/4 Rapid Migration', true),
       ('S/4 RFP response library', 'RFP response', 'v3', 'Certified & Published', 'SAP S/4 Rapid Migration', false),
       ('Landing zone reference architecture', 'Blueprint', 'v3', 'Certified & Published', 'Hyperscaler Landing Zone',
        true),
       ('Landing zone proof-of-value pack', 'Reusable template', 'v1', 'Certified & Published',
        'Hyperscaler Landing Zone', true),
       ('Smart factory reference architecture', 'Blueprint', 'v2', 'Certified & Published',
        'Manufacturing Smart Factory', true),
       ('Grid data platform — case study', 'Case study', 'v1', 'Certified & Published', 'E&U Grid Data Platform',
        false),
       ('Commerce accelerator demo pack', 'Deck', 'v2', 'Submitted', 'Retail Commerce Accelerator', false),
       ('Vendor consolidation battle card', 'Reusable template', 'v1', 'Submitted', 'Vendor Consolidation Play', true),
       ('Cyber baseline offer 1-pager', 'Deck', 'v1', 'Draft', 'Cyber Baseline for Mid-Market', false);

INSERT INTO mmf_portal.play_templates (name, channel, step_count, solution_name)
VALUES ('Cost Takeout outreach sequence', 'Email', 4, 'IT Cost Takeout'),
       ('Value workshop play', 'Direct', 3, 'IT Cost Takeout'),
       ('S/4 readiness assessment play', 'Direct', 3, 'SAP S/4 Rapid Migration'),
       ('Landing-zone proof of value', 'Webinar', 5, 'Hyperscaler Landing Zone'),
       ('Smart factory discovery play', 'Direct', 4, 'Manufacturing Smart Factory');

INSERT INTO mmf_portal.campaign_playbook_parts (name, description, display_order)
VALUES ('Campaign Brief', 'Why now, the market context, the objective and the target segment', 1),
       ('Messaging & Narrative', 'The story arc, proof points and the three things a seller must land', 2),
       ('Buyer Personas', 'Who buys, who blocks, what each cares about and how they are measured', 3),
       ('Value Proposition', 'The quantified outcome, the value case model and the reference wins', 4),
       ('Objection Handling', 'The eight objections that recur, and the answer to each', 5);

INSERT INTO mmf_portal.uploaded_target_accounts
(name, business_unit_code, country_name, sector, campaign_name, owner_name, salesforce_account_id, match_confidence)
VALUES ('Yorkshire Precision Ltd', 'UK', NULL, 'Manufacturing', 'UK Manufacturing — ADM Reboot', 'L. Murray', NULL,
        'Medium'),
       ('Tyne Components plc', 'UK', NULL, 'Manufacturing', 'UK Manufacturing — ADM Reboot', 'L. Murray', NULL, 'Low'),
       ('Sachsen Logistik', 'DE', NULL, 'Transport', 'DE Industrial — Cost Takeout Q3', 'T. Schmidt', NULL, 'Medium'),
       ('Munich Retail Group', 'DE', NULL, 'Retail', 'DE Retail — Commerce Push', 'T. Schmidt', '0011t00000XyZ12',
        'High'),
       ('Van Oord Logistics', 'NL', NULL, 'Transport', 'NL Industrial — IT Cost Takeout', 'J. Bakker', NULL, 'High'),
       ('Vasa Retail AB', 'NO', 'Sweden', 'Retail', 'SE Industrial — Smart Factory', 'A. Lindqvist', NULL, 'Medium');

INSERT INTO mmf_portal.campaign_history (campaign_name, changed_at, changed_by, change_description)
VALUES ('DE Industrial — Cost Takeout Q3', '2026-08-28 09:00:00+02', 'T. Schmidt',
        'Added 4 accounts from BATCH-0004 upload'),
       ('DE Industrial — Cost Takeout Q3', '2026-08-14 09:00:00+02', 'DE MM Leader',
        'Status Planned → Approved → Active'),
       ('UK Manufacturing — ADM Reboot', '2026-08-26 09:00:00+02', 'R. Patel', 'End date extended to 12 Sep 2026'),
       ('UK Manufacturing — ADM Reboot', '2026-08-12 09:00:00+02', 'R. Patel',
        'Objective updated after the joint plan review'),
       ('NL Retail — Commerce Acceleration', '2026-08-22 09:00:00+02', 'J. Bakker',
        'Linked Radar engine Netherlands · Retail & CPG');

INSERT INTO mmf_portal.radar_signals
(business_unit_code, country_name, account_name, radar_engine_name, title, source, score, severity, status, summary)
VALUES ('UK', NULL, 'Thames Utilities', 'UK · Energy & Utilities', 'Ofwat AMP8 investment plan approved', 'Regulator',
        92, 'High', 'New',
        'Approved capital plan releases multi-year technology spend. Grid analytics and asset data are named workstreams - direct fit for the E&U Grid Data Platform.'),
       ('UK', NULL, 'Pennine Manufacturing', 'UK · Manufacturing & CPG', 'Private-equity acquisition completed', 'News',
        85, 'High', 'New',
        'A new PE owner typically drives a 100-day cost agenda. Classic entry point for IT Cost Takeout and vendor consolidation.'),
       ('UK', NULL, 'Albion Foods', 'UK · Manufacturing & CPG', 'Named in SAP mid-market reference programme',
        'Partner feed', 77, 'Medium', 'Reviewed',
        'SAP is actively working the account - coordinate joint outreach around the S/4 Rapid Migration solution.'),
       ('DE', NULL, 'Rheinwerk AG', 'Germany · Industrial', 'Announces €400M plant modernization programme',
        'Press release', 96, 'High', 'New',
        'Three plants over 24 months, with legacy ERP named as a constraint. Strong fit for SAP S/4 Rapid Migration plus IT Cost Takeout.'),
       ('DE', NULL, 'NordChem', 'Germany · Industrial', 'CFO signals cost-reduction drive in H2 earnings call',
        'Earnings call', 88, 'High', 'New',
        'Management committed to an 8% opex reduction with IT named as a lever. Direct trigger for IT Cost Takeout outreach.'),
       ('DE', NULL, 'BavariaTech GmbH', 'Germany · TMT & E&U', 'Hiring 40+ cloud & data engineers', 'Job boards', 81,
        'Medium', 'New',
        'A large AWS and data-platform hiring spike suggests a migration already in motion - landing-zone and managed-service opportunity.'),
       ('DE', NULL, 'Munich Retail Group', 'Germany · Industrial', 'New digital commerce tender published',
        'Tender database', 83, 'High', 'Reviewed',
        'Public tender for commerce replatforming with a six-week deadline - the pre-tender positioning window is open now.'),
       ('NL', NULL, 'Rotterdam FoodCo', 'Netherlands · Industrial',
        'Publishes tender for application support consolidation', 'Tender database', 94, 'High', 'New',
        'Open tender to consolidate five application support vendors into one, closing in five weeks. Direct match for the Vendor Consolidation Play.'),
       ('NL', NULL, 'Amstel Retail Group', 'Netherlands · Retail & CPG',
        'CFO commits to 7% opex reduction in trading update', 'Earnings call', 88, 'High', 'New',
        'Management named IT and logistics as the two levers. Strong opening for IT Cost Takeout ahead of the FY planning cycle.'),
       ('NL', NULL, 'Eindhoven Devices BV', 'Netherlands · Industrial', 'Hiring 25+ SAP and integration engineers',
        'Job boards', 79, 'Medium', 'New',
        'Concentrated SAP hiring suggests an S/4 programme being staffed internally - a positioning window for a managed alternative.'),
       ('NL', NULL, 'Van Oord Logistics', 'Netherlands · Industrial', 'New Chief Digital Officer appointed',
        'Leadership changes', 70, 'Medium', 'New',
        'Leadership change often precedes transformation spend. Warm-intro opportunity for the account team.'),
       ('NO', 'Sweden', 'Nordic Steel AB', 'Nordics · Industrial', 'RFI issued for OT/IT integration partner',
        'Tender database', 89, 'High', 'New',
        'The RFI closes in three weeks. Direct fit for the Manufacturing Smart Factory solution.'),
       ('NO', 'Finland', 'Suomi Paper Oyj', 'Nordics · Industrial', 'Announces group-wide efficiency programme',
        'Press release', 90, 'High', 'New',
        'A €60M efficiency target over two years with shared services in scope - aligns to the ADM consolidation campaign already running.'),
       ('NO', 'Norway', 'Fjord Energy ASA', 'Nordics · Energy', 'Signs strategic cloud agreement with AWS',
        'Partner feed', 86, 'High', 'New',
        'Commitment made, capability not yet built. A strong opening for the Hyperscaler Landing Zone solution.'),
       ('NO', 'Denmark', 'Copenhagen Logistics', 'Nordics · Industrial', 'Recruiting Head of Enterprise Architecture',
        'Job boards', 72, 'Medium', 'New',
        'A senior EA hire usually precedes a modernization mandate. Time outreach for 60-90 days after the appointment.');

INSERT INTO mmf_portal.data_source_connectors
(name, connector_type, credential_reference, license_terms, is_active, used_by)
VALUES ('Open web search', 'public_web', NULL, 'Public sources', true, ARRAY['Radar', 'Agents']),
       ('Company news & press releases', 'public_web', NULL, 'Public sources', true, ARRAY['Radar']),
       ('Regulatory filings', 'public_web', NULL, 'Public sources', true, ARRAY['Radar']),
       ('Tender database (EU/TED)', 'subscription', 'kv://mmf/ted-api-key', 'Seat-limited; no redistribution', true,
        ARRAY['Radar']),
       ('Job boards / hiring feed', 'subscription', 'kv://mmf/hiring-feed', 'Pending procurement review', false,
        ARRAY['Radar']),
       ('Leadership change monitor', 'public_web', NULL, 'Public sources', true, ARRAY['Radar']),
       ('Salesforce (CRM)', 'crm', 'kv://mmf/sfdc-jwt', 'Internal', true, ARRAY['Data model', 'Agents']),
       ('Solutions & Assets index', 'in_house', 'kv://mmf/sharepoint-app', 'Internal', true, ARRAY['Agents (RAG)']);

INSERT INTO mmf_portal.smart_agents (name, lifecycle_stage, agent_type, status, version, description, grounding_sources)
VALUES ('Client Intelligence', 'Prospecting', 'Internal', 'Published', 'v2.1',
        'Account briefing built from Salesforce, Radar signals and the open web.', ARRAY['Salesforce', 'Radar signals',
        'Public web']),
       ('Meeting Preparation', 'Engagement', 'Internal', 'Published', 'v1.4',
        'Pre-meeting brief: context, attendees, talking points and likely objections.', ARRAY['Salesforce',
        'Solutions & Assets (RAG)', 'Radar signals']),
       ('RFP / Bid Summary', 'Bidding', 'External', 'Published', 'v3.0',
        'Summarizes an RFP into requirements, a fit assessment, risks and a response outline.', ARRAY['Uploaded RFP',
        'Solutions & Assets (RAG)']),
       ('Solutioning', 'Shaping', 'Internal', 'Published', 'v2.0',
        'Proposes a solution shape from Factory offers and certified assets.', ARRAY['Solutions & Assets (RAG)']),
       ('Pre-Tender', 'Prospecting', 'External', 'In-Test', 'v0.9',
        'Positions ahead of an upcoming tender using public procurement signals.', ARRAY['Public web (tenders)',
        'Radar signals']),
       ('Case Study', 'Shaping / Bidding', 'Internal', 'Published', 'v1.2',
        'Surfaces the most relevant proof points and drafts a tailored reference story.',
        ARRAY['Solutions & Assets (RAG)']);

INSERT INTO mmf_portal.agent_usage_metrics
(agent_name, measured_at, invocation_count, distinct_user_count, average_rating, output_count,
 invocations_by_business_unit, invocations_by_country, invocations_by_role, trend, feedback)
VALUES ('Meeting Preparation', '2026-09-02 08:12:00+02', 412, 38, 4.5, 398, '{
  "UK": 96,
  "DE": 141,
  "NL": 104,
  "NO": 71
}', '{
  "Sweden": 28,
  "Finland": 19,
  "Norway": 14,
  "Denmark": 10
}', '{
  "Seller / Client Partner": 301,
  "Campaign Lead": 58,
  "Solution Architect / SME": 33,
  "BU MM (Business) Leader": 20
}', '+18%', 'Fastest way to walk in prepared. Attendee section is the best part.'),
       ('Client Intelligence', '2026-09-02 07:44:00+02', 356, 41, 4.3, 341, '{
         "UK": 84,
         "DE": 126,
         "NL": 87,
         "NO": 59
       }', '{
         "Sweden": 23,
         "Finland": 16,
         "Norway": 12,
         "Denmark": 8
       }', '{
         "Seller / Client Partner": 254,
         "Campaign Lead": 47,
         "Solution Architect / SME": 31,
         "BU MM (Business) Leader": 24
       }', '+24%', 'Good on public signals; thin where the account is new to us.'),
       ('Solutioning', '2026-09-01 16:05:00+02', 198, 22, 4.1, 186, '{
         "UK": 44,
         "DE": 69,
         "NL": 51,
         "NO": 34
       }', '{
         "Sweden": 13,
         "Finland": 9,
         "Norway": 7,
         "Denmark": 5
       }', '{
         "Solution Architect / SME": 112,
         "Seller / Client Partner": 61,
         "Campaign Lead": 25
       }', '+9%', 'Useful starting shape. Still needs an architect to finish it.'),
       ('RFP / Bid Summary', '2026-09-01 11:31:00+02', 164, 19, 4.4, 161, '{
         "UK": 47,
         "DE": 52,
         "NL": 38,
         "NO": 27
       }', '{
         "Sweden": 11,
         "Finland": 7,
         "Norway": 5,
         "Denmark": 4
       }', '{
         "Solution Architect / SME": 78,
         "Seller / Client Partner": 66,
         "Campaign Lead": 20
       }', '+31%', 'Saves a day on bid day one. Requirements extraction is reliable.'),
       ('Case Study', '2026-08-29 14:52:00+02', 121, 26, 3.9, 118, '{
         "UK": 31,
         "DE": 38,
         "NL": 32,
         "NO": 20
       }', '{
         "Sweden": 8,
         "Finland": 5,
         "Norway": 4,
         "Denmark": 3
       }', '{
         "Seller / Client Partner": 74,
         "Solution Architect / SME": 31,
         "Campaign Lead": 16
       }', '+6%', 'Finds the right references; the drafted story needs a rewrite.'),
       ('Pre-Tender', '2026-08-27 09:18:00+02', 47, 9, 3.6, 44, '{
         "UK": 16,
         "DE": 14,
         "NL": 11,
         "NO": 6
       }', '{
         "Sweden": 2,
         "Finland": 2,
         "Norway": 1,
         "Denmark": 1
       }', '{
         "Seller / Client Partner": 29,
         "Campaign Lead": 12,
         "Factory Agentic Lead": 6
       }', 'new', 'Promising, but tender coverage is patchy outside the UK.');

INSERT INTO mmf_portal.governance_councils
(name, cadence, scope, next_meeting_date, chair_role, decision_count, action_count)
VALUES ('Quarterly SBU Steering', 'Quarterly', 'SBU', '2026-10-02', 'SBU Factory Leader', 4, 6),
       ('Monthly BU GTM Squad', 'Monthly', 'BU', '2026-09-05', 'BU MM Leader', 3, 8),
       ('Weekly Deal & Solutions Review', 'Weekly', 'BU', '2026-09-05', 'BU Factory Leader', 2, 5);

INSERT INTO mmf_portal.governance_meetings
(council_name, meeting_date, attendees, notes, decision_count, action_count)
VALUES ('Monthly BU GTM Squad', '2026-08-05', 'BU MM Leader, BU Factory Leader, Campaign Lead, 3 sellers',
        'Reviewed Q3 campaign pipeline. Cost Takeout ahead of plan; Commerce Push behind on meetings. Agreed to move two sellers onto the tender response.',
        2, 3),
       ('Weekly Deal & Solutions Review', '2026-08-29', 'Solution Architect, 4 sellers, BU Factory Leader',
        'Rheinwerk workshop pack reviewed and approved. Rotterdam tender: bid/no-bid taken as bid, subject to partner confirmation.',
        1, 2),
       ('Quarterly SBU Steering', '2026-07-03', 'SBU Factory Leader, 4 BU MM Leaders',
        'Q3 objectives set per BU. Agreed the daily Salesforce sync cadence for MVP and deferred the Cyber Baseline solution to Q4.',
        3, 4);

INSERT INTO mmf_portal.governance_decisions (decision, owner_name, decision_date, status, reference_type)
VALUES ('Approve SAP S/4 Wave 1 campaign for UK CPG', 'UK MM Leader', '2026-08-28', 'Ratified', 'Campaign'),
       ('Certify Retail Commerce Accelerator at In-Development', 'Factory S&A Lead', '2026-08-21', 'Ratified',
        'Solution'),
       ('Bid on the Rotterdam FoodCo consolidation tender', 'BU Factory Leader', '2026-08-29', 'Ratified', 'Prospect'),
       ('Defer Cyber Baseline solution to Q4', 'SBU Factory Leader', '2026-07-03', 'Open', 'Solution'),
       ('Adopt daily Salesforce sync cadence for MVP', 'SBU Factory Leader', '2026-07-03', 'Ratified', NULL);

INSERT INTO mmf_portal.governance_actions (action, owner_name, due_date, status)
VALUES ('Finalize Q4 target accounts for the Industrial engine', 'BU MM Leader', '2026-09-12', 'Open'),
       ('Certify Retail Commerce Accelerator assets', 'Factory S&A Lead', '2026-09-19', 'Open'),
       ('Register the tender-database subscription source', 'Factory Agentic Lead', '2026-09-26', 'Open'),
       ('Confirm sector/segment taxonomy as reference data', 'Admin', '2026-09-30', 'Open'),
       ('Assemble the Rotterdam tender bid team', 'BU Factory Leader', '2026-09-04', 'Open'),
       ('Configure E&U engine subscription source', 'Factory Agentic Lead', '2026-08-22', 'Closed');

INSERT INTO mmf_portal.raci_assignments (activity, responsible, accountable, consulted, informed)
VALUES ('Set BU quarterly objectives & targets', 'BU MM Leader', 'SBU Factory Leader', 'BU Factory Leader', 'Sellers'),
       ('Create & upload target prospects', 'Seller', 'BU MM Leader', 'Campaign Lead', 'BU Factory Leader'),
       ('Qualify & convert a prospect', 'Seller', 'BU MM Leader', 'Solution Architect', 'Campaign Lead'),
       ('Build & industrialize solutions/assets', 'Solution Architect', 'Factory S&A Lead', 'BU Factory Leader',
        'BU MM Leader'),
       ('Certify & publish solution/asset', 'Factory S&A Lead', 'Factory S&A Lead', 'Solution Architect', 'BUs'),
       ('Configure radar engines & rules', 'Factory Agentic Lead', 'BU Factory Leader', 'Sellers', 'BU MM Leader'),
       ('Plan & approve a campaign', 'Campaign Lead', 'BU MM Leader', 'Solution Architect', 'Sellers'),
       ('Execute campaign / work accounts', 'Seller', 'Campaign Lead', 'Factory Agentic Lead', 'BU MM Leader'),
       ('Author/register & govern agents', 'Factory Agentic Lead', 'Factory Agentic Lead', 'Admin', 'Sellers'),
       ('Manage users, roles & connectors', 'Admin', 'Admin', '—', 'All');

INSERT INTO mmf_portal.mvp_outcomes (outcome, status)
VALUES ('MVP clearly supports the overall mid-market growth objectives, and the MVP scope is signed off by leadership',
        'Open'),
       ('Data quality, compliance and launch readiness confirmed', 'Open'),
       ('No critical issues or gaps at go-live', 'Open');

INSERT INTO mmf_portal.reference_data (category, values_text, governance_status)
VALUES ('Business Line', 'CCA · PBS · ADM · CIS · Invent · DCX · I&D · Sogeti', 'Locked'),
       ('Industry / sector',
        'Manufacturing · Retail · CPG · Automotive · TMT · E&U · Transport · Financial Services · Life Sciences',
        'Open - action A4'),
       ('Segment', 'Mid-market revenue bands within €500M–€3B', 'Open - action A4'),
       ('Prospect lifecycle stage',
        'Target Identified · Research · Outreach · Meetings Scheduled / Delivered · Qualified Lead · Converted to Opportunity',
        'Locked'),
       ('Prospect source', 'Single form · Excel upload · Radar signal · Campaign', 'Locked'),
       ('Campaign status', 'Draft · Planned · Approved · Active · Paused · Closed · Review', 'Locked'),
       ('Solution class', 'Industry · Business Line · Cross-Business Line', 'Locked'),
       ('Certification status', 'Draft · Submitted · Certified & Published', 'Locked'),
       ('Signal status', 'New · Reviewed · Dismissed', 'Locked');

INSERT INTO mmf_portal.kpi_definitions (name, unit, definition, dimensions)
VALUES ('Qualified pipeline', '€', 'Sum of open MM-Factory-classified opportunities in scope', ARRAY['BU', 'Country',
        'Campaign']),
       ('Revenue booked', '€', 'Sum of closed-won MM-Factory-classified opportunities in scope', ARRAY['BU', 'Country',
        'Campaign']),
       ('Coverage', '%', 'Target accounts with an interaction or open opportunity divided by target accounts',
        ARRAY['BU', 'Country']),
       ('% Industrialized', '%', 'Reuse events on certified assets divided by total asset usage', ARRAY['BU', 'SBU']),
       ('Outreach activities completed', '#', 'ProspectInteraction records of type outreach or call in the period',
        ARRAY['BU', 'Country', 'Campaign', 'Seller']),
       ('Meetings secured', '#', 'ProspectInteraction records of type meeting scheduled or delivered', ARRAY['BU',
        'Country', 'Campaign', 'Seller']),
       ('Opportunities created', '#', 'ProspectOpportunityLink records created in the period', ARRAY['BU', 'Country',
        'Campaign']),
       ('Campaign stage conversion', '%', 'CampaignAccount progression between adjacent stages', ARRAY['Campaign']),
       ('Signal → opportunity conversion', '%',
        'Signals whose account opened an opportunity within the attribution window', ARRAY['BU', 'Engine']),
       ('Agent adoption', '#', 'Distinct users invoking an agent in the period', ARRAY['BU', 'Country', 'Agent']);

INSERT INTO mmf_portal.kpi_snapshots
(as_of, business_unit_code, country_name, pipeline_millions, revenue_millions, coverage_percent, reuse_percent,
 signal_count, signal_conversion_percent, outreach_count, meeting_count, opportunities_created,
 stage_conversion_percent, pipeline_target_millions, revenue_target_millions, coverage_target_percent)
VALUES ('2026-09-02 02:00:00+02', 'UK', NULL, 19.2, 6.1, 55, 64, 29, 15, 186, 41, 9, 22, 26, 9, 65),
       ('2026-09-02 02:00:00+02', 'DE', NULL, 24.6, 8.4, 62, 71, 38, 18, 242, 57, 13, 26, 30, 11, 70),
       ('2026-09-02 02:00:00+02', 'NL', NULL, 12.8, 4.7, 58, 69, 22, 16, 154, 34, 8, 24, 16, 6, 66),
       ('2026-09-02 02:00:00+02', 'NO', NULL, 14.1, 5.2, 49, 60, 26, 14, 131, 29, 7, 20, 20, 7, 62),
       ('2026-09-02 02:00:00+02', 'NO', 'Sweden', 5.4, 2.0, 53, 62, 9, 15, 44, 10, 3, 22, 7, 2.6, 64),
       ('2026-09-02 02:00:00+02', 'NO', 'Finland', 3.9, 1.4, 51, 59, 7, 14, 36, 8, 2, 21, 5.5, 1.9, 62),
       ('2026-09-02 02:00:00+02', 'NO', 'Norway', 2.7, 1.1, 45, 58, 6, 13, 29, 7, 1, 18, 4, 1.4, 60),
       ('2026-09-02 02:00:00+02', 'NO', 'Denmark', 2.1, 0.7, 44, 57, 4, 12, 22, 4, 1, 17, 3.5, 1.1, 60);

INSERT INTO mmf_portal.audit_events (occurred_at, actor_name, action, event_details)
VALUES ('2026-09-02 09:14:00+02', 'R. Patel', 'Upload validated', 'BATCH-0007 · 38 accepted, 6 rejected'),
       ('2026-09-01 16:42:00+02', 'K. Weber', 'Prospect converted', 'PRS-DE-00042 → 0061t00000AbdK2'),
       ('2026-09-01 11:07:00+02', 'System', 'Salesforce sync', 'Accounts 412 upserted · Opportunities 268 upserted'),
       ('2026-08-31 17:55:00+02', 'T. Schmidt', 'Campaign edited',
        'DE Industrial — Cost Takeout Q3 · 4 accounts added'),
       ('2026-08-29 14:20:00+02', 'Factory S&A Lead', 'Asset published', 'S/4 migration blueprint v5'),
       ('2026-08-28 08:31:00+02', 'Admin', 'Connector deactivated',
        'Job boards / hiring feed - pending procurement review');

-- Consolidated from V3__align_latest_prototype_mock_data.sql

-- Align the persisted mock model with MMF Portal Prototype v3.1, 15 Sep 2026.
ALTER TABLE mmf_portal.campaigns
    ADD COLUMN business_line text,
    ADD COLUMN theme text,
    ADD COLUMN partner_name text,
    ADD COLUMN campaign_description text,
    ADD COLUMN meetings_booked integer NOT NULL DEFAULT 0 CHECK (meetings_booked >= 0),
    ADD COLUMN qualified_leads integer NOT NULL DEFAULT 0 CHECK (qualified_leads >= 0),
    ADD COLUMN cxo_reach integer NOT NULL DEFAULT 0 CHECK (cxo_reach >= 0),
    ADD COLUMN inbound_count integer NOT NULL DEFAULT 0 CHECK (inbound_count >= 0),
    ADD COLUMN audience_reach integer NOT NULL DEFAULT 0 CHECK (audience_reach >= 0),
    ADD COLUMN bookings_millions numeric(12,2) NOT NULL DEFAULT 0 CHECK (bookings_millions >= 0),
    ADD COLUMN revenue_won_millions numeric(12,2) NOT NULL DEFAULT 0 CHECK (revenue_won_millions >= 0);

ALTER TABLE mmf_portal.radar_signals DROP CONSTRAINT radar_signals_severity_check;
ALTER TABLE mmf_portal.radar_signals
    ADD CONSTRAINT radar_signals_severity_check CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    ADD COLUMN signal_category text,
    ADD COLUMN published_at date,
    ADD COLUMN opportunity_hypothesis text,
    ADD COLUMN recommended_agents text[] NOT NULL DEFAULT '{}',
    ADD COLUMN recommended_action text,
    ADD COLUMN scoring_inputs jsonb NOT NULL DEFAULT '{}';

ALTER TABLE mmf_portal.smart_agents
    ADD COLUMN owner_team text,
    ADD COLUMN best_used_for text,
    ADD COLUMN launches_this_quarter integer NOT NULL DEFAULT 0 CHECK (launches_this_quarter >= 0);

ALTER TABLE mmf_portal.kpi_snapshots
    ADD COLUMN client_count integer,
    ADD COLUMN target_account_count integer,
    ADD COLUMN active_account_count integer,
    ADD COLUMN active_campaign_count integer,
    ADD COLUMN active_partner_play_count integer,
    ADD COLUMN key_asset_count integer,
    ADD COLUMN smart_agent_count integer,
    ADD COLUMN qualified_lead_count integer,
    ADD COLUMN bookings_target_millions numeric(12,2);

CREATE TABLE mmf_portal.partner_plays
(
    name                         text PRIMARY KEY,
    partner_name                 text           NOT NULL,
    partner_tier                 text           NOT NULL,
    business_line                text           NOT NULL,
    theme                        text           NOT NULL,
    eligible_country_codes       text[] NOT NULL,
    status                       text           NOT NULL CHECK (status IN ('Draft', 'Active', 'Paused', 'Closed')),
    value_proposition            text           NOT NULL,
    influenced_pipeline_millions numeric(12, 2) NOT NULL DEFAULT 0 CHECK (influenced_pipeline_millions >= 0),
    linked_campaign_count        integer        NOT NULL DEFAULT 0 CHECK (linked_campaign_count >= 0),
    owner_name                   text           NOT NULL
);

INSERT INTO mmf_portal.partner_plays
VALUES ('SAP RISE for Mid-Market', 'SAP', 'Platinum', 'ADM', 'SAP / Cloud', ARRAY['NL', 'DE', 'UK', 'SE', 'FI'],
        'Active', 'Fixed-scope RISE migration with Capgemini mid-market accelerators and SAP funding support.', 9.4, 3,
        'S. de Vries'),
       ('AWS Landing Zone Fast Start', 'AWS', 'Premier', 'CIS', 'SAP / Cloud', ARRAY['DE', 'UK', 'NO', 'DK'], 'Active',
        'Six-week landing zone with AWS MAP funding; ideal entry play for new logos.', 6.7, 3, 'K. Weber'),
       ('Microsoft Data & AI Jumpstart', 'Microsoft', 'Premier', 'I&D', 'Data & AI', ARRAY['NL', 'DE', 'UK', 'SE', 'FI',
        'NO', 'DK'], 'Active',
        'Fabric-based data platform starter with joint Microsoft investment and a four-week proof of value.', 8.1, 4,
        'L. Murray'),
       ('Adobe Commerce for Mid-Market Retail', 'Adobe', 'Gold', 'DCX', 'Sector play', ARRAY['NL', 'DE', 'SE'],
        'Active', 'Pre-configured commerce stack for retailers under EUR 3B revenue, with Adobe co-marketing.', 4.2, 3,
        'J. Bakker'),
       ('Siemens Smart Factory Accelerator', 'Siemens', 'Gold', 'CIS', 'Sector play', ARRAY['DE', 'SE'], 'Active',
        'OT/IT convergence play for discrete manufacturers, co-delivered with Siemens.', 5.3, 2, 'A. Lindqvist'),
       ('ServiceNow ITSM Consolidation', 'ServiceNow', 'Gold', 'ADM', 'Vendor Consolidation', ARRAY['NL', 'UK'],
        'Active', 'Consolidate fragmented tooling onto a single ITSM platform with a strong cost-takeout narrative.',
        3.1, 2, 'M. Jansen'),
       ('Google Cloud Modernization Sprint', 'Google Cloud', 'Silver', 'CIS', 'Enterprise Technology Modernization',
        ARRAY['UK', 'DK'], 'Draft',
        'Application modernization sprint with Google funding, pending the mid-market pricing model.', 0, 0,
        'R. Patel');

UPDATE mmf_portal.campaigns
SET business_line        = CASE name
                               WHEN 'NL Industrial — IT Cost Takeout' THEN 'ADM'
                               WHEN 'NL Retail — Commerce Acceleration' THEN 'DCX'
                               WHEN 'DE Manufacturing — Smart Factory' THEN 'CIS'
                               WHEN 'DE Industrial — Cost Takeout Q3' THEN 'ADM'
                               WHEN 'UK Manufacturing — ADM Reboot' THEN 'ADM'
                               WHEN 'UK E&U — Grid Analytics' THEN 'I&D'
                               WHEN 'SE Industrial — Smart Factory' THEN 'CIS'
                               WHEN 'FI Manufacturing — ADM Consolidation' THEN 'ADM'
                               WHEN 'NO Energy — Cloud Foundation' THEN 'CIS'
                               ELSE business_line END,
    meetings_booked      = CASE name
                               WHEN 'NL Industrial — IT Cost Takeout' THEN 11
                               WHEN 'NL Retail — Commerce Acceleration' THEN 6
                               WHEN 'DE Manufacturing — Smart Factory' THEN 9
                               WHEN 'DE Industrial — Cost Takeout Q3' THEN 14
                               WHEN 'UK Manufacturing — ADM Reboot' THEN 9
                               WHEN 'UK E&U — Grid Analytics' THEN 5
                               WHEN 'SE Industrial — Smart Factory' THEN 7
                               WHEN 'FI Manufacturing — ADM Consolidation' THEN 6
                               WHEN 'NO Energy — Cloud Foundation' THEN 4
                               ELSE meetings_booked END,
    qualified_leads      = opportunities_generated,
    bookings_millions    = round(pipeline_millions * 0.55, 1),
    revenue_won_millions = round(pipeline_millions * 0.24, 1);

-- The latest prototype has 29 unique agents. Duplicate lifecycle placements are UI metadata;
-- this table stores one catalogue record per agent and its displayed launch count.
TRUNCATE mmf_portal.smart_agents CASCADE;
INSERT INTO mmf_portal.smart_agents (name, lifecycle_stage, agent_type, status, version, description, grounding_sources,
                                     owner_team, best_used_for, launches_this_quarter)
VALUES ('Intelio', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Creates a 360-degree client intelligence view including business context, sector trends, financials, technology priorities and opportunity hypotheses.',
        ARRAY['Radar signals', 'Public web'], 'Clients & Innovation',
        'Account planning, first outreach, meeting preparation and opportunity shaping.', 64),
       ('BritMap', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Builds UK-focused BuyerMaps, decision-maker context and likely opportunity areas.', ARRAY['Radar signals',
        'Public web'], 'Clients & Innovation', 'UK mid-market account intelligence and targeted sales engagement.', 22),
       ('Helder', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Creates concise BuyerMaps for Netherlands mid-market clients.', ARRAY['Radar signals', 'Public web'],
        'Clients & Innovation', 'Netherlands teams preparing account meetings.', 18),
       ('Rapport', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Builds stakeholder intelligence profiles and engagement approaches.', ARRAY['Radar signals', 'Public web'],
        'Clients & Innovation', 'Preparing for senior stakeholder conversations.', 37),
       ('Stakeholder Profile', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Structures stakeholder profiles from public and contextual inputs.', ARRAY['Public web'],
        'Clients & Innovation', 'Account or bid stakeholder mapping.', 15),
       ('LinkedIn CXO Voice', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Decodes leadership activity and public CXO voice.', ARRAY['Public web'], 'Clients & Innovation',
        'When leadership signals or executive changes are identified.', 26),
       ('Market Intel in a Box', 'Client intelligence', 'Internal', 'Published', 'v1.0',
        'Generates executive-ready market intelligence and client briefings.', ARRAY['Public web'],
        'Clients & Innovation', 'Leadership-ready account and market briefings.', 29),
       ('Knowledge SPOC', 'Meeting preparation', 'Internal', 'Published', 'v1.0',
        'Finds relevant capability decks, case studies, sales kits and guidance.', ARRAY['Solutions & Assets (RAG)'],
        'Knowledge Management', 'Preparing meeting materials or proof points.', 51),
       ('Beacon', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Identifies and scores buying signals using public data and a structured taxonomy.', ARRAY['Radar signals'],
        'Clients & Innovation', 'Validating whether a trigger is commercially meaningful.', 33),
       ('Triggers Orchestrator', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Processes trigger lists and applies regional governance rules.', ARRAY['Radar signals'],
        'Clients & Innovation', 'Standardising batches of trigger signals.', 12),
       ('Financial Analyst', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Analyses financial stress and maps it to IT services opportunities.', ARRAY['Public web', 'Radar signals'],
        'Clients & Innovation', 'Financial updates, margin pressure or restructuring signals.', 44),
       ('Spend Scout', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Identifies likely investment areas from financials and company actions.', ARRAY['Public web', 'Radar signals'],
        'Clients & Innovation', 'Separating commercial opportunity from market noise.', 20),
       ('Sales TransFORM', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Explains sales pipeline, bookings, forecasting and governance rules.', ARRAY['Salesforce'],
        'Sales Analytics Centre', 'Qualifying or progressing pipeline stages.', 17),
       ('Deal Risk Sentinel', 'Opportunity qualification', 'Internal', 'Published', 'v1.0',
        'Surfaces commercial, delivery, compliance and governance risks across deals.', ARRAY['Salesforce'],
        'Wincentre', 'Qualification, go/no-go and deal review.', 25),
       ('Nexus', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Turns relevant innovation into client-ready value stories.', ARRAY['Solutions & Assets (RAG)',
        'Radar signals'], 'Clients & Innovation', 'Shaping innovation-led proposals and solution angles.', 39),
       ('Researcher', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Conducts deep research on competitors, markets, clients and partnerships.', ARRAY['Public web',
        'Radar signals'], 'Clients & Innovation', 'Market and competitor research during shaping.', 47),
       ('Horizon', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Anticipates public-sector tender opportunities before formal publication.', ARRAY['Public web'],
        'Clients & Innovation', 'Pre-tender positioning.', 14),
       ('CompeteIQ', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Builds competitor overviews and compete strategy.', ARRAY['Public web'], 'Clients & Innovation',
        'Strengthening differentiation and win themes.', 21),
       ('GCC Advisor', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Provides GCC market intelligence, talent and operating model insights.', ARRAY['Public web'],
        'Clients & Innovation', 'GCC-related advisory opportunities.', 8),
       ('Beat The Competition', 'Origination & shaping', 'Internal', 'Published', 'v1.0',
        'Creates competitive intelligence newsletters and market briefs.', ARRAY['Public web'], 'Clients & Innovation',
        'Competitive monitoring and strategy.', 16),
       ('RFx Shredder', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Extracts RFP and RFI requirements, risks, gaps and evaluation criteria.', ARRAY['Uploaded RFP'], 'Wincentre',
        'Day one of a bid or tender review.', 46),
       ('Bid Support Copilot', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Guides bid lifecycle activities, checklists, prompts and compliance.', ARRAY['Uploaded RFP'], 'Wincentre',
        'Bid and presales teams during an RFx response.', 34),
       ('Winplan Navigator', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Builds win strategy, value proposition and competitive positioning.', ARRAY['Salesforce'], 'Wincentre',
        'Pursuit strategy and win planning.', 28),
       ('RedTeam Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Critically reviews tender and bid content.', ARRAY['Uploaded RFP'], 'Wincentre',
        'Before formal proposal review.', 19),
       ('Cognitive Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Reviews proposals for clarity, logic, trust and decision effectiveness.', ARRAY['Uploaded RFP'], 'Wincentre',
        'Sharpening executive-ready proposal content.', 13),
       ('Proposal Matcher', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Compares RFx requirements with proposal content.', ARRAY['Uploaded RFP'], 'Proposal Centre',
        'Validating proposal fit against customer requirements.', 23),
       ('Final Checker', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Checks RFP responses for consistency, grammar, formatting and compliance.', ARRAY['Uploaded RFP'],
        'Proposal Centre', 'Before submission.', 30),
       ('Proposal Development', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Creates structured proposal documents from RFP content.', ARRAY['Uploaded RFP'], 'Proposal Centre',
        'Accelerating drafting.', 26),
       ('FAQ / Response Draft - UK', 'RFP / bid support', 'Internal', 'Published', 'v1.0',
        'Finds standard responses and bid essentials from UK knowledge sources.', ARRAY['Solutions & Assets (RAG)'],
        'Wincentre', 'Questionnaires, FAQs and standard response drafting.', 11);

DELETE
FROM mmf_portal.kpi_snapshots;
INSERT INTO mmf_portal.kpi_snapshots (as_of, business_unit_code, country_name, pipeline_millions, revenue_millions,
                                      coverage_percent, reuse_percent, signal_count, signal_conversion_percent,
                                      outreach_count, meeting_count, opportunities_created, stage_conversion_percent,
                                      pipeline_target_millions, revenue_target_millions, coverage_target_percent,
                                      client_count, target_account_count, active_account_count, active_campaign_count,
                                      active_partner_play_count, key_asset_count, smart_agent_count,
                                      qualified_lead_count, bookings_target_millions)
VALUES ('2026-08-11 02:00:00+02', 'NL', NULL, 38.4, 45.0, 62, 71, 92, 7, 31, 12, 12, 31, 50, 60, 70, 150, 50, 31, 4, 12,
        55, 29, 7, 60),
       ('2026-08-11 02:00:00+02', 'DE', NULL, 47.1, 52.6, 64, 68, 118, 11, 41, 18, 18, 36, 60, 70, 70, 210, 64, 41, 5,
        9, 62, 29, 11, 70),
       ('2026-08-11 02:00:00+02', 'UK', NULL, 33.7, 38.2, 53, 64, 87, 8, 29, 14, 14, 34, 45, 55, 65, 180, 55, 29, 4, 8,
        48, 29, 8, 55),
       ('2026-08-11 02:00:00+02', 'NO', 'Sweden', 16.2, 19.4, 53, 60, 51, 5, 17, 8, 6, 31, 22, 26, 62, 95, 32, 17, 3, 6,
        34, 29, 5, 26),
       ('2026-08-11 02:00:00+02', 'NO', 'Finland', 12.8, 14.1, 54, 58, 44, 4, 14, 7, 5, 29, 17, 18, 60, 70, 26, 14, 2,
        5, 28, 29, 4, 18),
       ('2026-08-11 02:00:00+02', 'NO', 'Norway', 9.6, 11.3, 45, 55, 36, 3, 10, 5, 4, 28, 14, 15, 60, 62, 22, 10, 2, 4,
        24, 29, 3, 15),
       ('2026-08-11 02:00:00+02', 'NO', 'Denmark', 8.4, 9.8, 45, 56, 31, 3, 9, 4, 3, 27, 12, 13, 60, 58, 20, 9, 2, 4,
        22, 29, 3, 13);

-- Consolidated from V4__add_domain_api_fields.sql

-- Persist the aggregate state introduced by the v1.1 REST and GraphQL contracts.
ALTER TABLE mmf_portal.assets
    ADD COLUMN source_type text NOT NULL DEFAULT 'Repository link'
        CHECK (source_type IN ('Uploaded file', 'Repository link', 'External link')),
    ADD COLUMN repository_name text,
    ADD COLUMN source_url text,
    ADD COLUMN owner_name text NOT NULL DEFAULT 'Unassigned',
    ADD COLUMN refresh_cycle_months integer NOT NULL DEFAULT 12 CHECK (refresh_cycle_months > 0),
    ADD COLUMN last_reviewed_at date,
    ADD COLUMN next_review_at date,
    ADD COLUMN lifecycle_state text NOT NULL DEFAULT 'Draft'
        CHECK (lifecycle_state IN ('Draft', 'Submitted', 'Certified', 'In refresh', 'Re-certified', 'Retired')),
    ADD COLUMN visibility_scopes text[] NOT NULL DEFAULT '{}';

UPDATE mmf_portal.assets
SET lifecycle_state = CASE certification_status
                          WHEN 'Certified & Published' THEN 'Certified'
                          WHEN 'Submitted' THEN 'Submitted'
                          ELSE 'Draft'
    END;

ALTER TABLE mmf_portal.radar_engines
    ADD COLUMN prospect_set text NOT NULL DEFAULT 'Target prospects'
        CHECK (prospect_set IN
               ('Target prospects', 'Active campaign accounts', 'Qualified leads', 'Full mid-market master',
                'Custom upload')),
    ADD COLUMN source_keys text[] NOT NULL DEFAULT '{}',
    ADD COLUMN frequency text NOT NULL DEFAULT 'Daily',
    ADD COLUMN run_at text NOT NULL DEFAULT '05:00 CET',
    ADD COLUMN lookback_days integer NOT NULL DEFAULT 14 CHECK (lookback_days > 0),
    ADD COLUMN minimum_score smallint NOT NULL DEFAULT 70 CHECK (minimum_score BETWEEN 0 AND 100),
    ADD COLUMN auto_link_campaigns boolean NOT NULL DEFAULT true;

CREATE TABLE mmf_portal.radar_runs
(
    id              uuid PRIMARY KEY,
    engine_name     text        NOT NULL REFERENCES mmf_portal.radar_engines (name) ON DELETE CASCADE,
    status          text        NOT NULL CHECK (status IN ('Accepted', 'Running', 'Completed', 'Failed')),
    requested_at    timestamptz NOT NULL,
    completed_at    timestamptz,
    failure_message text
);

ALTER TABLE mmf_portal.smart_agents
    ADD COLUMN platform text,
    ADD COLUMN launch_url text,
    ADD COLUMN visibility_scopes text[] NOT NULL DEFAULT '{}',
    ADD COLUMN recommended_trigger_categories text[] NOT NULL DEFAULT '{}';

CREATE TABLE mmf_portal.agent_launches
(
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name     text        NOT NULL REFERENCES mmf_portal.smart_agents (name),
    launched_at    timestamptz NOT NULL,
    launched_by    text        NOT NULL,
    account_name   text,
    prospect_id    text REFERENCES mmf_portal.prospects (id),
    opportunity_id text REFERENCES mmf_portal.opportunities (id),
    signal_id      bigint REFERENCES mmf_portal.radar_signals (id),
    campaign_name  text REFERENCES mmf_portal.campaigns (name)
);

CREATE TABLE mmf_portal.campaign_partner_plays
(
    campaign_name     text        NOT NULL REFERENCES mmf_portal.campaigns (name) ON DELETE CASCADE,
    partner_play_name text        NOT NULL REFERENCES mmf_portal.partner_plays (name),
    linked_at         timestamptz NOT NULL DEFAULT now(),
    linked_by         text        NOT NULL DEFAULT 'migration',
    PRIMARY KEY (campaign_name, partner_play_name)
);

INSERT INTO mmf_portal.campaign_partner_plays (campaign_name, partner_play_name)
SELECT c.name, p.name
FROM mmf_portal.campaigns c
         JOIN mmf_portal.partner_plays p ON p.partner_name = c.partner_name
WHERE c.partner_name IS NOT NULL ON CONFLICT DO NOTHING;

-- Consolidated from V5__use_surrogate_primary_keys.sql

-- Replace mutable natural primary keys with stable generated identifiers.

ALTER TABLE mmf_portal.prospects DROP CONSTRAINT prospects_account_name_fkey;
ALTER TABLE mmf_portal.opportunities DROP CONSTRAINT opportunities_account_name_fkey;
ALTER TABLE mmf_portal.radar_signals DROP CONSTRAINT radar_signals_account_name_fkey;
ALTER TABLE mmf_portal.assets DROP CONSTRAINT assets_solution_name_fkey;
ALTER TABLE mmf_portal.play_templates DROP CONSTRAINT play_templates_solution_name_fkey;
ALTER TABLE mmf_portal.campaigns DROP CONSTRAINT campaigns_solution_name_fkey;
ALTER TABLE mmf_portal.opportunities DROP CONSTRAINT opportunities_solution_name_fkey;
ALTER TABLE mmf_portal.campaigns DROP CONSTRAINT campaigns_radar_engine_name_fkey;
ALTER TABLE mmf_portal.radar_signals DROP CONSTRAINT radar_signals_radar_engine_name_fkey;
ALTER TABLE mmf_portal.radar_runs DROP CONSTRAINT radar_runs_engine_name_fkey;
ALTER TABLE mmf_portal.uploaded_target_accounts DROP CONSTRAINT uploaded_target_accounts_campaign_name_fkey;
ALTER TABLE mmf_portal.campaign_history DROP CONSTRAINT campaign_history_campaign_name_fkey;
ALTER TABLE mmf_portal.agent_launches DROP CONSTRAINT agent_launches_campaign_name_fkey;
ALTER TABLE mmf_portal.campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_campaign_name_fkey;
ALTER TABLE mmf_portal.agent_usage_metrics DROP CONSTRAINT agent_usage_metrics_agent_name_fkey;
ALTER TABLE mmf_portal.agent_launches DROP CONSTRAINT agent_launches_agent_name_fkey;
ALTER TABLE mmf_portal.campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_partner_play_name_fkey;
ALTER TABLE mmf_portal.governance_meetings DROP CONSTRAINT governance_meetings_council_name_fkey;

ALTER TABLE mmf_portal.campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_pkey;
ALTER TABLE mmf_portal.uploaded_target_accounts
DROP
CONSTRAINT uploaded_target_accounts_name_campaign_name_key;
ALTER TABLE mmf_portal.radar_signals
DROP
CONSTRAINT radar_signals_account_name_title_key;
ALTER TABLE mmf_portal.agent_usage_metrics
DROP
CONSTRAINT agent_usage_metrics_agent_name_measured_at_key;
ALTER TABLE mmf_portal.governance_meetings
DROP
CONSTRAINT governance_meetings_council_name_meeting_date_key;

ALTER TABLE mmf_portal.accounts
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.solutions
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.radar_engines
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.campaigns
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.smart_agents
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.partner_plays
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.data_source_connectors
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE mmf_portal.governance_councils
    ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;

ALTER TABLE mmf_portal.prospects
    ADD COLUMN account_id bigint;
ALTER TABLE mmf_portal.opportunities
    ADD COLUMN account_id bigint;
ALTER TABLE mmf_portal.radar_signals
    ADD COLUMN account_id bigint;
ALTER TABLE mmf_portal.agent_launches
    ADD COLUMN account_id bigint;
UPDATE mmf_portal.prospects p
SET account_id = a.id FROM mmf_portal.accounts a
WHERE a.name = p.account_name;
UPDATE mmf_portal.opportunities o
SET account_id = a.id FROM mmf_portal.accounts a
WHERE a.name = o.account_name;
UPDATE mmf_portal.radar_signals s
SET account_id = a.id FROM mmf_portal.accounts a
WHERE a.name = s.account_name;
UPDATE mmf_portal.agent_launches l
SET account_id = a.id FROM mmf_portal.accounts a
WHERE a.name = l.account_name;

ALTER TABLE mmf_portal.assets
    ADD COLUMN solution_id bigint;
ALTER TABLE mmf_portal.play_templates
    ADD COLUMN solution_id bigint;
ALTER TABLE mmf_portal.campaigns
    ADD COLUMN solution_id bigint;
ALTER TABLE mmf_portal.opportunities
    ADD COLUMN solution_id bigint;
UPDATE mmf_portal.assets a
SET solution_id = s.id FROM mmf_portal.solutions s
WHERE s.name = a.solution_name;
UPDATE mmf_portal.play_templates p
SET solution_id = s.id FROM mmf_portal.solutions s
WHERE s.name = p.solution_name;
UPDATE mmf_portal.campaigns c
SET solution_id = s.id FROM mmf_portal.solutions s
WHERE s.name = c.solution_name;
UPDATE mmf_portal.opportunities o
SET solution_id = s.id FROM mmf_portal.solutions s
WHERE s.name = o.solution_name;

ALTER TABLE mmf_portal.campaigns
    ADD COLUMN radar_engine_id bigint;
ALTER TABLE mmf_portal.radar_signals
    ADD COLUMN radar_engine_id bigint;
ALTER TABLE mmf_portal.radar_runs
    ADD COLUMN radar_engine_id bigint;
UPDATE mmf_portal.campaigns c
SET radar_engine_id = r.id FROM mmf_portal.radar_engines r
WHERE r.name = c.radar_engine_name;
UPDATE mmf_portal.radar_signals s
SET radar_engine_id = r.id FROM mmf_portal.radar_engines r
WHERE r.name = s.radar_engine_name;
UPDATE mmf_portal.radar_runs rr
SET radar_engine_id = r.id FROM mmf_portal.radar_engines r
WHERE r.name = rr.engine_name;

ALTER TABLE mmf_portal.uploaded_target_accounts
    ADD COLUMN campaign_id bigint;
ALTER TABLE mmf_portal.campaign_history
    ADD COLUMN campaign_id bigint;
ALTER TABLE mmf_portal.agent_launches
    ADD COLUMN campaign_id bigint;
ALTER TABLE mmf_portal.campaign_partner_plays
    ADD COLUMN campaign_id bigint;
UPDATE mmf_portal.uploaded_target_accounts u
SET campaign_id = c.id FROM mmf_portal.campaigns c
WHERE c.name = u.campaign_name;
UPDATE mmf_portal.campaign_history h
SET campaign_id = c.id FROM mmf_portal.campaigns c
WHERE c.name = h.campaign_name;
UPDATE mmf_portal.agent_launches l
SET campaign_id = c.id FROM mmf_portal.campaigns c
WHERE c.name = l.campaign_name;
UPDATE mmf_portal.campaign_partner_plays cp
SET campaign_id = c.id FROM mmf_portal.campaigns c
WHERE c.name = cp.campaign_name;

ALTER TABLE mmf_portal.agent_usage_metrics
    ADD COLUMN agent_id bigint;
ALTER TABLE mmf_portal.agent_launches
    ADD COLUMN agent_id bigint;
UPDATE mmf_portal.agent_usage_metrics m
SET agent_id = a.id FROM mmf_portal.smart_agents a
WHERE a.name = m.agent_name;
UPDATE mmf_portal.agent_launches l
SET agent_id = a.id FROM mmf_portal.smart_agents a
WHERE a.name = l.agent_name;

ALTER TABLE mmf_portal.campaign_partner_plays
    ADD COLUMN partner_play_id bigint;
UPDATE mmf_portal.campaign_partner_plays cp
SET partner_play_id = p.id FROM mmf_portal.partner_plays p
WHERE p.name = cp.partner_play_name;

ALTER TABLE mmf_portal.governance_meetings
    ADD COLUMN council_id bigint;
UPDATE mmf_portal.governance_meetings m
SET council_id = c.id FROM mmf_portal.governance_councils c
WHERE c.name = m.council_name;

ALTER TABLE mmf_portal.accounts DROP CONSTRAINT accounts_pkey;
ALTER TABLE mmf_portal.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.accounts
    ADD CONSTRAINT accounts_name_key UNIQUE (name);

ALTER TABLE mmf_portal.solutions DROP CONSTRAINT solutions_pkey;
ALTER TABLE mmf_portal.solutions
    ADD CONSTRAINT solutions_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.solutions
    ADD CONSTRAINT solutions_name_key UNIQUE (name);

ALTER TABLE mmf_portal.radar_engines DROP CONSTRAINT radar_engines_pkey;
ALTER TABLE mmf_portal.radar_engines
    ADD CONSTRAINT radar_engines_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.radar_engines
    ADD CONSTRAINT radar_engines_name_key UNIQUE (name);

ALTER TABLE mmf_portal.campaigns DROP CONSTRAINT campaigns_pkey;
ALTER TABLE mmf_portal.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.campaigns
    ADD CONSTRAINT campaigns_name_key UNIQUE (name);

ALTER TABLE mmf_portal.smart_agents DROP CONSTRAINT smart_agents_pkey;
ALTER TABLE mmf_portal.smart_agents
    ADD CONSTRAINT smart_agents_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.smart_agents
    ADD CONSTRAINT smart_agents_name_key UNIQUE (name);

ALTER TABLE mmf_portal.partner_plays DROP CONSTRAINT partner_plays_pkey;
ALTER TABLE mmf_portal.partner_plays
    ADD CONSTRAINT partner_plays_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.partner_plays
    ADD CONSTRAINT partner_plays_name_key UNIQUE (name);

ALTER TABLE mmf_portal.data_source_connectors DROP CONSTRAINT data_source_connectors_pkey;
ALTER TABLE mmf_portal.data_source_connectors
    ADD CONSTRAINT data_source_connectors_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.data_source_connectors
    ADD CONSTRAINT data_source_connectors_name_key UNIQUE (name);

ALTER TABLE mmf_portal.governance_councils DROP CONSTRAINT governance_councils_pkey;
ALTER TABLE mmf_portal.governance_councils
    ADD CONSTRAINT governance_councils_pkey PRIMARY KEY (id);
ALTER TABLE mmf_portal.governance_councils
    ADD CONSTRAINT governance_councils_name_key UNIQUE (name);

ALTER TABLE mmf_portal.prospects
    ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE mmf_portal.opportunities
    ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE mmf_portal.radar_signals
    ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE mmf_portal.assets
    ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE mmf_portal.play_templates
    ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE mmf_portal.campaigns
    ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE mmf_portal.radar_signals
    ALTER COLUMN radar_engine_id SET NOT NULL;
ALTER TABLE mmf_portal.radar_runs
    ALTER COLUMN radar_engine_id SET NOT NULL;
ALTER TABLE mmf_portal.uploaded_target_accounts
    ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE mmf_portal.campaign_history
    ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE mmf_portal.campaign_partner_plays
    ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE mmf_portal.agent_usage_metrics
    ALTER COLUMN agent_id SET NOT NULL;
ALTER TABLE mmf_portal.agent_launches
    ALTER COLUMN agent_id SET NOT NULL;
ALTER TABLE mmf_portal.campaign_partner_plays
    ALTER COLUMN partner_play_id SET NOT NULL;
ALTER TABLE mmf_portal.governance_meetings
    ALTER COLUMN council_id SET NOT NULL;

ALTER TABLE mmf_portal.prospects DROP COLUMN account_name;
ALTER TABLE mmf_portal.opportunities DROP COLUMN account_name;
ALTER TABLE mmf_portal.radar_signals DROP COLUMN account_name;
ALTER TABLE mmf_portal.agent_launches DROP COLUMN account_name;
ALTER TABLE mmf_portal.assets DROP COLUMN solution_name;
ALTER TABLE mmf_portal.play_templates DROP COLUMN solution_name;
ALTER TABLE mmf_portal.campaigns DROP COLUMN solution_name;
ALTER TABLE mmf_portal.opportunities DROP COLUMN solution_name;
ALTER TABLE mmf_portal.campaigns DROP COLUMN radar_engine_name;
ALTER TABLE mmf_portal.radar_signals DROP COLUMN radar_engine_name;
ALTER TABLE mmf_portal.radar_runs DROP COLUMN engine_name;
ALTER TABLE mmf_portal.uploaded_target_accounts DROP COLUMN campaign_name;
ALTER TABLE mmf_portal.campaign_history DROP COLUMN campaign_name;
ALTER TABLE mmf_portal.agent_launches DROP COLUMN campaign_name;
ALTER TABLE mmf_portal.campaign_partner_plays DROP COLUMN campaign_name;
ALTER TABLE mmf_portal.agent_usage_metrics DROP COLUMN agent_name;
ALTER TABLE mmf_portal.agent_launches DROP COLUMN agent_name;
ALTER TABLE mmf_portal.campaign_partner_plays DROP COLUMN partner_play_name;
ALTER TABLE mmf_portal.governance_meetings DROP COLUMN council_name;

ALTER TABLE mmf_portal.prospects
    ADD CONSTRAINT prospects_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts (id);
ALTER TABLE mmf_portal.opportunities
    ADD CONSTRAINT opportunities_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts (id),
    ADD CONSTRAINT opportunities_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions(id);
ALTER TABLE mmf_portal.radar_signals
    ADD CONSTRAINT radar_signals_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts (id),
    ADD CONSTRAINT radar_signals_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines(id);
ALTER TABLE mmf_portal.agent_launches
    ADD CONSTRAINT agent_launches_account_id_fkey FOREIGN KEY (account_id) REFERENCES mmf_portal.accounts (id),
    ADD CONSTRAINT agent_launches_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES mmf_portal.smart_agents(id),
    ADD CONSTRAINT agent_launches_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns(id);
ALTER TABLE mmf_portal.assets
    ADD CONSTRAINT assets_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions (id);
ALTER TABLE mmf_portal.play_templates
    ADD CONSTRAINT play_templates_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions (id);
ALTER TABLE mmf_portal.campaigns
    ADD CONSTRAINT campaigns_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES mmf_portal.solutions (id),
    ADD CONSTRAINT campaigns_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines(id);
ALTER TABLE mmf_portal.radar_runs
    ADD CONSTRAINT radar_runs_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES mmf_portal.radar_engines (id) ON DELETE CASCADE;
ALTER TABLE mmf_portal.uploaded_target_accounts
    ADD CONSTRAINT uploaded_target_accounts_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns (id) ON DELETE CASCADE;
ALTER TABLE mmf_portal.campaign_history
    ADD CONSTRAINT campaign_history_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns (id) ON DELETE CASCADE;
ALTER TABLE mmf_portal.campaign_partner_plays
    ADD CONSTRAINT campaign_partner_plays_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES mmf_portal.campaigns (id) ON DELETE CASCADE,
    ADD CONSTRAINT campaign_partner_plays_partner_play_id_fkey FOREIGN KEY (partner_play_id) REFERENCES mmf_portal.partner_plays(id),
    ADD CONSTRAINT campaign_partner_plays_pkey PRIMARY KEY (campaign_id, partner_play_id);
ALTER TABLE mmf_portal.agent_usage_metrics
    ADD CONSTRAINT agent_usage_metrics_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES mmf_portal.smart_agents (id) ON DELETE CASCADE,
    ADD CONSTRAINT agent_usage_metrics_agent_id_measured_at_key UNIQUE (agent_id, measured_at);
ALTER TABLE mmf_portal.uploaded_target_accounts
    ADD CONSTRAINT uploaded_target_accounts_name_campaign_id_key UNIQUE (name, campaign_id);
ALTER TABLE mmf_portal.radar_signals
    ADD CONSTRAINT radar_signals_account_id_title_key UNIQUE (account_id, title);
ALTER TABLE mmf_portal.governance_meetings
    ADD CONSTRAINT governance_meetings_council_id_fkey FOREIGN KEY (council_id) REFERENCES mmf_portal.governance_councils (id),
    ADD CONSTRAINT governance_meetings_council_id_meeting_date_key UNIQUE (council_id, meeting_date);

CREATE INDEX prospects_account_id_idx ON mmf_portal.prospects (account_id);
CREATE INDEX opportunities_account_id_idx ON mmf_portal.opportunities (account_id);
CREATE INDEX opportunities_solution_id_idx ON mmf_portal.opportunities (solution_id);
CREATE INDEX radar_signals_account_id_idx ON mmf_portal.radar_signals (account_id);
CREATE INDEX assets_solution_id_idx ON mmf_portal.assets (solution_id);
CREATE INDEX play_templates_solution_id_idx ON mmf_portal.play_templates (solution_id);
CREATE INDEX campaigns_solution_id_idx ON mmf_portal.campaigns (solution_id);
CREATE INDEX campaigns_radar_engine_id_idx ON mmf_portal.campaigns (radar_engine_id);
CREATE INDEX radar_signals_radar_engine_id_idx ON mmf_portal.radar_signals (radar_engine_id);
CREATE INDEX radar_runs_radar_engine_id_idx ON mmf_portal.radar_runs (radar_engine_id);
CREATE INDEX uploaded_target_accounts_campaign_id_idx ON mmf_portal.uploaded_target_accounts (campaign_id);
CREATE INDEX campaign_history_campaign_id_idx ON mmf_portal.campaign_history (campaign_id);
CREATE INDEX campaign_partner_plays_partner_play_id_idx ON mmf_portal.campaign_partner_plays (partner_play_id);
CREATE INDEX agent_launches_account_id_idx ON mmf_portal.agent_launches (account_id);
CREATE INDEX agent_launches_agent_id_idx ON mmf_portal.agent_launches (agent_id);
CREATE INDEX agent_launches_campaign_id_idx ON mmf_portal.agent_launches (campaign_id);
CREATE INDEX agent_usage_metrics_agent_id_idx ON mmf_portal.agent_usage_metrics (agent_id);
CREATE INDEX governance_meetings_council_id_idx ON mmf_portal.governance_meetings (council_id);

COMMIT;
