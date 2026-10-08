-- Replace mutable natural primary keys with stable generated identifiers.

ALTER TABLE prospects DROP CONSTRAINT prospects_account_name_fkey;
ALTER TABLE opportunities DROP CONSTRAINT opportunities_account_name_fkey;
ALTER TABLE radar_signals DROP CONSTRAINT radar_signals_account_name_fkey;
ALTER TABLE assets DROP CONSTRAINT assets_solution_name_fkey;
ALTER TABLE play_templates DROP CONSTRAINT play_templates_solution_name_fkey;
ALTER TABLE campaigns DROP CONSTRAINT campaigns_solution_name_fkey;
ALTER TABLE opportunities DROP CONSTRAINT opportunities_solution_name_fkey;
ALTER TABLE campaigns DROP CONSTRAINT campaigns_radar_engine_name_fkey;
ALTER TABLE radar_signals DROP CONSTRAINT radar_signals_radar_engine_name_fkey;
ALTER TABLE radar_runs DROP CONSTRAINT radar_runs_engine_name_fkey;
ALTER TABLE uploaded_target_accounts DROP CONSTRAINT uploaded_target_accounts_campaign_name_fkey;
ALTER TABLE campaign_history DROP CONSTRAINT campaign_history_campaign_name_fkey;
ALTER TABLE agent_launches DROP CONSTRAINT agent_launches_campaign_name_fkey;
ALTER TABLE campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_campaign_name_fkey;
ALTER TABLE agent_usage_metrics DROP CONSTRAINT agent_usage_metrics_agent_name_fkey;
ALTER TABLE agent_launches DROP CONSTRAINT agent_launches_agent_name_fkey;
ALTER TABLE campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_partner_play_name_fkey;
ALTER TABLE governance_meetings DROP CONSTRAINT governance_meetings_council_name_fkey;

ALTER TABLE campaign_partner_plays DROP CONSTRAINT campaign_partner_plays_pkey;
ALTER TABLE uploaded_target_accounts
    DROP CONSTRAINT uploaded_target_accounts_name_campaign_name_key;
ALTER TABLE radar_signals
    DROP CONSTRAINT radar_signals_account_name_title_key;
ALTER TABLE agent_usage_metrics
    DROP CONSTRAINT agent_usage_metrics_agent_name_measured_at_key;
ALTER TABLE governance_meetings
    DROP CONSTRAINT governance_meetings_council_name_meeting_date_key;

ALTER TABLE accounts ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE solutions ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE radar_engines ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE campaigns ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE smart_agents ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE partner_plays ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE data_source_connectors ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE governance_councils ADD COLUMN id bigint GENERATED ALWAYS AS IDENTITY;

ALTER TABLE prospects ADD COLUMN account_id bigint;
ALTER TABLE opportunities ADD COLUMN account_id bigint;
ALTER TABLE radar_signals ADD COLUMN account_id bigint;
ALTER TABLE agent_launches ADD COLUMN account_id bigint;
UPDATE prospects p SET account_id = a.id FROM accounts a WHERE a.name = p.account_name;
UPDATE opportunities o SET account_id = a.id FROM accounts a WHERE a.name = o.account_name;
UPDATE radar_signals s SET account_id = a.id FROM accounts a WHERE a.name = s.account_name;
UPDATE agent_launches l SET account_id = a.id FROM accounts a WHERE a.name = l.account_name;

ALTER TABLE assets ADD COLUMN solution_id bigint;
ALTER TABLE play_templates ADD COLUMN solution_id bigint;
ALTER TABLE campaigns ADD COLUMN solution_id bigint;
ALTER TABLE opportunities ADD COLUMN solution_id bigint;
UPDATE assets a SET solution_id = s.id FROM solutions s WHERE s.name = a.solution_name;
UPDATE play_templates p SET solution_id = s.id FROM solutions s WHERE s.name = p.solution_name;
UPDATE campaigns c SET solution_id = s.id FROM solutions s WHERE s.name = c.solution_name;
UPDATE opportunities o SET solution_id = s.id FROM solutions s WHERE s.name = o.solution_name;

ALTER TABLE campaigns ADD COLUMN radar_engine_id bigint;
ALTER TABLE radar_signals ADD COLUMN radar_engine_id bigint;
ALTER TABLE radar_runs ADD COLUMN radar_engine_id bigint;
UPDATE campaigns c SET radar_engine_id = r.id FROM radar_engines r WHERE r.name = c.radar_engine_name;
UPDATE radar_signals s SET radar_engine_id = r.id FROM radar_engines r WHERE r.name = s.radar_engine_name;
UPDATE radar_runs rr SET radar_engine_id = r.id FROM radar_engines r WHERE r.name = rr.engine_name;

ALTER TABLE uploaded_target_accounts ADD COLUMN campaign_id bigint;
ALTER TABLE campaign_history ADD COLUMN campaign_id bigint;
ALTER TABLE agent_launches ADD COLUMN campaign_id bigint;
ALTER TABLE campaign_partner_plays ADD COLUMN campaign_id bigint;
UPDATE uploaded_target_accounts u SET campaign_id = c.id FROM campaigns c WHERE c.name = u.campaign_name;
UPDATE campaign_history h SET campaign_id = c.id FROM campaigns c WHERE c.name = h.campaign_name;
UPDATE agent_launches l SET campaign_id = c.id FROM campaigns c WHERE c.name = l.campaign_name;
UPDATE campaign_partner_plays cp SET campaign_id = c.id FROM campaigns c WHERE c.name = cp.campaign_name;

ALTER TABLE agent_usage_metrics ADD COLUMN agent_id bigint;
ALTER TABLE agent_launches ADD COLUMN agent_id bigint;
UPDATE agent_usage_metrics m SET agent_id = a.id FROM smart_agents a WHERE a.name = m.agent_name;
UPDATE agent_launches l SET agent_id = a.id FROM smart_agents a WHERE a.name = l.agent_name;

ALTER TABLE campaign_partner_plays ADD COLUMN partner_play_id bigint;
UPDATE campaign_partner_plays cp SET partner_play_id = p.id FROM partner_plays p WHERE p.name = cp.partner_play_name;

ALTER TABLE governance_meetings ADD COLUMN council_id bigint;
UPDATE governance_meetings m SET council_id = c.id FROM governance_councils c WHERE c.name = m.council_name;

ALTER TABLE accounts DROP CONSTRAINT accounts_pkey;
ALTER TABLE accounts ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);
ALTER TABLE accounts ADD CONSTRAINT accounts_name_key UNIQUE (name);

ALTER TABLE solutions DROP CONSTRAINT solutions_pkey;
ALTER TABLE solutions ADD CONSTRAINT solutions_pkey PRIMARY KEY (id);
ALTER TABLE solutions ADD CONSTRAINT solutions_name_key UNIQUE (name);

ALTER TABLE radar_engines DROP CONSTRAINT radar_engines_pkey;
ALTER TABLE radar_engines ADD CONSTRAINT radar_engines_pkey PRIMARY KEY (id);
ALTER TABLE radar_engines ADD CONSTRAINT radar_engines_name_key UNIQUE (name);

ALTER TABLE campaigns DROP CONSTRAINT campaigns_pkey;
ALTER TABLE campaigns ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);
ALTER TABLE campaigns ADD CONSTRAINT campaigns_name_key UNIQUE (name);

ALTER TABLE smart_agents DROP CONSTRAINT smart_agents_pkey;
ALTER TABLE smart_agents ADD CONSTRAINT smart_agents_pkey PRIMARY KEY (id);
ALTER TABLE smart_agents ADD CONSTRAINT smart_agents_name_key UNIQUE (name);

ALTER TABLE partner_plays DROP CONSTRAINT partner_plays_pkey;
ALTER TABLE partner_plays ADD CONSTRAINT partner_plays_pkey PRIMARY KEY (id);
ALTER TABLE partner_plays ADD CONSTRAINT partner_plays_name_key UNIQUE (name);

ALTER TABLE data_source_connectors DROP CONSTRAINT data_source_connectors_pkey;
ALTER TABLE data_source_connectors ADD CONSTRAINT data_source_connectors_pkey PRIMARY KEY (id);
ALTER TABLE data_source_connectors ADD CONSTRAINT data_source_connectors_name_key UNIQUE (name);

ALTER TABLE governance_councils DROP CONSTRAINT governance_councils_pkey;
ALTER TABLE governance_councils ADD CONSTRAINT governance_councils_pkey PRIMARY KEY (id);
ALTER TABLE governance_councils ADD CONSTRAINT governance_councils_name_key UNIQUE (name);

ALTER TABLE prospects ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE opportunities ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE radar_signals ALTER COLUMN account_id SET NOT NULL;
ALTER TABLE assets ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE play_templates ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE campaigns ALTER COLUMN solution_id SET NOT NULL;
ALTER TABLE radar_signals ALTER COLUMN radar_engine_id SET NOT NULL;
ALTER TABLE radar_runs ALTER COLUMN radar_engine_id SET NOT NULL;
ALTER TABLE uploaded_target_accounts ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE campaign_history ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE campaign_partner_plays ALTER COLUMN campaign_id SET NOT NULL;
ALTER TABLE agent_usage_metrics ALTER COLUMN agent_id SET NOT NULL;
ALTER TABLE agent_launches ALTER COLUMN agent_id SET NOT NULL;
ALTER TABLE campaign_partner_plays ALTER COLUMN partner_play_id SET NOT NULL;
ALTER TABLE governance_meetings ALTER COLUMN council_id SET NOT NULL;

ALTER TABLE prospects DROP COLUMN account_name;
ALTER TABLE opportunities DROP COLUMN account_name;
ALTER TABLE radar_signals DROP COLUMN account_name;
ALTER TABLE agent_launches DROP COLUMN account_name;
ALTER TABLE assets DROP COLUMN solution_name;
ALTER TABLE play_templates DROP COLUMN solution_name;
ALTER TABLE campaigns DROP COLUMN solution_name;
ALTER TABLE opportunities DROP COLUMN solution_name;
ALTER TABLE campaigns DROP COLUMN radar_engine_name;
ALTER TABLE radar_signals DROP COLUMN radar_engine_name;
ALTER TABLE radar_runs DROP COLUMN engine_name;
ALTER TABLE uploaded_target_accounts DROP COLUMN campaign_name;
ALTER TABLE campaign_history DROP COLUMN campaign_name;
ALTER TABLE agent_launches DROP COLUMN campaign_name;
ALTER TABLE campaign_partner_plays DROP COLUMN campaign_name;
ALTER TABLE agent_usage_metrics DROP COLUMN agent_name;
ALTER TABLE agent_launches DROP COLUMN agent_name;
ALTER TABLE campaign_partner_plays DROP COLUMN partner_play_name;
ALTER TABLE governance_meetings DROP COLUMN council_name;

ALTER TABLE prospects
    ADD CONSTRAINT prospects_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id);
ALTER TABLE opportunities
    ADD CONSTRAINT opportunities_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id),
    ADD CONSTRAINT opportunities_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES solutions(id);
ALTER TABLE radar_signals
    ADD CONSTRAINT radar_signals_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id),
    ADD CONSTRAINT radar_signals_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES radar_engines(id);
ALTER TABLE agent_launches
    ADD CONSTRAINT agent_launches_account_id_fkey FOREIGN KEY (account_id) REFERENCES accounts(id),
    ADD CONSTRAINT agent_launches_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES smart_agents(id),
    ADD CONSTRAINT agent_launches_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES campaigns(id);
ALTER TABLE assets
    ADD CONSTRAINT assets_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES solutions(id);
ALTER TABLE play_templates
    ADD CONSTRAINT play_templates_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES solutions(id);
ALTER TABLE campaigns
    ADD CONSTRAINT campaigns_solution_id_fkey FOREIGN KEY (solution_id) REFERENCES solutions(id),
    ADD CONSTRAINT campaigns_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES radar_engines(id);
ALTER TABLE radar_runs
    ADD CONSTRAINT radar_runs_radar_engine_id_fkey FOREIGN KEY (radar_engine_id) REFERENCES radar_engines(id) ON DELETE CASCADE;
ALTER TABLE uploaded_target_accounts
    ADD CONSTRAINT uploaded_target_accounts_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE;
ALTER TABLE campaign_history
    ADD CONSTRAINT campaign_history_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE;
ALTER TABLE campaign_partner_plays
    ADD CONSTRAINT campaign_partner_plays_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE CASCADE,
    ADD CONSTRAINT campaign_partner_plays_partner_play_id_fkey FOREIGN KEY (partner_play_id) REFERENCES partner_plays(id),
    ADD CONSTRAINT campaign_partner_plays_pkey PRIMARY KEY (campaign_id, partner_play_id);
ALTER TABLE agent_usage_metrics
    ADD CONSTRAINT agent_usage_metrics_agent_id_fkey FOREIGN KEY (agent_id) REFERENCES smart_agents(id) ON DELETE CASCADE,
    ADD CONSTRAINT agent_usage_metrics_agent_id_measured_at_key UNIQUE (agent_id, measured_at);
ALTER TABLE uploaded_target_accounts
    ADD CONSTRAINT uploaded_target_accounts_name_campaign_id_key UNIQUE (name, campaign_id);
ALTER TABLE radar_signals
    ADD CONSTRAINT radar_signals_account_id_title_key UNIQUE (account_id, title);
ALTER TABLE governance_meetings
    ADD CONSTRAINT governance_meetings_council_id_fkey FOREIGN KEY (council_id) REFERENCES governance_councils(id),
    ADD CONSTRAINT governance_meetings_council_id_meeting_date_key UNIQUE (council_id, meeting_date);

CREATE INDEX prospects_account_id_idx ON prospects (account_id);
CREATE INDEX opportunities_account_id_idx ON opportunities (account_id);
CREATE INDEX opportunities_solution_id_idx ON opportunities (solution_id);
CREATE INDEX radar_signals_account_id_idx ON radar_signals (account_id);
CREATE INDEX assets_solution_id_idx ON assets (solution_id);
CREATE INDEX play_templates_solution_id_idx ON play_templates (solution_id);
CREATE INDEX campaigns_solution_id_idx ON campaigns (solution_id);
CREATE INDEX campaigns_radar_engine_id_idx ON campaigns (radar_engine_id);
CREATE INDEX radar_signals_radar_engine_id_idx ON radar_signals (radar_engine_id);
CREATE INDEX radar_runs_radar_engine_id_idx ON radar_runs (radar_engine_id);
CREATE INDEX uploaded_target_accounts_campaign_id_idx ON uploaded_target_accounts (campaign_id);
CREATE INDEX campaign_history_campaign_id_idx ON campaign_history (campaign_id);
CREATE INDEX campaign_partner_plays_partner_play_id_idx ON campaign_partner_plays (partner_play_id);
CREATE INDEX agent_launches_account_id_idx ON agent_launches (account_id);
CREATE INDEX agent_launches_agent_id_idx ON agent_launches (agent_id);
CREATE INDEX agent_launches_campaign_id_idx ON agent_launches (campaign_id);
CREATE INDEX agent_usage_metrics_agent_id_idx ON agent_usage_metrics (agent_id);
CREATE INDEX governance_meetings_council_id_idx ON governance_meetings (council_id);