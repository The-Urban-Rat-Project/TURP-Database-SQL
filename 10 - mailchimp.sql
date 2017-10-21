
-- view returns every mailchimp_list_member, with project, street etc. from last
-- report if available, otherwise defaults to list table's project
DROP VIEW IF EXISTS mailchimp_list_members_with_last_reports;
CREATE VIEW mailchimp_list_members_with_last_reports AS
SELECT 
	m.pk,
	m.id,
	m.email_address,
	CASE WHEN last_project IS NOT NULL THEN l.last_project ELSE m.project END AS project,
	last_street_number,
	last_street,
	last_postcode,
	last_date,
	last_trap_checked,
	last_bait_checked,
	last_minutes
FROM mailchimp_list_members m
LEFT JOIN members_last_reports l ON m.email_address = l.email_address;

-------------------------------------------------------------
-- This view is what is to be set in Mailchimp via their API, for each member.
-- old version that uses JotForm-submitted stories.
/*DROP VIEW IF EXISTS mailchimp_member_data;
CREATE VIEW mailchimp_member_data AS 
SELECT
	m.pk,
	m.id,
	m.email_address,
	-- to pre-populate their File a Report form
	m.project AS project_name,
	-- put in the project's latest story, defaulting to project 0 which is TURP if they're not part of one
	CASE WHEN m.project IS NULL THEN o2.title ELSE o.title END AS story_title,
	LEFT(CASE WHEN m.project IS NULL THEN o2.text ELSE o.text END,255) AS story_text, -- limited to 255 bytes by MailChimp
	CASE WHEN m.project IS NULL THEN o2.more_info_url ELSE o.more_info_url END AS more_info_url,
	CASE WHEN m.project IS NULL THEN o2.image_url ELSE o.image_url END AS story_image_url,
	o.project_logo_url AS project_logo_url,
	o.project_email_address as project_email_address,
	-- used to prepopulate their form, and to show some data 
	m.last_street,
	m.last_postcode,
	m.last_minutes,
	m.last_date,
	CASE m.last_trap_checked WHEN TRUE THEN 'Yes' ELSE 'No' END AS last_trap_checked ,
	CASE m.last_bait_checked WHEN TRUE THEN 'Yes' ELSE 'No' END AS last_bait_checked ,
	-- how the member is doing 
	s.reports_total,
	s.reports_last_30,
	reports_last_30_rank_in_street,
	reports_total_rank_in_street,
	reports_last_30_rank_in_postcode,
	reports_total_rank_in_postcode,
	s.trap_catches_total,
	s.trap_catches_last_30,
	   -- could add some more rankings here for catches and bait
	-- how the street is doing
	street_reports_total,
	street_reports_last_30,
	street_members_total,
	street_members_last_30,
	street_trap_catches_last_30,
	ROUND(street_bait_taken_average_last_30,0) street_bait_taken_average_last_30, -- percentage
	-- how the postcode is doing
	postcode_reports_total,
	postcode_reports_last_30,
	postcode_members_total,
	postcode_members_last_30,
	postcode_trap_catches_last_30,
	ROUND(postcode_bait_taken_average_last_30,0) postcode_bait_taken_average_last_30,  -- percentage
	-- how we're doing nationally
 	n.reports_total nat_reports_total,
 	n.reports_last_30 nat_reports_last_30
FROM
	mailchimp_list_members_with_last_reports m
LEFT JOIN
	stats_by_member_street_postcode_latest s ON m.email_address = s.email_address
LEFT JOIN 
	latest_stories o ON m.project = o.project_name
LEFT JOIN latest_stories o2 ON 0 = o2.project -- allows default to TURP story
CROSS JOIN
	stats_latest n;
*/	
-- SELECT * FROM mailchimp_member_data;

-- This view is what is to be set in Mailchimp via their API, for each member.
-- New TURP 2.5 version which uses WordPress managed stories and projects.
DROP VIEW IF EXISTS mailchimp_member_data;
CREATE VIEW mailchimp_member_data AS 
SELECT
	m.pk,
	m.id,
	m.email_address,
	-- to pre-populate their File a Report form
	m.project AS project_name,
	-- put in the project's latest story, defaulting to project 0 which is TURP if they're not part of one
	CASE WHEN m.project IS NULL THEN default_story.story_title ELSE story.story_title END AS story_title,
	LEFT(CASE WHEN m.project IS NULL THEN default_story.story_content ELSE story.story_content END,255) AS story_text, -- limited to 255 bytes by MailChimp
	CASE WHEN m.project IS NULL THEN default_story.story_url ELSE story.story_url END AS story_more_info_url,
	CASE WHEN m.project IS NULL THEN default_story.story_image_url ELSE story.story_image_url END AS story_image_url,
	project.logo_url AS project_logo_url,
	project.contact_email as project_email_address,
	-- used to prepopulate their form, and to show some data 
	m.last_street_number,
	m.last_street,
	m.last_postcode,
	m.last_minutes,
	m.last_date,
	CASE m.last_trap_checked WHEN TRUE THEN 'Yes' ELSE 'No' END AS last_trap_checked ,
	CASE m.last_bait_checked WHEN TRUE THEN 'Yes' ELSE 'No' END AS last_bait_checked ,
	-- how the member is doing 
	s.reports_total,
	s.reports_last_30,
	reports_last_30_rank_in_street,
	reports_total_rank_in_street,
	reports_last_30_rank_in_postcode,
	reports_total_rank_in_postcode,
	s.trap_catches_total,
	s.trap_catches_last_30,
	   -- could add some more rankings here for catches and bait
	-- how the street is doing
	street_reports_total,
	street_reports_last_30,
	street_members_total,
	street_members_last_30,
	street_trap_catches_last_30,
	ROUND(street_bait_taken_average_last_30,0) street_bait_taken_average_last_30, -- percentage
	-- how the postcode is doing
	postcode_reports_total,
	postcode_reports_last_30,
	postcode_members_total,
	postcode_members_last_30,
	postcode_trap_catches_last_30,
	ROUND(postcode_bait_taken_average_last_30,0) postcode_bait_taken_average_last_30,  -- percentage
	-- how we're doing nationally
 	n.reports_total nat_reports_total,
 	n.reports_last_30 nat_reports_last_30
FROM
	mailchimp_list_members_with_last_reports m
LEFT JOIN
	stats_by_member_street_postcode_latest s ON m.email_address = s.email_address
LEFT JOIN 
	latest_project_revisions project ON m.project = project.title
LEFT JOIN -- story for the project they've selected, or null
	latest_story_revisions story ON story.story_id = project.current_story_id
LEFT JOIN 
	latest_story_revisions default_story ON default_story.project_id = 798 -- allows default to TURP story
CROSS JOIN
	stats_latest n;	


	
-- SELECT * FROM mailchimp_member_data;

