CREATE OR REPLACE FUNCTION public.sp_exportartxtcargassocialesf931(fechadesde date, fechahasta date, actividad character varying, tipodeempresa character varying, zona character varying, zonanombre character varying, reducevalor character varying, importedetraccion numeric)
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
	
	tmp_cantidadadherentes AS(
		SELECT legajoid as legajoid, count(legajoid) as cantidadadherentes
		FROM legajo 
		INNER JOIN Hijo adherentes on legajo.id = adherentes.legajoid 
		WHERE legajo.obrasocialid = adherentes.obrasocialid 
		GROUP BY legajoid-- and legajoid = 'xxx'
	),
	
	tmp_importesRemunerativos AS(
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeRemunerativo
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.tipoconceptoid = -1))
		GROUP BY l.id
	),

		tmp_importesNoRemunerativos AS(
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeNoRemunerativo
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.tipoconceptoid = -2))
		GROUP BY l.id
	),

		tmp_importesDescuentos AS(
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeDescuento
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		INNER JOIN Concepto c ON c.id = liqit.conceptoid
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.tipoconceptoid = -3))
		GROUP BY l.id
	),

	tmp_conceptoHoraExtra AS (
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeHorasExtras
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		LEFT JOIN Concepto c ON liqit.conceptoid = c.id
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.nombre = 'Horas Extras 50%' OR c.nombre = 'Horas Extras 100%'))
		GROUP BY l.id
	),
	tmp_conceptoSueldoAnualComplementario AS (
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeSueldoAnualComplementario
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		LEFT JOIN concepto c ON liqit.conceptoid = c.id
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.nombre = 'Sueldo Anual Complementario'))
		GROUP BY l.id
	),
	tmp_conceptoVacaciones AS (
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeVacaciones
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		LEFT JOIN concepto c ON liqit.conceptoid = c.id
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.nombre = 'Vacaciones'))
		GROUP BY l.id
	),
	tmp_cantidadHorasExtras AS (
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.cantidad),0)::INT as cantidadHorasExtras
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		LEFT JOIN Concepto c ON liqit.conceptoid = c.id
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.nombre = 'Horas Extras 50%' OR c.nombre = 'Horas Extras 100%'))
		GROUP BY l.id
	),
	tmp_conceptoIncrementoSalarialDto14_20 AS (
		SELECT l.id as legajoid, 
		coalesce(sum(liqit.importeunitario),0.00) as importeIncrementoSalarialDto14_20
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Liquidacionitem liqit ON li.id = liqit.liquidacionid
		LEFT JOIN concepto c ON liqit.conceptoid = c.id
		WHERE ((li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta) AND (c.nombre = 'Incremento Salarial Dto 14/20'))
		GROUP BY l.id
	)

	SELECT 	
	RIGHT(C_ZEROS || coalesce(l.cuil,''), 11) AS Cuil,
	LEFT(REPLACE(coalesce((l.apellido || ' ' || l.nombre),''), 'ñ', 'n') || C_ESPACIOS, 30) AS NombreApellido,
	CASE WHEN coalesce(co.cantidadConyuge,0) = 0 THEN 'F' ELSE 'T' END AS CantidadConyuge,
	RIGHT(C_ZEROS || coalesce(h.cantidadHijos,0), 2) AS CantidadHijos,
	RIGHT(C_ZEROS || coalesce(s.Codigo,''), 2) AS CodigoSituacion,
	RIGHT(C_ZEROS || coalesce(cond.Codigo,''), 2) AS CodigoCondicion,
	RIGHT(C_ZEROS || coalesce(actividad,''), 3) AS CodigoActividad,
	RIGHT(C_ZEROS || coalesce(zona,''), 2) AS CodigoZona,
	REPEAT('0', 5)::VARCHAR AS PorcentajeAporteAdicionalSS,
	RIGHT(C_ZEROS || coalesce(mc.Codigo,'') , 3) AS CodigoModalidadContratacion,
	RIGHT(C_ZEROS || coalesce(os.Codigo,''), 6) AS CodigoObraSocial,
	RIGHT(C_ZEROS || coalesce(tca.cantidadadherentes,0), 2) AS CantidadAdherentes,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) + coalesce(inr.importeNoRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionTotal,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible1,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS AsignacionesFamiliaresPagadas,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS ImporteAporteVoluntario,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS ImporteAdicionalOS,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS ImporteExcedenteAportesSS,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS ImporteExcedenteAportesOS,
	LEFT(coalesce(zonanombre,'') || C_ESPACIOS, 50) AS ProvinciaLocalidad,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(tcisd.importeIncrementoSalarialDto14_20,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible2,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible3,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible4,
	RIGHT(C_ZEROS || coalesce(cs.Codigo,''), 2) AS CodigoSiniestrado,
	CASE WHEN coalesce(reducevalor,'') = '0' THEN 'F' ELSE 'T' END AS CorrespondeReduccion,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS CapitalRecomposicionLRT,
	RIGHT(C_ZEROS || coalesce(tipodeempresa,''), 1) AS TipoEmpresa,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS AporteAdicionalObraSocial,
	'1'::VARCHAR AS Regimen,
	RIGHT(C_ZEROS || coalesce(s.Codigo,''), 2) AS SituacionRevista1,
	'01'::VARCHAR AS DiaInicioSituacionRevista1,
	REPEAT('0', 2)::VARCHAR AS SituacionRevista2,
	REPEAT('0', 2)::VARCHAR AS DiaInicioSituacionRevista2,
	REPEAT('0', 2)::VARCHAR AS SituacionRevista3,
	REPEAT('0', 2)::VARCHAR AS DiaInicioSituacionRevista3,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(tcisd.importeIncrementoSalarialDto14_20,0.00) - coalesce(tcsac.importeSueldoAnualComplementario,0.00) - coalesce(tche.importeHorasExtras,0.00) - coalesce(id.importeDescuento,0.00) - coalesce(tcv.importeVacaciones,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS SueldoMasAdicionales,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcsac.importeSueldoAnualComplementario,2), 0.00)::VARCHAR, '.', ','), 12) AS Sac,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tche.importeHorasExtras,2), 0.00)::VARCHAR, '.', ','), 12) AS HorasExtras,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 12) AS ZonaDesfavorable,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcv.importeVacaciones,2), 0.00)::VARCHAR, '.', ','), 12) AS Vacaciones,
	RIGHT(C_ZEROS || '30' , 9) AS CantidadDiasTrabajados,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ',') , 12) AS RemuneracionImponible5,
	'0'::VARCHAR AS TrabajadorConvencionado,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ',') , 12) AS RemuneracionImponible6,
	REPEAT('0', 1)::VARCHAR AS TipoOperacion,
	REPEAT('0', 12)::VARCHAR AS Adicionales,
	REPEAT('0', 12)::VARCHAR AS Premios,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible8,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ',') , 12) AS RemuneracionImponible7,
	RIGHT(C_ZEROS || coalesce(tcanthe.cantidadHorasExtras,0), 3) AS CantidadHorasExtras,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(inr.importeNoRemunerativo,2), 0.00)::VARCHAR, '.', ','), 12) AS ConceptosNoRemunerativos,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 12) AS Maternidad,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS RectificacionRemuneracion,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(coalesce(ir.importeRemunerativo,0.00) + coalesce(inr.importeNoRemunerativo,0.00) - coalesce(id.importeDescuento,0.00),2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible9,
	RIGHT(C_ZEROS || REPLACE(0.00::VARCHAR, '.', ','), 9) AS ContribucionTareaDiferencial,
	REPEAT('0', 3)::VARCHAR AS HorasTrabajadas,
	'T'::VARCHAR AS SeguroColectivoDeVidaObligatorio,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(importeDetraccion,2), 0.00)::VARCHAR, '.', ','), 12) AS ImporteDetraccion,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcisd.importeIncrementoSalarialDto14_20,2), 0.00)::VARCHAR, '.', ','), 12) AS IncrementoSalarial,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcisd.importeIncrementoSalarialDto14_20,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible11
	FROM Legajo l
	INNER JOIN Liquidacion li ON li.legajoid = l.id
	LEFT JOIN tmp_cantConyuge co ON co.legajoid = l.id
	LEFT JOIN tmp_cantHijos h ON h.legajoid = l.id
	LEFT JOIN Condicion cond ON l.condicionid = cond.id
	LEFT JOIN CondicionSiniestrado cs ON l.condicionsiniestradoid = cs.id
	LEFT JOIN Situacion s ON l.situacionid = s.id
	LEFT JOIN ModalidadContratacion mc ON l.modalidadcontratacionid = mc.id
	LEFT JOIN ObraSocial os ON l.obrasocialid = os.id
	LEFT JOIN tmp_cantidadadherentes tca  ON tca.legajoid = l.id
	LEFT JOIN tmp_importesRemunerativos ir ON ir.legajoid = l.id
	LEFT JOIN tmp_importesNoRemunerativos inr ON inr.legajoid = l.id
	LEFT JOIN tmp_importesDescuentos id ON id.legajoid = l.id 
	LEFT JOIN tmp_conceptoHoraExtra tche ON tche.legajoid = l.id
	LEFT JOIN tmp_conceptoSueldoAnualComplementario tcsac ON tcsac.legajoid = l.id
	LEFT JOIN tmp_conceptoVacaciones tcv ON tcv.legajoid = l.id
	LEFT JOIN tmp_cantidadHorasExtras tcanthe ON tcanthe.legajoid = l.id
	LEFT JOIN tmp_conceptoIncrementoSalarialDto14_20 tcisd ON tcisd.legajoid = l.id
	WHERE li.fechaperiodoliquidacion BETWEEN fechadesde AND fechahasta 
	GROUP BY l.id,l.cuil,l.apellido,l.nombre,co.cantidadconyuge,h.cantidadhijos,l.situacionid,l.condicionid,tca.cantidadadherentes,ir.importeRemunerativo,inr.importeNoRemunerativo,id.importeDescuento,tcsac.importeSueldoAnualComplementario,tche.importeHorasExtras,tcv.importeVacaciones,tcanthe.cantidadHorasExtras,s.Codigo,cond.Codigo,mc.Codigo,os.Codigo,cs.Codigo,tcisd.importeIncrementoSalarialDto14_20;

	RETURN QUERY
		SELECT (
			tt_Final.Cuil ||
			tt_Final.NombreApellido ||
			tt_Final.CantidadConyuge ||
			tt_Final.CantidadHijos ||
			tt_Final.CodigoSituacion ||
			tt_Final.CodigoCondicion ||
			tt_Final.CodigoActividad ||
			tt_Final.CodigoZona ||
			tt_Final.PorcentajeAporteAdicionalSS ||
			tt_Final.CodigoModalidadContratacion ||
			tt_Final.CodigoObraSocial ||
			tt_Final.CantidadAdherentes ||
			tt_Final.RemuneracionTotal ||
			tt_Final.RemuneracionImponible1 ||
			tt_Final.AsignacionesFamiliaresPagadas ||
			tt_Final.ImporteAporteVoluntario ||
			tt_Final.ImporteAdicionalOS ||
			tt_Final.ImporteExcedenteAportesSS ||
			tt_Final.ImporteExcedenteAportesOS||
			tt_Final.ProvinciaLocalidad ||
			tt_Final.RemuneracionImponible2 ||
			tt_Final.RemuneracionImponible3 ||
			tt_Final.RemuneracionImponible4 ||
			tt_Final.CodigoSiniestrado ||
			tt_Final.CorrespondeReduccion ||
			tt_Final.CapitalRecomposicionLRT ||
			tt_Final.TipoEmpresa ||
			tt_Final.AporteAdicionalObraSocial ||
			tt_Final.Regimen ||
			tt_Final.SituacionRevista1 ||
			tt_Final.DiaInicioSituacionRevista1 ||
			tt_Final.SituacionRevista2 ||
			tt_Final.DiaInicioSituacionRevista2 ||
			tt_Final.SituacionRevista3 ||
			tt_Final.DiaInicioSituacionRevista3 ||
			tt_Final.SueldoMasAdicionales ||
			tt_Final.Sac ||
			tt_Final.HorasExtras ||
			tt_Final.ZonaDesfavorable ||
			tt_Final.Vacaciones ||
			tt_Final.CantidadDiasTrabajados ||
			tt_Final.RemuneracionImponible5 ||
			tt_Final.TrabajadorConvencionado ||
			tt_Final.RemuneracionImponible6 ||
			tt_Final.TipoOperacion ||
			tt_Final.Adicionales ||
			tt_Final.Premios ||
			tt_Final.RemuneracionImponible8 ||
			tt_Final.RemuneracionImponible7 ||
			tt_Final.CantidadHorasExtras ||
			tt_Final.ConceptosNoRemunerativos ||
			tt_Final.Maternidad ||
			tt_Final.RectificacionRemuneracion ||
			tt_Final.RemuneracionImponible9 ||
			tt_Final.ContribucionTareaDiferencial ||
			tt_Final.HorasTrabajadas ||
			tt_Final.SeguroColectivoDeVidaObligatorio ||
			tt_Final.ImporteDetraccion ||
			tt_Final.IncrementoSalarial ||
			tt_Final.RemuneracionImponible11) AS data
		FROM tt_FINAL;
	

END; $function$
;
