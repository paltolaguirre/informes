-- Function: sp_informelibrosueldos(date,date)

-- DROP FUNCTION sp_informelibrosueldos(date,date);

CREATE OR REPLACE FUNCTION sp_informelibrosueldos(fechadesde date, fechahasta date )
  RETURNS TABLE(
   fechaliquidacion timestamp,
   legajo text,
   nombre text,
   apellido text,
   periodo timestamp,
   total numeric
  )AS
$BODY$
BEGIN	

	RETURN QUERY 	

	 WITH tmp_importeliquidacion AS (
		SELECT li.id as liquidacionid, 0::numeric as importeLiquidacion
		FROM Liquidacion li
		LEFT JOIN Liquidacionitem liqitem ON li.id = liqitem.liquidacionid
		WHERE li.fecha BETWEEN fechadesde AND fechahasta
		GROUP BY li.id
	)

	 
	 SELECT li.fecha::timestamp as fechaLiquidacion,l.legajo as Legajo ,l.nombre as Nombre, l.apellido as Apellido, li.fechaperiodoliquidacion::timestamp as periodo ,importeLiquidacion as total
	 FROM liquidacion li
	 LEFT JOIN legajo l ON l.id = li.legajoid
	 LEFT JOIN tmp_importeliquidacion il ON il.liquidacionid = li.id
	 WHERE li.fecha BETWEEN fechadesde AND fechahasta
	 ORDER BY li.fecha;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_informelibrosueldos(date,date)
  OWNER TO postgres;



