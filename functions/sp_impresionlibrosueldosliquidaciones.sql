-- Function: SP_IMPRESIONLIBROSUELDOSLIQUIDACIONES(date,date)

-- DROP FUNCTION SP_IMPRESIONLIBROSUELDOSLIQUIDACIONES(date,date);

CREATE OR REPLACE FUNCTION SP_IMPRESIONLIBROSUELDOSLIQUIDACIONES(fechadesde date, fechahasta date )
  RETURNS TABLE(
   liquidacionid integer,
   legajo text,
   apellidonombre text,
   cuil text,
   direccion text,
   fechaalta timestamp,
   fechabaja timestamp,
   categoria text,
   sueldojornal numeric,
   sueldoperiodo timestamp,
   contratacion text,
   conceptonombre text,
   conceptoimporte numeric,
   tipogrilla text
  )AS
$BODY$
BEGIN	

	RETURN QUERY 	
		
	SELECT 
	li.id as liquidacionid,
	coalesce(l.legajo, '') as Legajo,
	coalesce(l.apellido || ' ' || l.nombre, '') as Apellidonombre,
	coalesce(l.cuil,'') as Cuil,
	coalesce(l.direccion,'') as Direccion,
	l.fechaalta::timestamp as Fechaalta,
	l.fechabaja::timestamp as Fechabaja,
	coalesce(l.categoria,'') as Categoria,
	coalesce(l.remuneracion, 0.00) as Sueldojornal,
	li.fechaperiodoliquidacion::timestamp as Sueldoperiodo,
	coalesce(mc.nombre, '') as Contratacion,
	coalesce(c.nombre,'') as Conceptonombre,
	coalesce( spliquidacion.importeunitario, 0.00) as Conceptoimporte,
	spliquidacion.tipogrilla as Tipogrilla
	FROM Liquidacion li 
	INNER JOIN SP_LIQUIDACIONCONCEPTOS() spliquidacion ON li.id = spliquidacion.liquidacionid
	INNER JOIN Legajo l ON li.legajoid = l.id
	LEFT JOIN Concepto c ON spliquidacion.conceptoid = c.id
	LEFT JOIN Modalidadcontratacion mc ON l.modalidadcontratacionid = mc.id
	WHERE li.fecha BETWEEN fechadesde AND fechahasta
	ORDER BY li.id,spliquidacion.tipogrilla;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION SP_IMPRESIONLIBROSUELDOSLIQUIDACIONES(date,date)
  OWNER TO postgres;


