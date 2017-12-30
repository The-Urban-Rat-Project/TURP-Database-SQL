-- Trigger is used by Zapier to run tasks such as refreshing materialized views periodically. 
-- Zapier inserts SQL into this table, which is executed by the stored procedure.

CREATE TABLE IF NOT EXISTS public.zapier_sql (
	id int8 NOT NULL DEFAULT nextval('zapier_triggers_id_seq'::regclass),
	created_at timestamp NOT NULL DEFAULT now(),
	"sql" text NOT NULL,
	zapier_id varchar(30) NOT NULL,
	PRIMARY KEY (id)
)
WITH (
	OIDS=FALSE
) ;

CREATE OR REPLACE FUNCTION public.on_insert_zapier_sql()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$

BEGIN
	-- EXECUTE 'REFRESH MATERIALIZED VIEW ';
    EXECUTE NEW.sql;
    RETURN NULL;
END;

$function$


CREATE TRIGGER on_insert_zapier_sql AFTER INSERT
	ON zapier_sql 
    FOR EACH ROW EXECUTE PROCEDURE on_insert_zapier_sql()