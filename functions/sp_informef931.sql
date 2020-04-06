CREATE OR REPLACE FUNCTION sp_informef931(fechadesde date, fechahasta date)
 RETURNS TABLE(nombre text, importe numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN	
	RETURN QUERY 			

  
	 SELECT c.nombre, sum(importeunitario) as importe
	 FROM liquidacion l
	 LEFT JOIN liquidacionitem li on l.id = li.liquidacionid
	 INNER JOIN concepto c ON li.conceptoid = c.id
	 WHERE (c.tipoconceptoid = -4 OR c.tipoconceptoid = -5 ) and (l.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta)
	 GROUP BY c.id, c.nombre;

END; 
$function$
;
