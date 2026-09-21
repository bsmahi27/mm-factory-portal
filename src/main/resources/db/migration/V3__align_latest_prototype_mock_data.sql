-- Align the persisted mock model with MMF Portal Prototype v3.1, 15 Sep 2026.
ALTER TABLE campaigns
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

ALTER TABLE radar_signals DROP CONSTRAINT radar_signals_severity_check;
ALTER TABLE radar_signals
    ADD CONSTRAINT radar_signals_severity_check CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    ADD COLUMN signal_category text,
    ADD COLUMN published_at date,
    ADD COLUMN opportunity_hypothesis text,
    ADD COLUMN recommended_agents text[] NOT NULL DEFAULT '{}',
    ADD COLUMN recommended_action text,
    ADD COLUMN scoring_inputs jsonb NOT NULL DEFAULT '{}';

ALTER TABLE smart_agents
    ADD COLUMN owner_team text,
    ADD COLUMN best_used_for text,
    ADD COLUMN launches_this_quarter integer NOT NULL DEFAULT 0 CHECK (launches_this_quarter >= 0);

ALTER TABLE kpi_snapshots
    ADD COLUMN client_count integer,
    ADD COLUMN target_account_count integer,
    ADD COLUMN active_account_count integer,
    ADD COLUMN active_campaign_count integer,
    ADD COLUMN active_partner_play_count integer,
    ADD COLUMN key_asset_count integer,
    ADD COLUMN smart_agent_count integer,
    ADD COLUMN qualified_lead_count integer,
    ADD COLUMN bookings_target_millions numeric(12,2);

CREATE TABLE partner_plays (
    name text PRIMARY KEY,
    partner_name text NOT NULL,
    partner_tier text NOT NULL,
    business_line text NOT NULL,
    theme text NOT NULL,
    eligible_country_codes text[] NOT NULL,
    status text NOT NULL CHECK (status IN ('Draft', 'Active', 'Paused', 'Closed')),
    value_proposition text NOT NULL,
    influenced_pipeline_millions numeric(12,2) NOT NULL DEFAULT 0 CHECK (influenced_pipeline_millions >= 0),
    linked_campaign_count integer NOT NULL DEFAULT 0 CHECK (linked_campaign_count >= 0),
    owner_name text NOT NULL
);

INSERT INTO partner_plays VALUES
    ('SAP RISE for Mid-Market', 'SAP', 'Platinum', 'ADM', 'SAP / Cloud', ARRAY['NL','DE','UK','SE','FI'], 'Active', 'Fixed-scope RISE migration with Capgemini mid-market accelerators and SAP funding support.', 9.4, 3, 'S. de Vries'),
    ('AWS Landing Zone Fast Start', 'AWS', 'Premier', 'CIS', 'SAP / Cloud', ARRAY['DE','UK','NO','DK'], 'Active', 'Six-week landing zone with AWS MAP funding; ideal entry play for new logos.', 6.7, 3, 'K. Weber'),
    ('Microsoft Data & AI Jumpstart', 'Microsoft', 'Premier', 'I&D', 'Data & AI', ARRAY['NL','DE','UK','SE','FI','NO','DK'], 'Active', 'Fabric-based data platform starter with joint Microsoft investment and a four-week proof of value.', 8.1, 4, 'L. Murray'),
    ('Adobe Commerce for Mid-Market Retail', 'Adobe', 'Gold', 'DCX', 'Sector play', ARRAY['NL','DE','SE'], 'Active', 'Pre-configured commerce stack for retailers under EUR 3B revenue, with Adobe co-marketing.', 4.2, 3, 'J. Bakker'),
    ('Siemens Smart Factory Accelerator', 'Siemens', 'Gold', 'CIS', 'Sector play', ARRAY['DE','SE'], 'Active', 'OT/IT convergence play for discrete manufacturers, co-delivered with Siemens.', 5.3, 2, 'A. Lindqvist'),
    ('ServiceNow ITSM Consolidation', 'ServiceNow', 'Gold', 'ADM', 'Vendor Consolidation', ARRAY['NL','UK'], 'Active', 'Consolidate fragmented tooling onto a single ITSM platform with a strong cost-takeout narrative.', 3.1, 2, 'M. Jansen'),
    ('Google Cloud Modernization Sprint', 'Google Cloud', 'Silver', 'CIS', 'Enterprise Technology Modernization', ARRAY['UK','DK'], 'Draft', 'Application modernization sprint with Google funding, pending the mid-market pricing model.', 0, 0, 'R. Patel');

UPDATE campaigns SET
    business_line = CASE name
        WHEN 'NL Industrial — IT Cost Takeout' THEN 'ADM' WHEN 'NL Retail — Commerce Acceleration' THEN 'DCX'
        WHEN 'DE Manufacturing — Smart Factory' THEN 'CIS' WHEN 'DE Industrial — Cost Takeout Q3' THEN 'ADM'
        WHEN 'UK Manufacturing — ADM Reboot' THEN 'ADM' WHEN 'UK E&U — Grid Analytics' THEN 'I&D'
        WHEN 'SE Industrial — Smart Factory' THEN 'CIS' WHEN 'FI Manufacturing — ADM Consolidation' THEN 'ADM'
        WHEN 'NO Energy — Cloud Foundation' THEN 'CIS' ELSE business_line END,
    meetings_booked = CASE name
        WHEN 'NL Industrial — IT Cost Takeout' THEN 11 WHEN 'NL Retail — Commerce Acceleration' THEN 6
        WHEN 'DE Manufacturing — Smart Factory' THEN 9 WHEN 'DE Industrial — Cost Takeout Q3' THEN 14
        WHEN 'UK Manufacturing — ADM Reboot' THEN 9 WHEN 'UK E&U — Grid Analytics' THEN 5
        WHEN 'SE Industrial — Smart Factory' THEN 7 WHEN 'FI Manufacturing — ADM Consolidation' THEN 6
        WHEN 'NO Energy — Cloud Foundation' THEN 4 ELSE meetings_booked END,
    qualified_leads = opportunities_generated,
    bookings_millions = round(pipeline_millions * 0.55, 1),
    revenue_won_millions = round(pipeline_millions * 0.24, 1);

-- The latest prototype has 29 unique agents. Duplicate lifecycle placements are UI metadata;
-- this table stores one catalogue record per agent and its displayed launch count.
TRUNCATE smart_agents CASCADE;
INSERT INTO smart_agents (name, lifecycle_stage, agent_type, status, version, description, grounding_sources, owner_team, best_used_for, launches_this_quarter) VALUES
    ('Intelio', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Creates a 360-degree client intelligence view including business context, sector trends, financials, technology priorities and opportunity hypotheses.', ARRAY['Radar signals','Public web'], 'Clients & Innovation', 'Account planning, first outreach, meeting preparation and opportunity shaping.', 64),
    ('BritMap', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Builds UK-focused BuyerMaps, decision-maker context and likely opportunity areas.', ARRAY['Radar signals','Public web'], 'Clients & Innovation', 'UK mid-market account intelligence and targeted sales engagement.', 22),
    ('Helder', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Creates concise BuyerMaps for Netherlands mid-market clients.', ARRAY['Radar signals','Public web'], 'Clients & Innovation', 'Netherlands teams preparing account meetings.', 18),
    ('Rapport', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Builds stakeholder intelligence profiles and engagement approaches.', ARRAY['Radar signals','Public web'], 'Clients & Innovation', 'Preparing for senior stakeholder conversations.', 37),
    ('Stakeholder Profile', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Structures stakeholder profiles from public and contextual inputs.', ARRAY['Public web'], 'Clients & Innovation', 'Account or bid stakeholder mapping.', 15),
    ('LinkedIn CXO Voice', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Decodes leadership activity and public CXO voice.', ARRAY['Public web'], 'Clients & Innovation', 'When leadership signals or executive changes are identified.', 26),
    ('Market Intel in a Box', 'Client intelligence', 'Internal', 'Published', 'v1.0', 'Generates executive-ready market intelligence and client briefings.', ARRAY['Public web'], 'Clients & Innovation', 'Leadership-ready account and market briefings.', 29),
    ('Knowledge SPOC', 'Meeting preparation', 'Internal', 'Published', 'v1.0', 'Finds relevant capability decks, case studies, sales kits and guidance.', ARRAY['Solutions & Assets (RAG)'], 'Knowledge Management', 'Preparing meeting materials or proof points.', 51),
    ('Beacon', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Identifies and scores buying signals using public data and a structured taxonomy.', ARRAY['Radar signals'], 'Clients & Innovation', 'Validating whether a trigger is commercially meaningful.', 33),
    ('Triggers Orchestrator', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Processes trigger lists and applies regional governance rules.', ARRAY['Radar signals'], 'Clients & Innovation', 'Standardising batches of trigger signals.', 12),
    ('Financial Analyst', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Analyses financial stress and maps it to IT services opportunities.', ARRAY['Public web','Radar signals'], 'Clients & Innovation', 'Financial updates, margin pressure or restructuring signals.', 44),
    ('Spend Scout', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Identifies likely investment areas from financials and company actions.', ARRAY['Public web','Radar signals'], 'Clients & Innovation', 'Separating commercial opportunity from market noise.', 20),
    ('Sales TransFORM', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Explains sales pipeline, bookings, forecasting and governance rules.', ARRAY['Salesforce'], 'Sales Analytics Centre', 'Qualifying or progressing pipeline stages.', 17),
    ('Deal Risk Sentinel', 'Opportunity qualification', 'Internal', 'Published', 'v1.0', 'Surfaces commercial, delivery, compliance and governance risks across deals.', ARRAY['Salesforce'], 'Wincentre', 'Qualification, go/no-go and deal review.', 25),
    ('Nexus', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Turns relevant innovation into client-ready value stories.', ARRAY['Solutions & Assets (RAG)','Radar signals'], 'Clients & Innovation', 'Shaping innovation-led proposals and solution angles.', 39),
    ('Researcher', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Conducts deep research on competitors, markets, clients and partnerships.', ARRAY['Public web','Radar signals'], 'Clients & Innovation', 'Market and competitor research during shaping.', 47),
    ('Horizon', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Anticipates public-sector tender opportunities before formal publication.', ARRAY['Public web'], 'Clients & Innovation', 'Pre-tender positioning.', 14),
    ('CompeteIQ', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Builds competitor overviews and compete strategy.', ARRAY['Public web'], 'Clients & Innovation', 'Strengthening differentiation and win themes.', 21),
    ('GCC Advisor', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Provides GCC market intelligence, talent and operating model insights.', ARRAY['Public web'], 'Clients & Innovation', 'GCC-related advisory opportunities.', 8),
    ('Beat The Competition', 'Origination & shaping', 'Internal', 'Published', 'v1.0', 'Creates competitive intelligence newsletters and market briefs.', ARRAY['Public web'], 'Clients & Innovation', 'Competitive monitoring and strategy.', 16),
    ('RFx Shredder', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Extracts RFP and RFI requirements, risks, gaps and evaluation criteria.', ARRAY['Uploaded RFP'], 'Wincentre', 'Day one of a bid or tender review.', 46),
    ('Bid Support Copilot', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Guides bid lifecycle activities, checklists, prompts and compliance.', ARRAY['Uploaded RFP'], 'Wincentre', 'Bid and presales teams during an RFx response.', 34),
    ('Winplan Navigator', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Builds win strategy, value proposition and competitive positioning.', ARRAY['Salesforce'], 'Wincentre', 'Pursuit strategy and win planning.', 28),
    ('RedTeam Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Critically reviews tender and bid content.', ARRAY['Uploaded RFP'], 'Wincentre', 'Before formal proposal review.', 19),
    ('Cognitive Review', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Reviews proposals for clarity, logic, trust and decision effectiveness.', ARRAY['Uploaded RFP'], 'Wincentre', 'Sharpening executive-ready proposal content.', 13),
    ('Proposal Matcher', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Compares RFx requirements with proposal content.', ARRAY['Uploaded RFP'], 'Proposal Centre', 'Validating proposal fit against customer requirements.', 23),
    ('Final Checker', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Checks RFP responses for consistency, grammar, formatting and compliance.', ARRAY['Uploaded RFP'], 'Proposal Centre', 'Before submission.', 30),
    ('Proposal Development', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Creates structured proposal documents from RFP content.', ARRAY['Uploaded RFP'], 'Proposal Centre', 'Accelerating drafting.', 26),
    ('FAQ / Response Draft - UK', 'RFP / bid support', 'Internal', 'Published', 'v1.0', 'Finds standard responses and bid essentials from UK knowledge sources.', ARRAY['Solutions & Assets (RAG)'], 'Wincentre', 'Questionnaires, FAQs and standard response drafting.', 11);

DELETE FROM kpi_snapshots;
INSERT INTO kpi_snapshots (as_of, business_unit_code, country_name, pipeline_millions, revenue_millions, coverage_percent, reuse_percent, signal_count, signal_conversion_percent, outreach_count, meeting_count, opportunities_created, stage_conversion_percent, pipeline_target_millions, revenue_target_millions, coverage_target_percent, client_count, target_account_count, active_account_count, active_campaign_count, active_partner_play_count, key_asset_count, smart_agent_count, qualified_lead_count, bookings_target_millions) VALUES
    ('2026-08-11 02:00:00+02', 'NL', NULL, 38.4, 45.0, 62, 71, 92, 7, 31, 12, 12, 31, 50, 60, 70, 150, 50, 31, 4, 12, 55, 29, 7, 60),
    ('2026-08-11 02:00:00+02', 'DE', NULL, 47.1, 52.6, 64, 68, 118, 11, 41, 18, 18, 36, 60, 70, 70, 210, 64, 41, 5, 9, 62, 29, 11, 70),
    ('2026-08-11 02:00:00+02', 'UK', NULL, 33.7, 38.2, 53, 64, 87, 8, 29, 14, 14, 34, 45, 55, 65, 180, 55, 29, 4, 8, 48, 29, 8, 55),
    ('2026-08-11 02:00:00+02', 'NO', 'Sweden', 16.2, 19.4, 53, 60, 51, 5, 17, 8, 6, 31, 22, 26, 62, 95, 32, 17, 3, 6, 34, 29, 5, 26),
    ('2026-08-11 02:00:00+02', 'NO', 'Finland', 12.8, 14.1, 54, 58, 44, 4, 14, 7, 5, 29, 17, 18, 60, 70, 26, 14, 2, 5, 28, 29, 4, 18),
    ('2026-08-11 02:00:00+02', 'NO', 'Norway', 9.6, 11.3, 45, 55, 36, 3, 10, 5, 4, 28, 14, 15, 60, 62, 22, 10, 2, 4, 24, 29, 3, 15),
    ('2026-08-11 02:00:00+02', 'NO', 'Denmark', 8.4, 9.8, 45, 56, 31, 3, 9, 4, 3, 27, 12, 13, 60, 58, 20, 9, 2, 4, 22, 29, 3, 13);