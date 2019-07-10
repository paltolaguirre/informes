-- Function: sp_informelibrosueldos(date,date)

-- DROP FUNCTION sp_informelibrosueldos(date,date);

CREATE OR REPLACE FUNCTION sp_informelibrosueldos(fechadesde date, fechahasta date )
  RETURNS TABLE(
   legajo text,
   fechaperiodoliquidacion timestamp,
   concepto text,
   importe numeric
  )AS
$BODY$
BEGIN	
	RETURN QUERY 	
			
	 SELECT le.legajo,l.fechaperiodoliquidacion::timestamp,c.nombre, importeunitario
	 FROM liquidacion l
	 LEFT JOIN legajo le ON le.id = l.legajoid
	 LEFT JOIN sp_liquidacionconceptos() lc ON lc.id = l.id
	 LEFT JOIN sp_conceptos() c ON lc.conceptoid = c.id
	 WHERE l.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta
	 ORDER BY le.nombre, l.fechaperiodoliquidacion;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informelibrosueldos(date,date)
  OWNER TO postgres;



