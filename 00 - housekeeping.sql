-- Trigger is used by Zapier to run tasks such as refreshing materialized views periodically. 
-- Zapier inserts SQL into this table, which is executed by the stored procedure.

CREATE TABLE IF NOT EXISTS public.zapier_sql (
	id int8 NOT NULL DEFAULT nextval('zapier_triggers_id_seq'::regclass),
	created_at timestamp NOT NULL DEFAULT now(),
	"sql" text NOT NULL,
	zapier_id varchar(30) NOT NULL,
	PRIMARY KEY (id)
);

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
    FOR EACH ROW EXECUTE PROCEDURE on_insert_zapier_sql();
    

-- MailChimp membership

CREATE TABLE IF NOT EXISTS public.mailchimp_list_members (
	id varchar(50) NOT NULL,
	list_id varchar(20) NOT NULL,
	email_address varchar(100) NOT NULL,
	pk int2 NOT NULL DEFAULT nextval('mailchimp_list_members_pk_seq'::regclass),
	project varchar(50) NULL,
	status varchar(30) NULL,
	PRIMARY KEY (pk)
);
