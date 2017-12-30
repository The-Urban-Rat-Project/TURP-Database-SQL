-- calculate statistics for every street reported on so far
DROP MATERIALIZED VIEW IF EXISTS stats_by_street_latest;
CREATE MATERIALIZED VIEW stats_by_street_latest AS SELECT 
	street,
	postcode,
	-- reports
	COUNT(*) AS reports_total,
	COUNT(*) FILTER (WHERE date >= CURRENT_DATE-30) AS reports_last_30,
	MIN(date) AS earliest,
	MAX(date) AS latest,
	-- members
	COUNT(DISTINCT email_address) AS members_total,
	COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-30) AS members_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS members_trapping_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS members_baiting_last_30,
	SUM(minutes) AS minutes_total,
	SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-30) AS minutes_last_30,
	-- traps
	count(*) FILTER (WHERE trap_checked) AS trap_checks_total,
	count(*) FILTER (WHERE trap_caught IS NOT NULL) AS trap_catches_total,
	count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS trap_checks_last_30,
	count(*) FILTER (WHERE trap_caught IS NOT NULL AND date >= CURRENT_DATE-30) AS trap_catches_last_30,
	-- bait stations,
	count(*) FILTER (WHERE bait_checked) AS bait_checks_total,
	AVG(bait_taken) FILTER (WHERE bait_checked) AS bait_taken_average,
	count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_checks_last_30,
	AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_taken_average_last_30
	
FROM 
	reports
GROUP BY
	street,
	postcode;
	
REFRESH MATERIALIZED VIEW stats_by_street_latest;



--------------------------------------------------------------------------------
-- Do we want to return rank, percent_rank(), or perc_position from here? Probably not all of them?

-- calculate statistics for every street recorded so far
/*SELECT 
	s.*,
	-- street reports rankings in postcode
	RANK() OVER (PARTITION BY postcode ORDER BY reports DESC) AS reports_rank_in_postcode,
	RANK() OVER (PARTITION BY postcode ORDER BY reports_last_7 DESC) AS reports_rank_in_postcode_last_7,
	RANK() OVER (PARTITION BY postcode ORDER BY reports_last_30 DESC) AS reports_rank_in_postcode_last_30,
	RANK() OVER (PARTITION BY postcode ORDER BY reports_last_90 DESC) AS reports_rank_in_postcode_last_90,
	RANK() OVER (PARTITION BY postcode ORDER BY reports_last_365 DESC) AS reports_rank_in_postcode_last_365,
	perc_position(PERCENT_RANK() OVER (PARTITION BY postcode ORDER BY reports DESC)) AS reports_perc_in_postcode,
	perc_position(PERCENT_RANK() OVER (PARTITION BY postcode ORDER BY reports_last_7 DESC)) AS reports_perc_in_postcode_last_7,
	perc_position(PERCENT_RANK() OVER (PARTITION BY postcode ORDER BY reports_last_30 DESC)) AS reports_perc_in_postcode_last_30,
	perc_position(PERCENT_RANK() OVER (PARTITION BY postcode ORDER BY reports_last_90 DESC)) AS reports_perc_in_postcode_last_90,
	perc_position(PERCENT_RANK() OVER (PARTITION BY postcode ORDER BY reports_last_365 DESC)) AS reports_perc_in_postcode_last_365
FROM 
	(SELECT 
		street,
		postcode,
		-- reports
		COUNT(*) AS reports,
		COUNT(*) FILTER (WHERE date >= CURRENT_DATE-7) AS reports_last_7,
		COUNT(*) FILTER (WHERE date >= CURRENT_DATE-30) AS reports_last_30,
		COUNT(*) FILTER (WHERE date >= CURRENT_DATE-90) AS reports_last_90,
		COUNT(*) FILTER (WHERE date >= CURRENT_DATE-365) AS reports_last_365,
		-- earliest and latest dates
		MIN(date) AS earliest,
		MAX(date) AS latest,
		-- members
		COUNT(DISTINCT email_address) AS members,
		COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-7) AS members_last_7,
		COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-30) AS members_last_30,
		COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-90) AS members_last_90,
		COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-365) AS members_last_365,
		-- members trapping and baiting
		COUNT(DISTINCT email_address) FILTER (WHERE trap_checked) AS members_trapping,
		COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-7) AS members_trapping_last_7,
		COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS members_trapping_last_30,
		COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-90) AS members_trapping_last_90,
		COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-365) AS members_trapping_last_365,
		COUNT(DISTINCT email_address) FILTER (WHERE bait_checked) AS members_baiting,
		COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-7) AS members_baiting_last_7,
		COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS members_baiting_last_30,
		COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-90) AS members_baiting_last_90,
		COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-365) AS members_baiting_last_365,
		-- time spent
		SUM(minutes) AS minutes,
		SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-7) AS minutes_last_7,
		SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-30) AS minutes_last_30,
		SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-90) AS minutes_last_90,
		SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-365) AS minutes_last_365,
		-- trap reports and catches
		count(*) FILTER (WHERE trap_checked) AS trap_checks,
		count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-7) AS trap_checks_last_7,
		count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS trap_checks_last_30,
		count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-90) AS trap_checks_last_90,
		count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-365) AS trap_checks_last_365,
		count(*) FILTER (WHERE trap_checked AND trap_caught IS NOT NULL) AS trap_catches,
		count(*) FILTER (WHERE trap_checked AND trap_caught IS NOT NULL AND date >= CURRENT_DATE-7) AS trap_catches_last_7,
		count(*) FILTER (WHERE trap_checked AND trap_caught IS NOT NULL AND date >= CURRENT_DATE-30) AS trap_catches_last_30,
		count(*) FILTER (WHERE trap_checked AND trap_caught IS NOT NULL AND date >= CURRENT_DATE-90) AS trap_catches_last_90,
		count(*) FILTER (WHERE trap_checked AND trap_caught IS NOT NULL AND date >= CURRENT_DATE-365) AS trap_catches_last_365,
		-- bait stations and bait taken
		count(*) FILTER (WHERE bait_checked) AS bait_checks,
		count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-7) AS bait_checks_last_7,
		count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_checks_last_30,
		count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-90) AS bait_checks_last_90,
		count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-365) AS bait_checks_last_365,
		AVG(bait_taken) FILTER (WHERE bait_checked) AS bait_taken_mean,
		AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-7) AS bait_taken_mean_last_7,
		AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_taken_mean_last_30,
		AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-90) AS bait_taken_mean_last_90,
		AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-365) AS bait_taken_mean_last_365
		
	FROM 
		reports
	GROUP BY
		street,
		postcode ) AS s
;	
*/

---------------------------------

-- SELECT * FROM stats_by_street_latest;

DROP MATERIALIZED VIEW IF EXISTS stats_latest;
CREATE MATERIALIZED VIEW stats_latest AS SELECT 
	-- reports
	COUNT(*) AS reports_total,
	COUNT(*) FILTER (WHERE date >= CURRENT_DATE-30) AS reports_last_30,
	MIN(date) AS earliest,
	MAX(date) AS latest,
	-- members
	COUNT(DISTINCT email_address) AS members_total,
	COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-30) AS members_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS members_trapping_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS members_baiting_last_30,
	SUM(minutes) AS minutes_total,
	SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-30) AS minutes_last_30,
	-- traps
	count(*) FILTER (WHERE trap_checked) AS trap_checks_total,
	count(*) FILTER (WHERE trap_caught IS NOT NULL) AS trap_catches_total,
	count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS trap_checks_last_30,
	count(*) FILTER (WHERE trap_caught IS NOT NULL AND date >= CURRENT_DATE-30) AS trap_catches_last_30,
	-- bait stations,
	count(*) FILTER (WHERE bait_checked) AS bait_checks_total,
	AVG(bait_taken) FILTER (WHERE bait_checked) AS bait_taken_average,
	count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_checks_last_30,
	AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_taken_average_last_30
	
FROM 
	reports;
	
REFRESH MATERIALIZED VIEW stats_latest;

-- SELECT * FROM stats_latest;

-- calculate statistics for every postcode reported on so far

DROP MATERIALIZED VIEW IF EXISTS stats_by_postcode_latest;
CREATE MATERIALIZED VIEW stats_by_postcode_latest AS 
SELECT 
	postcode,
	-- reports
	COUNT(*) AS reports_total,
	COUNT(*) FILTER (WHERE date >= CURRENT_DATE-30) AS reports_last_30,
	MIN(date) AS earliest,
	MAX(date) AS latest,
	-- members
	COUNT(DISTINCT email_address) AS members_total,
	COUNT(DISTINCT email_address) FILTER (WHERE date >= CURRENT_DATE-30) AS members_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS members_trapping_last_30,
	COUNT(DISTINCT email_address) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS members_baiting_last_30,
	SUM(minutes) AS minutes_total,
	SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-30) AS minutes_last_30,
	-- traps
	count(*) FILTER (WHERE trap_checked) AS trap_checks_total,
	count(*) FILTER (WHERE trap_caught IS NOT NULL) AS trap_catches_total,
	count(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS trap_checks_last_30,
	count(*) FILTER (WHERE trap_caught IS NOT NULL AND date >= CURRENT_DATE-30) AS trap_catches_last_30,
	-- bait stations,
	count(*) FILTER (WHERE bait_checked) AS bait_checks_total,
	AVG(bait_taken) FILTER (WHERE bait_checked) AS bait_taken_average,
	count(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_checks_last_30,
	AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_taken_average_last_30
	
FROM 
	reports
GROUP BY
	postcode;

REFRESH MATERIALIZED VIEW stats_by_postcode_latest;
-- SELECT * FROM stats_by_postcode_latest;

-- calculate statistics for every member who's reported so far

DROP VIEW IF EXISTS stats_by_member_latest CASCADE;
CREATE VIEW stats_by_member_latest AS
SELECT 
	m.*,
	-- member's ranking nationally
	PERCENT_RANK() OVER (ORDER BY reports_total DESC) AS reports_total_percentile,
	PERCENT_RANK() OVER (ORDER BY reports_last_30 DESC) AS reports_last_30_percentile,
	PERCENT_RANK() OVER (ORDER BY minutes_total DESC) AS minutes_total_percentile,
	PERCENT_RANK() OVER (ORDER BY minutes_last_30 DESC) AS minutes_last_30_percentile,
	-- member's ranking in postcode
	last_postcode,
	RANK() OVER (PARTITION BY last_postcode ORDER BY reports_total DESC) AS reports_total_rank_in_postcode,
	RANK() OVER (PARTITION BY last_postcode ORDER BY reports_last_30 DESC) AS reports_last_30_rank_in_postcode,
	-- member's ranking in street
	last_street,
	RANK() OVER (PARTITION BY last_street ORDER BY reports_total DESC) AS reports_total_rank_in_street,
	RANK() OVER (PARTITION BY last_street ORDER BY reports_last_30 DESC) AS reports_last_30_rank_in_street
FROM ( 
	SELECT
		email_address,
		-- reports
		COUNT(*) AS reports_total,
		COUNT(*) FILTER (WHERE date >= CURRENT_DATE-30) AS reports_last_30,
		MIN(date) AS earliest,
		MAX(date) AS latest,
		-- members
		SUM(minutes) AS minutes_total,
		SUM(minutes) FILTER (WHERE date >= CURRENT_DATE-30) AS minutes_last_30,
		-- traps
		COUNT(*) FILTER (WHERE trap_checked) AS trap_checks_total,
		COUNT(*) FILTER (WHERE trap_caught IS NOT NULL) AS trap_catches_total,
		COUNT(*) FILTER (WHERE trap_checked AND date >= CURRENT_DATE-30) AS trap_checks_last_30,
		COUNT(*) FILTER (WHERE trap_caught IS NOT NULL AND date >= CURRENT_DATE-30) AS trap_catches_last_30,
		-- bait stations,
		COUNT(*) FILTER (WHERE bait_checked) AS bait_checks_total,
		AVG(bait_taken) FILTER (WHERE bait_checked) AS bait_taken_average,
		COUNT(*) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_checks_last_30,
		AVG(bait_taken) FILTER (WHERE bait_checked AND date >= CURRENT_DATE-30) AS bait_taken_average_last_30
		FROM 
			reports
		GROUP BY
			email_address
	) m
JOIN 
	-- need the member's last postcode and street to figure out their ranking in those localities
	members_last_reports l ON m.email_address = l.email_address
;

-- SELECT * FROM stats_by_member_latest;


-- composite member, postcode and street stats for all members
DROP VIEW IF EXISTS stats_by_member_street_postcode_latest;
CREATE VIEW stats_by_member_street_postcode_latest AS SELECT
	m.*,
	p.reports_total postcode_reports_total,
	p.reports_last_30 postcode_reports_last_30,
	p.earliest postcode_earliest,
	p.latest postcode_latest,
	p.members_total postcode_members_total,
	p.members_last_30 postcode_members_last_30,
	p.members_trapping_last_30 postcode_members_trapping_last_30,
	p.members_baiting_last_30 postcode_members_baiting_last_30,
	p.minutes_total postcode_minutes_total,
	p.minutes_last_30 postcode_minutes_last_30,
	p.trap_checks_total postcode_trap_checks_total,
	p.trap_catches_total postcode_trap_catches_total,
	p.trap_checks_last_30 postcode_trap_checks_last_30,
	p.trap_catches_last_30 postcode_trap_catches_last_30,
	p.bait_checks_total postcode_bait_checks_total,
	p.bait_taken_average postcode_bait_taken_average,
	p.bait_checks_last_30 postcode_bait_checks_last_30,
	p.bait_taken_average_last_30 postcode_bait_taken_average_last_30,
	s.reports_total street_reports_total,
	s.reports_last_30 street_reports_last_30,
	s.earliest street_earliest,
	s.latest street_latest,
	s.members_total street_members_total,
	s.members_last_30 street_members_last_30,
	s.members_trapping_last_30 street_members_trapping_last_30,
	s.members_baiting_last_30 street_members_baiting_last_30,
	s.minutes_total street_minutes_total,
	s.minutes_last_30 street_minutes_last_30,
	s.trap_checks_total street_trap_checks_total,
	s.trap_catches_total street_trap_catches_total,
	s.trap_checks_last_30 street_trap_checks_last_30,
	s.trap_catches_last_30 street_trap_catches_last_30,
	s.bait_checks_total street_bait_checks_total,
	s.bait_taken_average street_bait_taken_average,
	s.bait_checks_last_30 street_bait_checks_last_30,
	s.bait_taken_average_last_30 street_bait_taken_average_last_30
FROM 
	stats_by_member_latest m
JOIN
	stats_by_postcode_latest p ON m.last_postcode = p.postcode
JOIN
	stats_by_street_latest s ON (m.last_street = s.street AND m.last_postcode = s.postcode);	


-- SELECT * FROM members_last_reports;