CREATE OR REPLACE FUNCTION public.sp_librosueldosdigital(tipoliquidacion character varying, periodoliquidacion date)
 RETURNS TABLE(legajo text, apellido text, nombre text, fechaperiodoliquidacion timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN	
	RETURN QUERY 		
	 SELECT le.legajo, le.apellido, le.nombre, l.fechaperiodoliquidacion::timestamp
	 FROM liquidacion l
     INNER JOIN liquidaciontipo lt ON l.tipoid = lt.id
	 INNER JOIN legajo le on l.legajoid = le.id
	 WHERE lt.codigo = tipoliquidacion AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD');
END;
$function$
;
