CREATE OR REPLACE FUNCTION sp_exportartxtlibrosueldosdigitalliquidacionesperiodoregistrotres(esmensual boolean, periodoliquidacion date)
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

	WITH tmp_LiquidacionConceptos AS(
		SELECT l.id AS liquidacionid,le.cuil AS cuil,c.codigointerno AS codigointernoConcepto,li.cantidad AS cantidadConceptos,li.importeunitario AS importeConcepto,c.tipoconceptoid AS tipoConcepto
		FROM liquidacion l 
		INNER JOIN liquidaciontipo lt on l.tipoid = lt.id
		INNER JOIN legajo le on l.legajoid = le.id
		INNER JOIN liquidacionitem li on li.liquidacionid = l.id
		INNER JOIN concepto c on li.conceptoid = c.id
		WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD')	
	)
	SELECT
	'03'::VARCHAR AS RegistroTres,
	RIGHT(C_ZEROS || REPLACE(coalesce(tlc.cuil,''),'-',''), 11)::VARCHAR AS CuilRegistroTres, 
    LEFT(coalesce(tlc.codigointernoConcepto,0) || C_ESPACIOS , 10)::VARCHAR AS CodigoInternoRegistroTres,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tlc.cantidadConceptos ,2), 0.00)::VARCHAR, '.', ''),5) AS CantidadRegistroTres,
	' '::VARCHAR AS UnidadesRegistroTres,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tlc.importeConcepto,2), 0.00)::VARCHAR, '.', ''), 15) AS ImporteRegistroTres,
	CASE WHEN (tlc.tipoConcepto = -1 OR tlc.tipoConcepto = -2)  THEN 'C' ELSE 'D' END AS DebitoCreditoRegistroTres,
	REPEAT(' ', 6)::VARCHAR AS PeriodoAjusteRegistroTres
	
	FROM Liquidacion l
	INNER JOIN Liquidaciontipo lt on lt.id = l.tipoid
	LEFT JOIN tmp_LiquidacionConceptos tlc ON l.id = tlc.liquidacionid	
	WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD');	

	RETURN QUERY
		SELECT (	
			tt_FINAL.RegistroTres ||
			tt_FINAL.CuilRegistroTres || 
			tt_FINAL.CodigoInternoRegistroTres ||
			tt_FINAL.CantidadRegistroTres ||
			tt_FINAL.UnidadesRegistroTres ||
			tt_FINAL.ImporteRegistroTres ||
			tt_FINAL.DebitoCreditoRegistroTres ||
			tt_FINAL.PeriodoAjusteRegistroTres
	) AS data
		FROM tt_FINAL;
	

END; $function$;