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

	WITH tmp_conceptosRetencionesAportesPatronales AS (
		SELECT liqitem.id as id, liqitem.conceptoid as conceptoid, liqitem.importeunitario as importeunitario, liqitem.liquidacionid as liquidacionid, c.nombre as nombreconcepto
		FROM Liquidacion li
		LEFT JOIN Liquidacionitem liqitem ON li.id = liqitem.liquidacionid
		INNER JOIN concepto c ON liqitem.conceptoid = c.id
		WHERE c.tipoconceptoid = -4 OR c.tipoconceptoid = -5 
		GROUP BY li.id, liqitem.id, c.nombre
	)
  
	 SELECT tcrap.nombreconcepto, sum(importeunitario) as importe
	 FROM liquidacion l
	 LEFT JOIN tmp_conceptosRetencionesAportesPatronales tcrap ON tcrap.liquidacionid = l.id
	 WHERE l.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta
	 GROUP BY tcrap.nombreconcepto, tcrap.conceptoid;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informef931(date,date)
  OWNER TO postgres;

	

