-- Function: sp_informelibrosueldos(date,date)

-- DROP FUNCTION sp_informelibrosueldos(date,date);

CREATE OR REPLACE FUNCTION sp_informelibrosueldos(fechadesde date, fechahasta date )
  RETURNS TABLE(
   legajo text,
   fecha timestamp,
   concepto text,
   importe numeric
  )AS
$BODY$
BEGIN	
	RETURN QUERY 	
			
	 SELECT le.legajo,l.fecha::timestamp,c.nombre, importeunitario
	 FROM liquidacion l
	 LEFT JOIN legajo le ON le.id = l.legajoid
	 LEFT JOIN sp_liquidacionconceptos() lc ON lc.liquidacionid = l.id
	 LEFT JOIN sp_conceptos() c ON lc.conceptoid = c.id
	 WHERE l.fecha BETWEEN fechadesde AND fechahasta
	 ORDER BY le.nombre, l.fecha;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informelibrosueldos(date,date)
  OWNER TO postgres;



