
-- view returns every mailchimp_list_member, with project, street etc. from last
-- report if available, otherwise defaults to list table's project
-- DROP VIEW IF EXISTS mailchimp_list_members_with_last_reports;
CREATE OR REPLACE VIEW mailchimp_list_members_with_last_reports AS
SELECT 
	m.pk,
	m.id,
	m.email_address,
	-- Use the last project reported on, or first part of MailChimp project if no report submitted yet
	CASE WHEN last_project IS NOT NULL THEN l.last_project ELSE split_part(m.project,E'\n',1) END::varchar AS project,
	last_street_number,
	last_street,
	last_postcode,
	last_date,
	last_trap_checked,
	last_bait_checked,
	last_minutes,
	CASE WHEN l.last_projects_text IS NOT NULL THEN l.last_projects_text ELSE m.project END AS last_projects_text,
	last_projects
FROM mailchimp_list_members m
LEFT JOIN members_last_reports l ON m.email_address = l.email_address;


-- This view is what is to be set in Mailchimp via their API, for each member.
-- New TURP 2.5 version which uses WordPress managed stories and projects.
-- DROP VIEW IF EXISTS mailchimp_member_data;
CREATE OR REPLACE VIEW public.mailchimp_member_data AS
	SELECT  
		m.pk,
		m.id,
		m.email_address,
		m.project AS project_name,
		project.logo_url AS project_logo_url,
		project.contact_email AS project_email_address,
		story.story_title,
		story.story_content AS story_text,
		story.story_url AS story_more_info_url,
		story.story_image_url,
		m.last_street_number,
		m.last_street,
		m.last_postcode,
		m.last_minutes,
		m.last_date,
			CASE m.last_trap_checked
				WHEN true THEN 'Yes'::text
				ELSE 'No'::text
			END AS last_trap_checked,
			CASE m.last_bait_checked
				WHEN true THEN 'Yes'::text
				ELSE 'No'::text
			END AS last_bait_checked,
		s.reports_total,
		s.reports_last_30,
		s.reports_last_30_rank_in_street,
		s.reports_total_rank_in_street,
		s.reports_last_30_rank_in_postcode,
		s.reports_total_rank_in_postcode,
		s.trap_catches_total,
		s.trap_catches_last_30,
		s.street_reports_total,
		s.street_reports_last_30,
		s.street_members_total,
		s.street_members_last_30,
		s.street_trap_catches_last_30,
		round(s.street_bait_taken_average_last_30, 0) AS street_bait_taken_average_last_30,
		s.postcode_reports_total,
		s.postcode_reports_last_30,
		s.postcode_members_total,
		s.postcode_members_last_30,
		s.postcode_trap_catches_last_30,
		round(s.postcode_bait_taken_average_last_30, 0) AS postcode_bait_taken_average_last_30,
		n.reports_total AS nat_reports_total,
		n.reports_last_30 AS nat_reports_last_30,
		m.last_projects_text AS projects
    FROM 
		mailchimp_list_members_with_last_reports m
    LEFT JOIN 
		stats_by_member_street_postcode_latest s ON m.email_address = s.email_address
    -- join the user's project if they have one
    LEFT JOIN 
		latest_project_revisions project ON m.project = project.title
    -- join the default project for users who haven't selected one
    LEFT JOIN 
		latest_project_revisions default_project ON default_project.project_id = 798
    -- choose the latest revision of the current story for the user's project if available, otherwise from the default project
    LEFT JOIN 
		latest_story_revisions story ON story.story_id = CASE WHEN project.id IS NULL THEN default_project.current_story_id ELSE project.current_story_id END
    -- add all the national level stats
    CROSS JOIN 
		stats_latest n;

	
-- SELECT * FROM mailchimp_member_data;

