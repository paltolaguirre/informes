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

  WITH tmp_conceptosRetencionesAportesPatronales AS(
      SELECT retencion.id as id,
	    retencion.conceptoid as conceptoid,
	    retencion.importeunitario as importeunitario,
	    retencion.liquidacionid as liquidacionid, 
			'1' as tipogrilla
	   FROM retencion
	   UNION ALL
	   SELECT aportepatronal.id as id,
	   aportepatronal.conceptoid as conceptoid,
	   aportepatronal.importeunitario as importeunitario,
	   aportepatronal.liquidacionid as liquidacionid,
			'5' as tipogrilla 
	   FROM aportepatronal
	)

	 SELECT c.nombre, sum(importeunitario) as importe
	 FROM liquidacion l
	 LEFT JOIN tmp_conceptosRetencionesAportesPatronales tcrap ON tcrap.liquidacionid = l.id
	 INNER JOIN concepto c ON tcrap.conceptoid = c.id
	 WHERE l.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta
	 GROUP BY c.nombre, c.id;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informef931(date,date)
  OWNER TO postgres;

	

