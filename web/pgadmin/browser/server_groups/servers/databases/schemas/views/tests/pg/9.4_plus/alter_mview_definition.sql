-- View: public."testmview_$%{}[]()&*^!/@`#"

-- DROP MATERIALIZED VIEW public."testmview_$%{}[]()&*^!/@`#";

CREATE MATERIALIZED VIEW public."testmview_$%{}[]()&*^!/@`#"
TABLESPACE pg_default
AS
 SELECT 12
WITH DATA;

ALTER TABLE public."testmview_$%{}[]()&*^!/@`#"
    OWNER TO postgres;
