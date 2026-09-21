-- Persist the aggregate state introduced by the v1.1 REST and GraphQL contracts.
ALTER TABLE assets
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

UPDATE assets
SET lifecycle_state = CASE certification_status
    WHEN 'Certified & Published' THEN 'Certified'
    WHEN 'Submitted' THEN 'Submitted'
    ELSE 'Draft'
END;

ALTER TABLE radar_engines
    ADD COLUMN prospect_set text NOT NULL DEFAULT 'Target prospects'
        CHECK (prospect_set IN ('Target prospects', 'Active campaign accounts', 'Qualified leads', 'Full mid-market master', 'Custom upload')),
    ADD COLUMN source_keys text[] NOT NULL DEFAULT '{}',
    ADD COLUMN frequency text NOT NULL DEFAULT 'Daily',
    ADD COLUMN run_at text NOT NULL DEFAULT '05:00 CET',
    ADD COLUMN lookback_days integer NOT NULL DEFAULT 14 CHECK (lookback_days > 0),
    ADD COLUMN minimum_score smallint NOT NULL DEFAULT 70 CHECK (minimum_score BETWEEN 0 AND 100),
    ADD COLUMN auto_link_campaigns boolean NOT NULL DEFAULT true;

CREATE TABLE radar_runs (
    id uuid PRIMARY KEY,
    engine_name text NOT NULL REFERENCES radar_engines(name) ON DELETE CASCADE,
    status text NOT NULL CHECK (status IN ('Accepted', 'Running', 'Completed', 'Failed')),
    requested_at timestamptz NOT NULL,
    completed_at timestamptz,
    failure_message text
);

ALTER TABLE smart_agents
    ADD COLUMN platform text,
    ADD COLUMN launch_url text,
    ADD COLUMN visibility_scopes text[] NOT NULL DEFAULT '{}',
    ADD COLUMN recommended_trigger_categories text[] NOT NULL DEFAULT '{}';

CREATE TABLE agent_launches (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name text NOT NULL REFERENCES smart_agents(name),
    launched_at timestamptz NOT NULL,
    launched_by text NOT NULL,
    account_name text,
    prospect_id text REFERENCES prospects(id),
    opportunity_id text REFERENCES opportunities(id),
    signal_id bigint REFERENCES radar_signals(id),
    campaign_name text REFERENCES campaigns(name)
);

CREATE TABLE campaign_partner_plays (
    campaign_name text NOT NULL REFERENCES campaigns(name) ON DELETE CASCADE,
    partner_play_name text NOT NULL REFERENCES partner_plays(name),
    linked_at timestamptz NOT NULL DEFAULT now(),
    linked_by text NOT NULL DEFAULT 'migration',
    PRIMARY KEY (campaign_name, partner_play_name)
);

INSERT INTO campaign_partner_plays (campaign_name, partner_play_name)
SELECT c.name, p.name
FROM campaigns c
JOIN partner_plays p ON p.partner_name = c.partner_name
WHERE c.partner_name IS NOT NULL
ON CONFLICT DO NOTHING;
