CREATE OR REPLACE FUNCTION sp_exportartxtlibrosueldosdigitalliquidacionesperiodoregistrocuatro(correspondereduccion character varying, tipoempresa character varying, actividad character varying,zona character varying, esmensual boolean, periodoliquidacion date,importedetraccion numeric)
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

	WITH tmp_cantHijos AS (
		SELECT count(h.id) as cantidadHijos, l.id as legajoid
		FROM Legajo l
		INNER JOIN Hijo h ON h.legajoid = l.id
		GROUP BY l.id
	),
	
	tmp_cantConyuge AS (
		SELECT count(c.id) as cantidadConyuge, l.id as legajoid
		FROM Legajo l
		INNER JOIN Conyuge c ON c.legajoid = l.id
		GROUP BY l.id
	),
	tmp_situacionRevista AS (
		SELECT l.id AS liquidacionid ,suno.codigo AS situacionrevistauno,sdos.codigo AS situacionrevistados,stres.codigo AS situacionrevistatres
		FROM liquidacion l
		INNER JOIN Liquidaciontipo lt ON l.tipoid = lt.id
		LEFT JOIN situacion suno ON l.situacionrevistaunoid = suno.id 
		LEFT JOIN situacion sdos ON l.situacionrevistadosid = sdos.id 
		LEFT JOIN situacion stres ON l.situacionrevistatresid = stres.id
        WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD')
		GROUP BY l.id,suno.codigo,sdos.codigo,stres.codigo
	),
	tmp_cantidadadherentes AS(
		SELECT legajoid as legajoid, count(legajoid) as cantidadadherentes
		FROM legajo 
		INNER JOIN Hijo adherentes on legajo.id = adherentes.legajoid 
		WHERE legajo.obrasocialid = adherentes.obrasocialid 
		GROUP BY legajoid-- and legajoid = 'xxx'
	),
	tmp_importesRemunerativos AS(
		SELECT l.id as liquidacionid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeRemunerativo
		FROM Liquidacion l
		INNER JOIN Liquidaciontipo lt ON l.tipoid = lt.id
		INNER JOIN Legajo le ON l.legajoid = le.id
		LEFT JOIN Liquidacionitem liqit ON l.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD') AND (c.tipoconceptoid = -1)
		GROUP BY l.id
	),

		tmp_importesNoRemunerativos AS(
		SELECT l.id as liquidacionid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeNoRemunerativo
		FROM Liquidacion l
		INNER JOIN Liquidaciontipo lt ON l.tipoid = lt.id
		INNER JOIN Legajo le ON l.legajoid = le.id
		LEFT JOIN Liquidacionitem liqit ON l.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD') AND (c.tipoconceptoid = -2)
		GROUP BY l.id
	),

		tmp_importesDescuentos AS(
		SELECT l.id as liquidacionid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeDescuento
		FROM Liquidacion l
		INNER JOIN Liquidaciontipo lt ON l.tipoid = lt.id
		INNER JOIN Legajo le ON l.legajoid = le.id
		LEFT JOIN Liquidacionitem liqit ON l.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD') AND (c.tipoconceptoid = -3)
		GROUP BY l.id
	)
    
	SELECT
	'04'::VARCHAR AS RegistroCuatro,
	RIGHT(C_ZEROS || REPLACE(coalesce(le.cuil,''),'-',''), 11)::VARCHAR AS CuilRegistroCuatro,
	RIGHT(C_ZEROS ||  coalesce(co.cantidadConyuge,0),1) AS CantidadConyuge,
	RIGHT(C_ZEROS || coalesce(h.cantidadHijos,0), 2) AS CantidadHijos,
	CASE WHEN le.incluidoencct  THEN '1' ELSE '0' END AS MarcaCCT,
	CASE WHEN le.correspondescvo  THEN '1' ELSE '0' END AS CorrespondeSCVO,
	CASE WHEN correspondereduccion = '1'  THEN '1' ELSE '0' END AS CorrespondeReduccion,
	tipoempresa:: VARCHAR AS TipoEmpresa, 
	'0'::VARCHAR AS TipoOperacion,
	RIGHT(C_ZEROS || coalesce(s.Codigo,''), 2) AS CodigoSituacion,
	RIGHT(C_ESPACIOS || coalesce(cond.Codigo,''), 2) AS CodigoCondicion,
	RIGHT(C_ZEROS || coalesce(actividad,''), 3) AS CodigoActividad, 
	RIGHT(C_ESPACIOS || coalesce(mc.Codigo,'') , 3) AS CodigoModalidadContratacion,
	RIGHT(C_ESPACIOS || coalesce(cs.Codigo,''), 2) AS CodigoSiniestrado,
	RIGHT(C_ZEROS || coalesce(zona,''), 2) AS CodigoZona, 
	RIGHT(C_ZEROS || coalesce(tsr.situacionrevistauno,''), 2) AS SituacionRevista1,
	RIGHT(C_ZEROS || coalesce(to_char(l.fechasituacionrevistauno,'DD'),''), 2) AS DiaInicioSituacionRevista1,
	RIGHT(C_ZEROS || coalesce(tsr.situacionrevistados,''), 2) AS SituacionRevista2,
	RIGHT(C_ZEROS || coalesce(to_char(l.fechasituacionrevistados,'DD'),''), 2) AS DiaInicioSituacionRevista2,
	RIGHT(C_ZEROS || coalesce(tsr.situacionrevistatres,''), 2) AS SituacionRevista3,
	RIGHT(C_ZEROS || coalesce(to_char(l.fechasituacionrevistatres,'DD'),''), 2) AS DiaInicioSituacionRevista3,
	RIGHT(C_ZEROS || coalesce(l.cantidaddiastrabajados,0), 2) AS CantidadDiasTrabajados,
	REPEAT('0', 3)::VARCHAR AS HorasTrabajadas,
	REPEAT('0',5)::VARCHAR AS PorcentajeAporteAdicionalSS,
	REPEAT('0',5)::VARCHAR AS ContribucionTareaDiferencial,
	RIGHT(C_ZEROS || coalesce(os.Codigo,''), 6) AS CodigoObraSocial,
	RIGHT(C_ZEROS || coalesce(tca.cantidadadherentes,0), 2) AS CantidadAdherentes,
	REPEAT('0',15)::VARCHAR AS AporteAdicionalOS,
	REPEAT('0',15)::VARCHAR AS ContribucionAdicionalOS,
	REPEAT('0',15)::VARCHAR AS BaseCalculoDiferencialAportesOSyFSR,
	REPEAT('0',15)::VARCHAR AS BaseCalculoDiferencialOSyFSR,
	REPEAT('0',15)::VARCHAR AS BaseCalculoDiferencialLRT,
	REPEAT('0',15)::VARCHAR AS RemuneracionMaternidadANSeS,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) + coalesce(inr.importeNoRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS RemuneracionBruta,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible1,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible2,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible3,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible4,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible5,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible6,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible7,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible8,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) + coalesce(inr.importeNoRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible9,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseCalculoDiferencialAporteSegSocial,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseCalculoDiferencialContribucionesSegSocial,
	RIGHT(C_ZEROS || REPLACE(coalesce(round((coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00)) - coalesce(importedetraccion,0.00),2), 0.00)::VARCHAR, '.', ','), 15) AS BaseImponible10,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(importedetraccion,2), 0.00)::VARCHAR, '.', ','), 15) AS ImporteDetraccion
	FROM Liquidacion l
	INNER JOIN Liquidaciontipo lt ON lt.id = l.tipoid
    INNER JOIN Legajo le ON le.id = l.legajoid
    LEFT JOIN tmp_cantConyuge co ON co.legajoid = le.id
	LEFT JOIN tmp_cantHijos h ON h.legajoid = le.id
	LEFT JOIN Condicion cond ON le.condicionid = cond.id
	LEFT JOIN CondicionSiniestrado cs ON le.condicionsiniestradoid = cs.id
	LEFT JOIN Situacion s ON le.situacionid = s.id
	LEFT JOIN tmp_situacionRevista tsr ON l.id = tsr.liquidacionid
	LEFT JOIN ModalidadContratacion mc ON le.modalidadcontratacionid = mc.id
	LEFT JOIN ObraSocial os ON le.obrasocialid = os.id
	LEFT JOIN tmp_cantidadadherentes tca  ON tca.legajoid = le.id
	LEFT JOIN tmp_importesRemunerativos ir ON ir.liquidacionid = l.id
	LEFT JOIN tmp_importesNoRemunerativos inr ON inr.liquidacionid = l.id
	LEFT JOIN tmp_importesDescuentos id ON id.liquidacionid = l.id 	
	WHERE ((esmensual AND lt.id in (-1,-5,-6)) or (not esmensual AND lt.id in (-2,-3,-4)))  AND  to_char(l.fechaperiodoliquidacion, 'YYYY') = to_char(periodoliquidacion, 'YYYY') and to_char(l.fechaperiodoliquidacion, 'MM') = to_char(periodoliquidacion, 'MM') and to_char(l.fechaperiodoliquidacion, 'DD') = to_char(periodoliquidacion, 'DD');	

	RETURN QUERY
		SELECT (	
			tt_FINAL.RegistroCuatro ||
			tt_FINAL.CuilRegistroCuatro ||
			tt_FINAL.CantidadConyuge ||
			tt_FINAL.CantidadHijos ||
			tt_FINAL.MarcaCCT ||
			tt_FINAL.CorrespondeSCVO ||
			tt_FINAL.CorrespondeReduccion ||
			tt_FINAL.TipoEmpresa || 
			tt_FINAL.TipoOperacion ||
			tt_FINAL.CodigoSituacion ||
			tt_FINAL.CodigoCondicion ||
			tt_FINAL.CodigoActividad || 
			tt_FINAL.CodigoModalidadContratacion ||
			tt_FINAL.CodigoSiniestrado ||
			tt_FINAL.CodigoZona || 
			tt_FINAL.SituacionRevista1 ||
			tt_FINAL.DiaInicioSituacionRevista1 ||
			tt_FINAL.SituacionRevista2 ||
			tt_FINAL.DiaInicioSituacionRevista2 ||
			tt_FINAL.SituacionRevista3 ||
			tt_FINAL.DiaInicioSituacionRevista3 ||
			tt_FINAL.CantidadDiasTrabajados ||
			tt_FINAL.HorasTrabajadas ||
			tt_FINAL.PorcentajeAporteAdicionalSS ||
			tt_FINAL.ContribucionTareaDiferencial ||
			tt_FINAL.CodigoObraSocial ||
			tt_FINAL.CantidadAdherentes ||
			tt_FINAL.AporteAdicionalOS ||
			tt_FINAL.ContribucionAdicionalOS ||
			tt_FINAL.BaseCalculoDiferencialAportesOSyFSR ||
			tt_FINAL.BaseCalculoDiferencialOSyFSR ||
			tt_FINAL.BaseCalculoDiferencialLRT ||
			tt_FINAL.RemuneracionMaternidadANSeS ||
			tt_FINAL.RemuneracionBruta ||
			tt_FINAL.BaseImponible1 ||
			tt_FINAL.BaseImponible2 ||
			tt_FINAL.BaseImponible3 ||
			tt_FINAL.BaseImponible4 ||
			tt_FINAL.BaseImponible5 ||
			tt_FINAL.BaseImponible6 ||
			tt_FINAL.BaseImponible7 ||
			tt_FINAL.BaseImponible8 ||
			tt_FINAL.BaseImponible9 ||
			tt_FINAL.BaseCalculoDiferencialAporteSegSocial ||
			tt_FINAL.BaseCalculoDiferencialContribucionesSegSocial ||
			tt_FINAL.BaseImponible10 ||
			tt_FINAL.ImporteDetraccion
	) AS data
		FROM tt_FINAL;
	

END; $function$;