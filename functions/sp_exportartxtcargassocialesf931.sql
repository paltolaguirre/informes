-- Function: sp_exportartxtcargassocialesf931(date, date, character varying, character varying, character varying, character varying, character varying, numeric)

-- DROP FUNCTION sp_exportartxtcargassocialesf931(date, date, character varying, character varying, character varying, character varying, character varying, numeric)

CREATE OR REPLACE FUNCTION sp_exportartxtcargassocialesf931(IN fechadesde date, IN fechahasta date, IN actividad character varying, IN tipodeempresa character varying, IN zona character varying, IN zonanombre character varying, IN reducevalor character varying, IN importedetraccion numeric)
  RETURNS TABLE(data text) 
  AS $BODY$
DECLARE
	-- Constantes
	C_ZEROS CONSTANT VARCHAR := '00000000000000000000';
	C_ESPACIOS CONSTANT VARCHAR := '                 ';
	
BEGIN	
	DROP TABLE IF EXISTS tt_FINAL;

	CREATE TEMP TABLE tt_FINAL AS
	
	WITH tmp_cantidadadherentes AS(
		SELECT legajoid as legajoid, count(legajoid) as cantidadadherentes
		FROM legajo 
		INNER JOIN Hijo adherentes on legajo.id = adherentes.legajoid 
		WHERE legajo.obrasocialid = adherentes.obrasocialid 
		GROUP BY legajoid-- and legajoid = 'xxx'
	),
	
	tmp_remuneraciontotal AS(
		SELECT l.id as legajoid, sum(ir.importeunitario) as importeNoRemunerativo,sum(inr.importeunitario) as importeRemunerativo, sum(r.importeunitario) as importeRetencion, sum(d.importeunitario) as importeDescuento
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN Retencion r ON li.id = r.liquidacionid
		LEFT JOIN ImporteRemunerativo ir ON li.id = ir.liquidacionid
		LEFT JOIN ImporteNoRemunerativo inr ON li.id = inr.liquidacionid
		LEFT JOIN Descuento d ON li.id = d.liquidacionid
		WHERE li.fecha BETWEEN fechadesde AND fechahasta
		GROUP BY l.id
	),
	tmp_conceptoHoraExtra AS (
		SELECT l.id as legajoid, sum(ir.importeunitario) as importeHorasExtras
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN ImporteRemunerativo ir ON li.id = ir.liquidacionid
		LEFT JOIN Concepto c ON ir.conceptoid = c.id
		WHERE c.nombre ILIKE '%Horas Extras%' AND li.fecha BETWEEN fechadesde AND fechahasta
		GROUP BY l.id
	),
	tmp_conceptoSueldoAnualComplementario AS (
		SELECT l.id as legajoid, sum(ir.importeunitario) as importeSueldoAnualComplementario
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN ImporteRemunerativo ir ON li.id = ir.liquidacionid
		LEFT JOIN concepto c ON ir.conceptoid = c.id
		WHERE c.nombre ILIKE '%Sueldo Anual Complementario%' AND li.fecha BETWEEN fechadesde AND fechahasta
		GROUP BY l.id
	),
	tmp_conceptoVacaciones AS (
		SELECT l.id as legajoid, sum(ir.importeunitario) as importeVacaciones
		FROM Legajo l
		INNER JOIN Liquidacion li ON li.legajoid = l.id
		LEFT JOIN ImporteRemunerativo ir ON li.id = ir.liquidacionid
		LEFT JOIN concepto c ON ir.conceptoid = c.id
		WHERE c.nombre ILIKE '%Vacaciones%' AND li.fecha BETWEEN fechadesde AND fechahasta
		GROUP BY l.id
	),
	tmp_cantidadHorasExtras AS (
		SELECT l.id as legajoid, sum(n.cantidad) as cantidadHorasExtras
		FROM Legajo l
		INNER JOIN Novedad n ON n.legajoid = l.id
		INNER JOIN concepto c ON n.conceptoid = c.id
		WHERE c.nombre ILIKE '%Horas Extras%' 
		GROUP BY l.id
	)
	
	SELECT 	
	RIGHT(C_ZEROS || coalesce(l.cuil,''), 11) AS Cuil,
	LEFT(coalesce((l.apellido || ' ' || l.nombre),'') || C_ESPACIOS, 30) AS NombreApellido,
	RIGHT(C_ZEROS || coalesce(Count(co.id),0), 1) AS CantidadConyuge,
	RIGHT(C_ZEROS || coalesce(Count(h.id),0), 2) AS CantidadHijos,
	RIGHT(C_ZEROS || coalesce(s.Codigo,''), 2) AS CodigoSituacion,
	RIGHT(C_ZEROS || coalesce(cond.Codigo,''), 2) AS CodigoCondicion,
	RIGHT(C_ZEROS || coalesce(actividad,''), 3) AS CodigoActividad,
	RIGHT(C_ZEROS || coalesce(zona,''), 2) AS CodigoZona,
	REPEAT('0', 5)::VARCHAR AS PorcentajeAporteAdicionalSS,
	RIGHT(C_ZEROS || coalesce(mc.Codigo,'') , 3) AS CodigoModalidadContratacion,
	RIGHT(C_ZEROS || coalesce(os.Codigo,''), 6) AS CodigoObraSocial,
	RIGHT(C_ZEROS || coalesce(tca.cantidadadherentes,0), 2) AS CantidadAdherentes,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo + trt.importeNoRemunerativo - trt.importeRetencion,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionTotal,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible1,
	REPEAT('0', 9)::VARCHAR AS AsignacionesFamiliaresPagadas,
	REPEAT('0', 9)::VARCHAR AS ImporteAporteVoluntario,
	REPEAT('0', 9)::VARCHAR AS ImporteAdicionalOS,
	REPEAT('0', 9)::VARCHAR AS ImporteExcedenteAportesSS,
	REPEAT('0', 9)::VARCHAR AS ImporteExcedenteAportesOS,
	LEFT(coalesce(zonanombre,'') || C_ESPACIOS, 50) AS ProvinciaLocalidad,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible2,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible3,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible4,
	RIGHT(C_ZEROS || coalesce(cs.Codigo,''), 2) AS CodigoSiniestrado,
	RIGHT(C_ZEROS || coalesce(reducevalor,''), 1) AS CorrespondeReduccion,
	REPEAT('0', 9)::VARCHAR AS CapitalRecomposicionLRT,
	RIGHT(C_ZEROS || coalesce(tipodeempresa,''), 1) AS TipoEmpresa,
	REPEAT('0', 9)::VARCHAR AS AporteAdicionalObraSocial,
	'1'::VARCHAR AS Regimen,
	RIGHT(C_ZEROS || coalesce(s.Codigo,''), 2) AS SituacionRevista1,
	RIGHT(C_ZEROS || coalesce(date_part('day',l.fechaalta),0), 2) AS DiaInicioSituacionRevista1,
	REPEAT('0', 2)::VARCHAR AS SituacionRevista2,
	REPEAT('0', 2)::VARCHAR AS DiaInicioSituacionRevista2,
	REPEAT('0', 2)::VARCHAR AS SituacionRevista3,
	REPEAT('0', 2)::VARCHAR AS DiaInicioSituacionRevista3,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - tcsac.importeSueldoAnualComplementario - tche.importeHorasExtras - tcv.importeVacaciones,2), 0.00)::VARCHAR, '.', ','), 12) AS SueldoMasAdicionales,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcsac.importeSueldoAnualComplementario,2), 0.00)::VARCHAR, '.', ','), 12) AS Sac,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tche.importeHorasExtras,2), 0.00)::VARCHAR, '.', ','), 12) AS HorasExtras,
	REPEAT('0', 12)::VARCHAR AS ZonaDesfavorable,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(tcv.importeVacaciones,2), 0.00)::VARCHAR, '.', ','), 12) AS Vacaciones,
	RIGHT(C_ZEROS || '30' , 9) AS CantidadDiasTrabajados,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ',') , 12) AS RemuneracionImponible5,
	'1'::VARCHAR AS TrabajadorConvencionado,
	REPEAT('0', 12)::VARCHAR AS RemuneracionImponible6, 
	REPEAT('0', 1)::VARCHAR AS TipoOperacion,
	REPEAT('0', 12)::VARCHAR AS Adicionales,
	REPEAT('0', 12)::VARCHAR AS Premios,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible8,
	REPEAT('0', 12)::VARCHAR AS RemuneracionImponible7, 
	RIGHT(C_ZEROS || coalesce(tcanthe.cantidadHorasExtras,0), 3) AS CantidadHorasExtras,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeNoRemunerativo,2), 0.00)::VARCHAR, '.', ','), 12) AS ConceptosNoRemunerativos,
	REPEAT('0', 12)::VARCHAR AS Maternidad,
	REPEAT('0', 9)::VARCHAR AS RectificacionRemuneracion,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(trt.importeRemunerativo + trt.importeNoRemunerativo - trt.importeDescuento,2), 0.00)::VARCHAR, '.', ','), 12) AS RemuneracionImponible9,
	REPEAT('0', 9)::VARCHAR AS ContribucionTareaDiferencial,
	REPEAT('0', 3)::VARCHAR AS HorasTrabajadas,
	'T'::VARCHAR AS SeguroColectivoDeVidaObligatorio,
	RIGHT(C_ZEROS || REPLACE(coalesce(round(importeDetraccion,2), 0.00)::VARCHAR, '.', ','), 12) AS ImporteDetraccion
	FROM Legajo l
	INNER JOIN Liquidacion li ON li.legajoid = l.id
	LEFT JOIN Conyuge co ON co.legajoid = l.id
	LEFT JOIN Hijo h ON h.legajoid = l.id
	LEFT JOIN Condicion cond ON l.condicionid = cond.id
	LEFT JOIN CondicionSiniestrado cs ON l.condicionsiniestradoid = cs.id
	LEFT JOIN Situacion s ON l.situacionid = s.id
	LEFT JOIN ModalidadContratacion mc ON l.modalidadcontratacionid = mc.id
	LEFT JOIN ObraSocial os ON l.obrasocialid = os.id
	LEFT JOIN tmp_cantidadadherentes tca  ON tca.legajoid = l.id
	LEFT JOIN tmp_remuneraciontotal trt ON trt.legajoid = l.id 
	LEFT JOIN tmp_conceptoHoraExtra tche ON tche.legajoid = l.id
	LEFT JOIN tmp_conceptoSueldoAnualComplementario tcsac ON tcsac.legajoid = l.id
	LEFT JOIN tmp_conceptoVacaciones tcv ON tcv.legajoid = l.id
	LEFT JOIN tmp_cantidadHorasExtras tcanthe ON tcanthe.legajoid = l.id
	WHERE li.fecha BETWEEN fechadesde AND fechahasta 
	GROUP BY l.id,l.cuil,l.apellido,l.nombre,l.situacionid,l.condicionid,tca.cantidadadherentes,trt.importeRemunerativo,trt.importeNoRemunerativo,trt.importeRetencion,trt.importeDescuento,tcsac.importeSueldoAnualComplementario,tche.importeHorasExtras,tcv.importeVacaciones,tcanthe.cantidadHorasExtras,s.Codigo,cond.Codigo,mc.Codigo,os.Codigo,cs.Codigo;

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
			tt_Final.ImporteDetraccion) AS data
		FROM tt_FINAL;
	

END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION sp_exportartxtcargassocialesf931(date, date, character varying, character varying, character varying, character varying, character varying, numeric)
  OWNER TO postgres;
