CREATE OR REPLACE FUNCTION public.sp_liquidacionfinalanualf1357(esfinal boolean, anio character varying, p_mes character varying)
 RETURNS TABLE(legajo text, totalremuneraciones numeric, totaldeduccionesgenerales numeric, totaldeduccionespersonales numeric, totalimpuestodeterminado numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
DECLARE
	-- Constantes
	C_ZEROS CONSTANT VARCHAR := '000000000000000000000000000000000000';
	mes CONSTANT VARCHAR := RIGHT(C_ZEROS || mes,2);
RETURN QUERY
	
with tablaLegajosIDs as(
	SELECT legajoid
	FROM liquidacion l
	INNER JOIN liquidaciontipo lt ON l.tipoid = lt.id
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND lt.id = -6 AND to_char(l.fechaperiodoliquidacion,'MM') = mes) OR (not esfinal AND lt.id != -6  AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes))
	GROUP BY legajoid
),
tmp_totalRemuneraciones as (
	SELECT l.id as liquidacionid, a.importe AS totalremuneraciones 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'TOTAL_REMUNERACIONES'
),
tmp_totalDeduccionesGenerales as (
	SELECT l.id as liquidacionid, a.importe AS totaldeduccionesgenerales 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_DEDUCCIONES_GENERALES'
),
tmp_totalDeduccionesPersonales as (
	SELECT l.id as liquidacionid, a.importe AS totaldeduccionespersonales 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_DEDUCCIONES_PERSONALES_ANUAL'
),
tmp_totalImpuestoDeterminado as (
	SELECT l.id as liquidacionid, a.importe AS totalimpuestodeterminado 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SALDO_A_PAGAR'
)

SELECT le.cuil ||' - '|| le.nombre ||' - '|| le.apellido AS legajo,
coalesce(round(ttr.totalremuneraciones,2), 0.00) AS totalremuneraciones,
coalesce(round(ttdg.totaldeduccionesgenerales,2), 0.00) AS totaldeduccionesgenerales,
coalesce(round(ttdp.totaldeduccionespersonales,2), 0.00) AS totaldeduccionespersonales,
coalesce(round(ttid.totalimpuestodeterminado,2), 0.00) AS totalimpuestodeterminado
FROM legajo le
INNER JOIN tablaLegajosIDs tl on le.id = tl.legajoid
INNER JOIN liquidacion l ON l.legajoid = tl.legajoid
INNER JOIN tmp_totalRemuneraciones ttr ON ttr.liquidacionid = l.id
INNER JOIN tmp_totalDeduccionesGenerales ttdg ON ttdg.liquidacionid = l.id 
INNER JOIN tmp_totalDeduccionesPersonales ttdp ON ttdp.liquidacionid = l.id
INNER JOIN tmp_totalImpuestoDeterminado ttid ON ttid.liquidacionid = l.id
WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes))
GROUP BY l.legajoid,le.cuil,le.nombre,le.apellido,ttr.totalremuneraciones,ttdg.totaldeduccionesgenerales, ttdp.totaldeduccionespersonales,ttid.totalimpuestodeterminado;
END; 
$function$;
