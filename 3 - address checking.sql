

-- FUNCTION: public.is_suspicious_street(character varying)
/* This returns streets which don't have Rd, St etc. in them. 
   Note this doesn't work in HeidiSQL, run it in pgAdmin.*/
-- DROP FUNCTION public.is_suspicious_street(character varying);

CREATE OR REPLACE FUNCTION public.is_suspicious_street(
	street character varying)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
BEGIN

	RETURN SUBSTRING(street FROM '[\\w\\s]*(?:Rd|St|Cr|Tce|Ln|Ave|Pl|Pde|Quay)(?: North| South| East| West)?$') IS NULL;
END

$BODY$;

ALTER FUNCTION public.is_suspicious_street(character varying)
    OWNER TO database_admin;



-- Table: public.corrected_suspicious_streets

-- DROP TABLE public.corrected_suspicious_streets;

CREATE TABLE public.corrected_suspicious_streets
(
    id integer NOT NULL DEFAULT nextval('corrected_suspicious_streets_id_seq'::regclass),
    original_street character varying(80) COLLATE pg_catalog."default" NOT NULL,
    original_postcode character varying(10) COLLATE pg_catalog."default" NOT NULL,
    corrected_street character varying(80) COLLATE pg_catalog."default" NOT NULL,
    corrected_postcode character varying(10) COLLATE pg_catalog."default" NOT NULL,
    created_by character varying(60) COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT corrected_suspicious_streets_pkey PRIMARY KEY (id)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.corrected_suspicious_streets
    OWNER to database_admin;
GRANT ALL ON TABLE public.corrected_suspicious_streets TO database_admin;
GRANT ALL ON TABLE public.corrected_suspicious_streets TO PUBLIC;



-- View: public.suspicious_streets
/* Lists all the originally entered streets which fail is_suspicious_street(), alongside any correction.*/
-- View: public.suspicious_streets

-- DROP VIEW public.suspicious_streets;
CREATE OR REPLACE VIEW public.suspicious_streets AS
SELECT 
	MIN(r.id) AS first_id,
	r.original_street as original_street,
	r.street as normalised_street,
	r.postcode as original_postcode,
	r.email_address,
	c.corrected_street,
	c.corrected_postcode
FROM reports r
LEFT JOIN corrected_suspicious_streets c ON r.original_street = c.original_street AND r.postcode = c.original_postcode
WHERE is_suspicious_street(normalise_street(r.original_street))
GROUP BY 
	r.original_street, 
	r.street, 
	r.postcode, 
	r.email_address,
	c.corrected_street,
	c.corrected_postcode
ORDER BY
	first_id ASC;


ALTER TABLE public.suspicious_streets
    OWNER TO database_admin;

GRANT ALL ON TABLE public.suspicious_streets TO database_admin;
GRANT ALL ON TABLE public.suspicious_streets TO PUBLIC;

-- SELECT * FROM suspicious_streets ORDER BY first_id;
