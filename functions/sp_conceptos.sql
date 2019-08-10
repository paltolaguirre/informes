-- Function: sp_conceptos()

-- DROP FUNCTION sp_conceptos();

CREATE OR REPLACE FUNCTION sp_conceptos()
  RETURNS TABLE(id integer, nombre text) AS
$BODY$
BEGIN	
	RETURN QUERY 			

	 SELECT public.concepto.id,
		public.concepto.nombre
		
	   FROM public.concepto
		 WHERE esimprimible = 1
	
	UNION ALL

	SELECT concepto.id,
	       concepto.nombre
	FROM concepto
	WHERE esimprimible = 1;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_conceptos()
  OWNER TO postgres;