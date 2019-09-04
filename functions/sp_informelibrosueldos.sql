-- Function: sp_informelibrosueldos(date,date)

-- DROP FUNCTION sp_informelibrosueldos(date,date);

CREATE OR REPLACE FUNCTION sp_informelibrosueldos(fechadesde date, fechahasta date )
  RETURNS TABLE(
   fecha timestamp,
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
		SELECT li.id as liquidacionid, sum(ir.importeunitario) + sum(inr.importeunitario) - sum(r.importeunitario) -sum(d.importeunitario) as importeLiquidacion
		FROM Liquidacion li
		LEFT JOIN Retencion r ON r.liquidacionid = li.id
		LEFT JOIN Descuento d ON d.liquidacionid = li.id
		LEFT JOIN ImporteRemunerativo ir ON ir.liquidacionid = li.id
		LEFT JOIN ImporteNoRemunerativo inr ON inr.liquidacionid = li.id
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



