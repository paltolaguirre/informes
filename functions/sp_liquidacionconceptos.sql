-- Function: sp_liquidacionconceptos()

-- DROP FUNCTION sp_liquidacionconceptos();

CREATE OR REPLACE FUNCTION sp_liquidacionconceptos()
  RETURNS TABLE(id integer, conceptoid integer, importeunitario numeric, liquidacionid integer) AS
$BODY$
BEGIN	
	RETURN QUERY 			

	 SELECT retencion.id,
	    retencion.conceptoid,
	    retencion.importeunitario,
	    retencion.liquidacionid
	   FROM retencion
	UNION ALL
	 SELECT descuento.id,
	    descuento.conceptoid,
	    descuento.importeunitario,
	    descuento.liquidacionid
	   FROM descuento
	UNION ALL
	 SELECT importeremunerativo.id,
	    importeremunerativo.conceptoid,
	    importeremunerativo.importeunitario,
	    importeremunerativo.liquidacionid
	   FROM importeremunerativo
	UNION ALL
	 SELECT importenoremunerativo.id,
	    importenoremunerativo.conceptoid,
	    importenoremunerativo.importeunitario,
	    importenoremunerativo.liquidacionid
	   FROM importenoremunerativo;

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_liquidacionconceptos()
  OWNER TO postgres;
