-- Function: sp_informef931(date,date)

-- DROP FUNCTION sp_informef931(date,date);

CREATE OR REPLACE FUNCTION sp_informef931(fechadesde date, fechahasta date )
  RETURNS TABLE(
   nombre text,
   importe numeric
  )AS
$BODY$
BEGIN	
	RETURN QUERY 			

	 SELECT c.nombre, sum(importeunitario) as importe
	 FROM liquidacion l
	 LEFT JOIN sp_liquidacionconceptos() lc ON lc.id = l.id
	 LEFT JOIN sp_conceptos() c ON lc.conceptoid = c.id
	 WHERE l.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta
	 GROUP BY c.nombre, c.id;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informef931(date,date)
  OWNER TO postgres;



