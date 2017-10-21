
-- FUNCTION: public.normalise_street(character varying)

-- DROP FUNCTION public.normalise_street(character varying);

CREATE OR REPLACE FUNCTION public.normalise_street(
	address character varying)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE SECURITY DEFINER 
    ROWS 0
AS $BODY$
DECLARE 
	s character varying;
BEGIN
	s := INITCAP($1);
    s := REGEXP_REPLACE(s,'\mAvenue\M', 'Ave' );
    s := REGEXP_REPLACE(s,'\mCrescent\M', 'Cr' );
    s := REGEXP_REPLACE(s,'\mRoad\M', 'Rd' );
    s := REGEXP_REPLACE(s,'\mStreet\M', 'St' );
    s := REGEXP_REPLACE(s,'\mLane\M', 'Ln' );
    s := REGEXP_REPLACE(s,'\mTerrace\M', 'Tce' );
    s := REGEXP_REPLACE(s,'\mPlace\M', 'Pl' );
    s := REGEXP_REPLACE(s,'\mParade\M', 'Pde' );

  	RETURN TRIM(s); 
END

$BODY$;

ALTER FUNCTION public.normalise_street(character varying)
    OWNER TO database_admin;


	
-- PERC_POSITION returns "top 22%" or "bottom 15%" etc. given a fraction, where 0 is top ranked, and 1 is bottom ranked.
-- There is a minimum of 1% at either end.
-- FUNCTION: public.perc_position(double precision)
-- DROP FUNCTION public.perc_position(double precision);
CREATE OR REPLACE FUNCTION public.perc_position(
	fraction double precision)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE SECURITY DEFINER 
AS $BODY$
BEGIN
	IF $1 <= 0.01 THEN
    	RETURN 'top 1%';
	ELSIF $1 <= 0.5 THEN
    	RETURN 'top'||TO_CHAR(100*fraction,'99')||'%';
    ELSIF $1 >= 0.99 THEN
    	RETURN 'bottom 1%';
    ELSE
    	RETURN 'bottom'||TO_CHAR(100*(1-fraction),'99')||'%';
    END IF;
END

$BODY$;

ALTER FUNCTION public.perc_position(double precision)
    OWNER TO database_admin;

COMMENT ON FUNCTION public.perc_position(double precision)
    IS 'Format a percentage as a "top x% or bottom x%" string.';
    
SELECT perc_position(0), perc_position(1), perc_position(0.332), perc_position(0.78);



/*
-- Query to find out the previous trap_lure_added when something is caught.
SELECT 
	email_address,
	street,
	postcode,
	trap_caught,
	LAG(trap_lure_added) OVER w AS previous_trap_lure_added,
	trap_lure_added
FROM reports
WHERE trap_caught IS NOT NULL
WINDOW w AS (PARTITION BY email_address, street, postcode ORDER BY date ASC )
;
*/


-- Normalise the report_submissions table
-- DROP VIEW IF EXISTS reports CASCADE;
CREATE OR REPLACE VIEW reports AS 
SELECT
	r.id, 
	date,
	email_address,
	project,
    street_number,
	-- apply any correction in table corrected_suspicious_streets
	CASE WHEN c.original_street IS NOT NULL THEN c.corrected_street ELSE normalise_street(street) END AS street,
	street original_street,
	CASE WHEN c.original_postcode IS NOT NULL THEN c.corrected_postcode ELSE postcode END AS postcode,
	minutes,
	trap_checked,
	trap_reset,
	CASE WHEN trap_lure_added = 'None' THEN NULL ELSE trap_lure_added END AS trap_lure_added,
	CASE WHEN trap_caught = 'Nothing' THEN NULL ELSE trap_caught END AS trap_caught,
	bait_checked,
	bait_taken,
	CASE WHEN bait_added = 'None' THEN NULL ELSE bait_added END AS bait_added,
	submitted_at,
	r.created_at,
	submission_id,
	form_id,
	ip_address	 
FROM report_submissions r
LEFT JOIN corrected_suspicious_streets c ON r.street = c.original_street AND r.postcode = c.original_postcode;


-- SELECT * FROM reports;


DROP VIEW IF EXISTS reports_for_export CASCADE;
CREATE OR REPLACE VIEW reports_for_export AS
SELECT
	id, 
	date,
	project,
	street_number,
	street,
	postcode,
	minutes,
	trap_checked,
	trap_reset,
	trap_lure_added,
	trap_caught,
	bait_checked,
	bait_taken,
	bait_added,
	submitted_at	 
FROM
	reports;

-- what did each member last do?
DROP VIEW IF EXISTS members_last_reports;
CREATE OR REPLACE VIEW members_last_reports AS SELECT 
	*
FROM (
	SELECT 
		email_address,
		FIRST_VALUE(project) OVER w AS last_project,
		FIRST_VALUE(street_number) OVER w as last_street_number,
		FIRST_VALUE(street) OVER w AS last_street,
		FIRST_VALUE(postcode) OVER w AS last_postcode,
		FIRST_VALUE(date) OVER w AS last_date,
		FIRST_VALUE(trap_checked) OVER w AS last_trap_checked,
		FIRST_VALUE(bait_checked) OVER w AS last_bait_checked,
		FIRST_VALUE(minutes) OVER w AS last_minutes
	FROM 
		reports
	WINDOW w AS (
		PARTITION BY email_address
		ORDER BY submitted_at DESC
	) 
) s
GROUP BY 
	email_address,
	last_project,
	last_street_number,
	last_street,
	last_postcode,
	last_date,
	last_trap_checked,
	last_bait_checked,
	last_minutes;