-- This file contains the entities for managing stories in the reminder emails.

-- Projects ---------------------------------

-- Table: public.projects
-- DROP TABLE public.projects;
CREATE TABLE public.projects
(
    id integer NOT NULL DEFAULT nextval('projects_id_seq'::regclass),
    name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    abbreviation character varying(10) COLLATE pg_catalog."default" NOT NULL,
    logo_url character varying(200) COLLATE pg_catalog."default",
    email_address character varying(50) COLLATE pg_catalog."default" NOT NULL,
    pin integer NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    enabled boolean NOT NULL DEFAULT true,
    coordinator_first_name character varying(40) COLLATE pg_catalog."default" NOT NULL,
    coordinator_last_name character varying(40) COLLATE pg_catalog."default" NOT NULL,
    coordinator_phone character varying(12) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT projects_pkey PRIMARY KEY (id),
    CONSTRAINT unq_name UNIQUE (name)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.projects
    OWNER to database_admin;

GRANT ALL ON TABLE public.projects TO database_admin;
GRANT ALL ON TABLE public.projects TO PUBLIC;


-- Table: public.project_postcodes

-- DROP TABLE public.project_postcodes;

CREATE TABLE public.project_postcodes
(
    project integer NOT NULL,
    postcode character varying(10) COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT fk_project_postcodes_project_id FOREIGN KEY (project)
        REFERENCES public.projects (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.project_postcodes
    OWNER to database_admin;

GRANT ALL ON TABLE public.project_postcodes TO database_admin;
GRANT ALL ON TABLE public.project_postcodes TO PUBLIC;


-- Stories ---------------------------------------

-- Table: public.stories

-- DROP TABLE public.stories;

CREATE TABLE public.stories
(
    id integer NOT NULL DEFAULT nextval('stories_id_seq'::regclass),
    project integer,
    title character varying(100) COLLATE pg_catalog."default" NOT NULL,
    text text COLLATE pg_catalog."default" NOT NULL,
    image_url character varying(255) COLLATE pg_catalog."default" NOT NULL,
    more_info_url character varying(255) COLLATE pg_catalog."default" NOT NULL,
    created_at timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT stories_pkey PRIMARY KEY (id),
    CONSTRAINT fk_stories_projects FOREIGN KEY (project)
        REFERENCES public.projects (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE SET NULL
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.stories
    OWNER to database_admin;

GRANT ALL ON TABLE public.stories TO database_admin;
GRANT ALL ON TABLE public.stories TO PUBLIC;

-- view for the latest stories for every project
CREATE OR REPLACE VIEW latest_stories AS
SELECT 
	s.id,
	project as project,
	name AS project_name,
	title,
	text,
	image_url,
	more_info_url,
	s.created_at,
	p.email_address AS project_email_address,
	logo_url AS project_logo_url
FROM
	(
	SELECT
		*,
		RANK() OVER (PARTITION BY project ORDER BY created_at DESC) AS rank
	FROM 
		stories
	) s
LEFT JOIN
	projects p ON s.project = p.id
WHERE
	s.rank = 1;

-- TURP 2.5 using WordPress to manage Projects and Stories -----------------------------------------------------
	
-- View with latest revisions of every Project
CREATE OR REPLACE VIEW latest_project_revisions AS 
SELECT 
	DISTINCT ON (project_id) 
	* 
FROM 
	project_revisions 
ORDER BY 
	project_id, 
	created_at DESC;



-- View with latest revisions of every Story
-- DROP VIEW latest_story_revisions CASCADE;
CREATE OR REPLACE VIEW latest_story_revisions AS 
SELECT 
	s.id AS revision_id,
	p.project_id AS project_id,
	p.title AS project_name,
	logo_url AS project_logo_url,
	contact AS project_contact,
	contact_email AS project_email_address,
	story_id,
	story_title AS title,
	story_content AS text,
	story_image_url AS image_url,
	story_url AS more_info_url,
	s.created_at
FROM 
	latest_project_revisions p
LEFT JOIN (
	SELECT 
		DISTINCT ON (project_id)
		*
	FROM
		story_revisions
	ORDER BY 
		project_id, 
		created_at DESC
) AS s
ON p.project_id = s.project_id;