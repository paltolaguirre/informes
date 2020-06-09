CREATE OR REPLACE FUNCTION sp_exportartxtlibrosueldosdigitalliquidacionesperiodoregistrodos(esmensual boolean, periodoliquidacion date)
 RETURNS TABLE(data text)
 LANGUAGE plpgsql
AS $function$
DECLARE
	-- Constantes
	C_ZEROS CONSTANT VARCHAR := '000000000000000000000000000000000000';	
   	C_ESPACIOS CONSTANT VARCHAR := '                                                                        ';

BEGIN	
	DROP TABLE IF EXISTS tt_FINAL;

	CREATE TEMP TABLE tt_FINAL AS

	WITH tmp_LiquidacionLegajo AS(
		SELECT l.id AS liquidacionid,le.cuil AS cuil,le.legajo AS legajo,le.cbu AS cbu, l.condicionpagoid AS condicionpago, l.fechaperiodoliquidacion AS fechaperiodoliquidacion
		FROM liquidacion l
		INNER JOIN legajo le ON l.legajoid = le.id 
		INNER JOIN liquidaciontipo lt on l.tipoid = lt.id
		WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD')	
	)

	SELECT
	'02'::VARCHAR AS RegistroDos,
	RIGHT(C_ZEROS || REPLACE(coalesce(tll.cuil,''),'-',''), 11)::VARCHAR AS CuilRegistroDos, 
	RIGHT(C_ESPACIOS || coalesce(tll.legajo,''), 10)::VARCHAR AS LegajoRegistroDos, 
	REPEAT(' ', 50)::VARCHAR AS DependenciaRevistaRegistroDos,
	RIGHT(C_ESPACIOS || coalesce(tll.cbu,''), 22)::VARCHAR AS CbuRegistroDos,
	REPEAT('0', 3)::VARCHAR AS CantDiasParaTopeRegistroDos,
	RIGHT(C_ZEROS || coalesce(to_char(tll.fechaperiodoliquidacion , 'YYYY') || to_char(tll.fechaperiodoliquidacion , 'MM') || to_char(tll.fechaperiodoliquidacion , 'DD'),''),8)::VARCHAR AS FechaPagoRegistroDos,
	RIGHT(C_ESPACIOS || '0', 8)::VARCHAR AS FechaRubricaRegistroDos,
    CASE WHEN tll.condicionpago = -1  THEN '3' ELSE '1' END AS FormaPagoRegistroDos
	
	FROM Liquidacion l
	INNER JOIN Liquidaciontipo lt on lt.id = l.tipoid
	LEFT JOIN tmp_LiquidacionLegajo tll ON l.id = tll.liquidacionid
	WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD');	

	RETURN QUERY
		SELECT (	
			tt_FINAL.RegistroDos || 
			tt_FINAL.CuilRegistroDos || 
			tt_FINAL.LegajoRegistroDos || 
			tt_FINAL.DependenciaRevistaRegistroDos ||
			tt_FINAL.CbuRegistroDos ||
			tt_FINAL.CantDiasParaTopeRegistroDos ||
			tt_FINAL.FechaPagoRegistroDos ||
			tt_FINAL. FechaRubricaRegistroDos ||
			tt_FINAL.FormaPagoRegistroDos
	) AS data
		FROM tt_FINAL;
	

END; $function$;