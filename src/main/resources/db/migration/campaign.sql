ALTER TABLE mmf_portal.campaigns
    ADD COLUMN sponsor_name VARCHAR(255),
ADD COLUMN target_industry VARCHAR(255),
ADD COLUMN campaign_visual TEXT,
ADD COLUMN target_account_list TEXT,
ADD COLUMN market_insights TEXT,
ADD COLUMN sales_playbook TEXT,
ADD COLUMN linked_solution_name VARCHAR(255);