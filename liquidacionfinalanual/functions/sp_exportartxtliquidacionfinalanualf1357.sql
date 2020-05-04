CREATE OR REPLACE FUNCTION sp_exportartxtliquidacionfinalanualf1357(IN esfinal boolean, IN anio character varying, IN mes character varying) 
 RETURNS TABLE(data text)
 LANGUAGE plpgsql
AS $function$
DECLARE
	-- Constantes
	C_ZEROS CONSTANT VARCHAR := '000000000000000000000000000000000000';
	C_ESPACIOS CONSTANT VARCHAR := '                                                                        ';
	C_SAC CONSTANT INT := -5;
BEGIN
DROP TABLE IF EXISTS tt_FINAL;

CREATE TEMP TABLE tt_FINAL AS
-- Solo obtengo los legajos que usan IG
WITH tablaLegajosIDs AS(
	SELECT legajoid
	FROM liquidacion l
	INNER JOIN liquidaciontipo lt ON l.tipoid = lt.id
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND li.conceptoid = -29 AND ((esfinal AND lt.id = -6 AND to_char(l.fechaperiodoliquidacion,'MM') = mes) OR (not esfinal AND lt.id != -6  AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes))
	GROUP BY legajoid
),
tmp_FechaDesdeHasta AS(
    SELECT le.legajoid AS Legajoid, min(l.fechaperiodoliquidacion) AS FechaDesde, max(l.fechaperiodoliquidacion) AS FechaHasta
	FROM liquidacion l
    INNER JOIN tablaLegajosIDs le ON l.legajoid = le.legajoid
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio 
    GROUP BY le.legajoid
),
tmp_LegajoSiradig AS(
    SELECT le.legajoid AS legajoid, count(bs.id) AS beneficioLegajo
    FROM tablaLegajosIDs le
    INNER JOIN siradig s ON le.legajoid= s.legajoid 
    INNER JOIN beneficiosiradig bs ON s.id = bs.siradigid 
    INNER JOIN siradigtipogrilla stg ON bs.siradigtipogrillaid = stg.id 
    WHERE bs.siradigtipogrillaid = -24
    GROUP BY le.legajoid
),
tmp_RemuneracionBruta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'REMUNERACION_BRUTA'
	
),
tmp_RetribucionNoHabitual AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'RETRIBUCIONES_NO_HABITUALES'
),
tmp_SacPrimerCuota AS (
	SELECT le.legajoid as legajoid, li.importeunitario AS importe 
	FROM liquidacion l
	INNER JOIN tablaLegajosIDs le on l.legajoid = le.legajoid
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND to_char(l.fechaperiodoliquidacion, 'MM') = '06' AND li.conceptoid = -2 and l.tipoid = -5
),
tmp_SacSegundaCuota AS (
	SELECT le.legajoid as legajoid, li.importeunitario AS importe 
	FROM liquidacion l
	INNER JOIN tablaLegajosIDs le on l.legajoid = le.legajoid
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND to_char(l.fechaperiodoliquidacion, 'MM') = '12' AND li.conceptoid = -2 and l.tipoid = -5
),
tmp_HorasExtrasGravadas AS (
SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HORAS_EXTRAS_GRAVADAS'
),
tmp_MovilidadYViaticosGravada AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MOVILIDAD_Y_VIATICOS_GRAVADA'
),
tmp_PersonalDocenteGravada AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MATERIAL_DIDACTICO_PERSONAL_DOCENTE_REMUNERACION_GRAVADA'
),
tmp_RemuneracionNoAlcanzadaOExenta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'REMUNERACION_NO_ALCANZADA_O_EXENTA'
),
tmp_HorasExtrasExentas AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HORAS_EXTRAS_REMUNERACION_EXENTA'
),
tmp_MovilidadYViaticosExenta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MOVILIDAD_Y_VIATICOS_REMUNERACION_EXENTA'
),
tmp_PersonalDocenteExenta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MATERIAL_DIDACTICO_PERSONAL_DOCENTE_REMUNERACION_EXENTA'
),
tmp_RemuneracionBrutaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'REMUNERACION_BRUTA_OTROS_EMPLEOS'
),
tmp_RetribucionNoHabitualOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'RETRIBUCIONES_NO_HABITUALES_OTROS_EMPLEOS'
),
tmp_SacPrimerCuotaOtrosEmpleos AS (
	SELECT le.legajoid AS legajoid, igoe.sac AS importe
    FROM tablaLegajosIDs le
    INNER JOIN siradig s ON le.legajoid= s.legajoid 
    inner join Importegananciasotroempleosiradig igoe on s.id = igoe.siradigid     
    WHERE to_char(s.periodosiradig, 'YYYY') = anio and to_char(igoe.mes, 'MM') = '06'
    GROUP BY le.legajoid,igoe.sac
),
tmp_SacSegundaCuotaOtrosEmpleos AS (
	SELECT le.legajoid AS legajoid, igoe.sac AS importe
    FROM tablaLegajosIDs le
    INNER JOIN siradig s ON le.legajoid= s.legajoid 
    inner join Importegananciasotroempleosiradig igoe on s.id = igoe.siradigid     
    WHERE to_char(s.periodosiradig, 'YYYY') = anio and to_char(igoe.mes, 'MM') = '12'
    GROUP BY le.legajoid,igoe.sac
),
tmp_HorasExtrasGravadasOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HORAS_EXTRAS_GRAVADAS_OTROS_EMPLEOS'
),
tmp_MovilidadYViaticosGravadaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MOVILIDAD_Y_VIATICOS_GRAVADA_OTROS_EMPLEOS'
),
tmp_PersonalDocenteGravadaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MATERIA_DIDACTICO_OTROS_EMPLEOS'
),
tmp_RemuneracionNoAlcanzadaOExentaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'REMUNERACION_NO_ALCANZADA_O_EXENTA_OTROS_EMPLEOS'
),
tmp_HorasExtrasExentasOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HORAS_EXTRAS_REMUNERACION_EXENTA_OTROS_EMPLEOS'
),
tmp_MovilidadYViaticosExentaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MOVILIDAD_Y_VIATICOS_REMUNERACION_EXENTA_OTROS_EMPLEOS'
),
tmp_PersonalDocenteExentaOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MATERIAL_DIDACTICO_PERSONAL_DOCENTE_REMUNERACION_EXENTA_OTROS_EMPLEOS'
),
tmp_SubtotalRemuneracionGravada AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_REMUNERACION_GRAVADA'
),
tmp_SubtotalRemuneracionNoGravadaNoAlcanzadaExenta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_REMUNERACION_NO_GRAVADA_NO_ALCANZADA_EXENTA'
),
tmp_TotalRemuneraciones AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'TOTAL_REMUNERACIONES'
),
tmp_AportesJubilatorios AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_JUBILATORIOS_RETIROS_PENSIONES_O_SUBSIDIOS'
),
tmp_AportesJubilatoriosOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_JUBILATORIOS_RETIROS_PENSIONES_O_SUBSIDIOS_OTROS_EMPLEOS'
),
tmp_AportesObraSocial AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_OBRA_SOCIAL'
),
tmp_AportesObraSocialOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_OBRA_SOCIAL_OTROS_EMPLEOS'
),
tmp_CuotaSindical AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'CUOTA_SINDICAL'
),
tmp_CuotaSindicalOtrosEmpleos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'CUOTA_SINDICAL_OTROS_EMPLEOS'
),
tmp_CuotaMedicaAsistencial AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'CUOTA_MEDICA_ASISTENCIAL'
),
tmp_PrimasSeguroCasoMuerte AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'PRIMAS_DE_SEGURO_PARA_EL_CASO_DE_MUERTE'
),
tmp_PrimasSeguroAhorroOMixto AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'PRIMAS_DE_SEGURO_DE_AHORRO_O_MIXTO'
),
tmp_AportesPlanesSeguroRetiroPrivado AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_A_PLANES_DE_SEGURO_DE_RETIRO_PRIVADO'
),
tmp_AdquisicionCuotapartesFCI AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'ADQUISICION_DE_CUOTAPARTES_DE_FCI_CON_FINES_DE_RETIRO'
),
tmp_GastosSepelio AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'GASTOS_DE_SEPELIO'
),
tmp_GastosRepresentacionCorredores AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'GASTOS_DE_REPRESENTACION_E_INTERESES_DE_CORREDORES_Y_VIAJANTES_DE_COMERCIO'
),
tmp_DonacionFisicosNacProvMunArt20 AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'DONACION_FISICOS_NAC_PROV_MUN_ART_20'
),
tmp_DescuentosObligatoriosLeyNacionalProvincialMunicipal AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'DESCUENTOS_OBLIGATORIOS_POR_LEY_NACIONAL_PROVINCIAL_MUNICIPAL'
),
tmp_HonorariosServSanitaria AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HONORARIOS_SERV_ASISTENCIA_SANITARIA_MEDICA_Y_PARAMEDICA'
),
tmp_InteresesCreditosHipotecarios AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'INTERESES_CREDITOS_HIPOTECARIOS'
),
tmp_AportesCapSocFondoRiesgoSGR AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_CAP_SOC_FONDO_RIESGO_SOCIOS_PROTECTORES_SGR'
),
tmp_AportesCajasComplementarias AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'APORTES_CAJAS_COMPLEMENTARIAS_FONDOS_COMPENSADORES_DE_PREV_SIMILARES'
),
tmp_AlquilerInmbuebles AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'ALQUILER_INMUEBLES_DESTINADOS_A_CASA_HABITACION'
),
tmp_EmpleadosServicioDomestico AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'EMPLEADOS_SERVICIO_DOMESTICO'
),
tmp_GastosMovilidadViaticos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'GASTOS_MOVILIDAD_VIATICOS_ABONADOS_POR_EL_EMPLEADOR'
),
tmp_IndumentariaEquipamientoObligatorio AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'INDUMENTARIA_EQUIPAMIENTO_CARACTER_OBLIGATORIO'
),
tmp_OtrasDeducciones AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'OTRAS_DEDUCCIONES'
),
tmp_SubtotalDeduccionesGenerales AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_DEDUCCIONES_GENERALES'
),
tmp_MinimoNoImponible AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'MINIMO_NO_IMPONIBLE'
),
tmp_DeduccionEspecial AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'DEDUCCION_ESPECIAL'
),
tmp_Conyuge AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'CONYUGE_ANUAL'
),
tmp_CantidadHijos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'CANTIDAD_HIJOS_HIJASTROS'
),
tmp_Hijos AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'HIJOS_ANUAL'
),
tmp_SubtotalCargasFamilia AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SUBTOTAL_CARGAS_FAMILIA'
),
tmp_RemuneracionSujetaImpuesto AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'REMUNERACION_SUJETA_A_IMPUESTO'
),
tmp_AlicuotaArt90LeyGanancias AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'ALICUOTA_ART_90_LEY_GANANCIAS'
),
tmp_AlicuotaAplicableSinHorasExtras AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'ALICUOTA_APLICABLE_SIN_INCLUIR_HORAS_EXTRAS'
),
tmp_ImpuestoDeterminado AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'IMPUESTO_DETERMINADO'
),
tmp_ImpuestoRetenido AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'IMPUESTO_RETENIDO'
),
tmp_PagosACuenta AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'PAGOS_A_CUENTA'
),
tmp_SaldoAPagar AS (
	SELECT l.id as liquidacionid, a.importe AS importe 
	FROM liquidacion l 
	INNER JOIN liquidacionitem li ON l.id = li.liquidacionid 
	INNER JOIN acumulador a ON li.id = a.liquidacionitemid 
	WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes)) AND li.conceptoid = -29 AND a.codigo = 'SALDO_A_PAGAR'
)
SELECT
'02'::VARCHAR AS TipoRegistroTrabajador,
RIGHT(C_ZEROS || coalesce(le.cuil,''), 11)::VARCHAR AS CuitTrabajador, 
RIGHT(C_ZEROS || coalesce(to_char(tfdh.FechaDesde , 'YYYY') || to_char(tfdh.FechaDesde , 'MM') || to_char(tfdh.FechaDesde , 'DD'),''),8)::VARCHAR AS PeriodoTrabajadoDesde,
RIGHT(C_ZEROS || coalesce(to_char(tfdh.FechaHasta , 'YYYY') || to_char(tfdh.FechaHasta , 'MM') || to_char(tfdh.FechaHasta , 'DD'),''),8)::VARCHAR AS PeriodoTrabajadoHasta,
RIGHT(C_ZEROS || coalesce((to_number(to_char(tfdh.FechaHasta, 'MM'),'99') - to_number(to_char(tfdh.FechaDesde, 'MM'),'99') + 1),0),2)::VARCHAR AS MesesTrabajador,
CASE WHEN COUNT(tls.beneficioLegajo) = 0  THEN '1' ELSE '2' END AS BeneficioTrabajador,
'0'::VARCHAR AS DesarrollaActividadTransporte,
'03'::VARCHAR AS TipoRegistroRemuneracion,
RIGHT(C_ZEROS || coalesce(le.cuil,''), 11)::VARCHAR AS CuitRemuneracion,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trb.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionBruta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trnh.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionNoHabitual,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tspc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS SacPrimerCuota,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tssc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS SacSegundaCuota,
RIGHT(C_ZEROS || REPLACE(coalesce(round(theg.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS HorasExtrasGravadas,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tmvg.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS MovilidadYViaticosGravada,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpdg.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PersonalDocenteGravada,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trnae.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionNoAlcanzadaOExenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(thee.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS HorasExtrasExenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tmve.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS MovilidadYViaticosExenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpde.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PersonalDocenteExenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trboe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionBrutaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trnhoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionNoHabitualOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tspcoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS SacPrimerCuotaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tsscoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS SacSegundaCuotaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(thegoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS HorasExtrasGravadasOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tmvgoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS MovilidadYViaticosGravadaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpdgoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PersonalDocenteGravadaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trnaeoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionNoAlcanzadaOExentaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(theeoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS HorasExtrasExentaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tmveoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS MovilidadYViaticosExentaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpdeoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PersonalDocenteExentaOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tsrg.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionGravada,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tsrngnae.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionNoGravadaNoAlcanzadaExenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(ttr.importe,2), 0.00)::VARCHAR, '.', ''), 17)::VARCHAR AS TotalRemuneraciones,
'04'::VARCHAR AS TipoRegistroDeduccion,
RIGHT(C_ZEROS || coalesce(le.cuil,''), 11)::VARCHAR AS CuitDeduccion, 
RIGHT(C_ZEROS || REPLACE(coalesce(round(taj.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AportesJubilatorios,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tajoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS TotalRemuneracionesOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(taos.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AporteObraSocial,
RIGHT(C_ZEROS || REPLACE(coalesce(round(taosoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AporteObraSocialOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tcs.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS CuotaSindical,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tcsoe.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS CuotaSindicalOtrosEmpleos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tcma.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS CuotaMedicaAsistencial,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpscm.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PrimasSeguroParaCasoDeMuerte,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpsam.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PrimasSeguroDeAhorroOMixto,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tapsrp.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AportesPlanesDeSeguroDeRetiroPrivado,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tacf.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AdquisicionDeCuotapartesDeFCIConFinesDeRetiro,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tgs.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS GastosSepelio,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tgrc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS GastosRepresentacionEIntereses,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tdfnpm.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS DonacionFisicosNacProvMunArt20,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tdolnpm.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS DescuentosObligatoriosPorLey,
RIGHT(C_ZEROS || REPLACE(coalesce(round(thss.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS HonorariosServAsistenciaSanitaria,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tich.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS InteresesCreditosHipotecarios,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tacsfr.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AportesCapSocFondoRiesgo,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tacc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AportesCajasComplementarias,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tai.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS AlquilerInmuebles,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tesd.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS EmpleadoServicioDomestico,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tgmv.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS GastosMovilidadViaticosAbonadosPorElEmpleador,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tieo.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS IndumentariaEquipamiento,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tod.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS OtrasDeducciones,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tsdg.importe,2), 0.00)::VARCHAR, '.', ''), 17)::VARCHAR AS TotalDeduccionesGenerales,
'05'::VARCHAR AS TipoRegistroDeduccionArt23,
RIGHT(C_ZEROS || coalesce(le.cuil,''), 11)::VARCHAR AS CuitDeduccionArt23, 
RIGHT(C_ZEROS || REPLACE(coalesce(round(tmni.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS MinimoNoImponible,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tde.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS DeduccionEspecial,
RIGHT(C_ZEROS || REPLACE(coalesce(0, 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS DeduccionEspecifica,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS Conyuge,
RIGHT(C_ZEROS || coalesce(tch.importe::int,0), 2)::VARCHAR AS CantidadHijos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(th.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS Hijos,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tscf.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS TotalCargasFamilia,
--“Total Deducciones ART. 23” es la sumatoria del campo 3 (“Ganancia no Imponible”) + campo 4 (“Deducción Especial”) + campo 9 (“Total de Cargas de Familia”)
RIGHT(C_ZEROS || REPLACE((coalesce(round(tmni.importe,2), 0.00) + coalesce(round(tde.importe,2), 0.00) + coalesce(round(tscf.importe,2), 0.00)) ::VARCHAR, '.', ''), 15)::VARCHAR AS DeduccionesArt23,
RIGHT(C_ZEROS || REPLACE(coalesce(round(trsi.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS RemuneracionSujetaAImpuesto,
'06'::VARCHAR AS TipoRegistroCalculoDelImpuesto,
RIGHT(C_ZEROS || coalesce(le.cuil,''), 11)::VARCHAR AS CuitCalculoDelImpuesto,
CASE 
	         WHEN coalesce(taa90lg.importe, 0) = 0 THEN '0' 
	         WHEN coalesce(taa90lg.importe, 0) = 5 THEN '1' 
	         WHEN coalesce(taa90lg.importe, 0) = 9 THEN '2' 
	         WHEN coalesce(taa90lg.importe, 0) = 12 THEN '3'
	         WHEN coalesce(taa90lg.importe, 0) = 15 THEN '4' 
	         WHEN coalesce(taa90lg.importe, 0) = 19 THEN '5'
	         WHEN coalesce(taa90lg.importe, 0) = 23 THEN '6'
	         WHEN coalesce(taa90lg.importe, 0) = 27 THEN '7'
	         WHEN coalesce(taa90lg.importe, 0) = 31 THEN '8'
	         WHEN coalesce(taa90lg.importe, 0) = 35 THEN '9'
	         
	       END                                        AS AlicuotaArt90,
 CASE 
	         WHEN coalesce(taashe.importe, 0) = 0 THEN '0' 
	         WHEN coalesce(taashe.importe, 0) = 5 THEN '1' 
	         WHEN coalesce(taashe.importe, 0) = 9 THEN '2' 
	         WHEN coalesce(taashe.importe, 0) = 12 THEN '3'
	         WHEN coalesce(taashe.importe, 0) = 15 THEN '4' 
	         WHEN coalesce(taashe.importe, 0) = 19 THEN '5'
	         WHEN coalesce(taashe.importe, 0) = 23 THEN '6'
	         WHEN coalesce(taashe.importe, 0) = 27 THEN '7'
	         WHEN coalesce(taashe.importe, 0) = 31 THEN '8'
	         WHEN coalesce(taashe.importe, 0) = 35 THEN '9'
	         
	       END 										AS AlicuotaAplicableSinHorasExtras,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tid.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS ImpuestoDeterminado,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tir.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS ImpuestoRetenido,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tpc.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS PagosACuenta,
RIGHT(C_ZEROS || REPLACE(coalesce(round(tsp.importe,2), 0.00)::VARCHAR, '.', ''), 15)::VARCHAR AS SaldoAPagar
FROM legajo le
INNER JOIN tablaLegajosIDs tl on le.id = tl.legajoid
INNER JOIN liquidacion l ON l.legajoid = tl.legajoid
LEFT JOIN tmp_FechaDesdeHasta tfdh ON tl.legajoid = tfdh.legajoid
LEFT JOIN tmp_LegajoSiradig tls ON tl.legajoid = tls.legajoid
LEFT JOIN tmp_RemuneracionBruta trb ON l.id = trb.liquidacionid
LEFT JOIN tmp_RetribucionNoHabitual trnh ON l.id = trnh.liquidacionid
LEFT JOIN tmp_SacPrimerCuota tspc ON tl.legajoid = tspc.legajoid
LEFT JOIN tmp_SacSegundaCuota tssc ON tl.legajoid = tssc.legajoid
LEFT JOIN tmp_HorasExtrasGravadas theg ON l.id = theg.liquidacionid
LEFT JOIN tmp_MovilidadYViaticosGravada tmvg ON l.id = tmvg.liquidacionid
LEFT JOIN tmp_PersonalDocenteGravada tpdg ON l.id = tpdg.liquidacionid
LEFT JOIN tmp_RemuneracionNoAlcanzadaOExenta trnae ON l.id = trnae.liquidacionid
LEFT JOIN tmp_HorasExtrasExentas thee ON l.id = thee.liquidacionid
LEFT JOIN tmp_MovilidadYViaticosExenta tmve ON l.id = tmve.liquidacionid
LEFT JOIN tmp_PersonalDocenteExenta tpde ON l.id = tpde.liquidacionid
LEFT JOIN tmp_RemuneracionBrutaOtrosEmpleos trboe ON l.id = trboe.liquidacionid
LEFT JOIN tmp_RetribucionNoHabitualOtrosEmpleos trnhoe ON l.id = trnhoe.liquidacionid
LEFT JOIN tmp_SacPrimerCuotaOtrosEmpleos tspcoe ON tl.legajoid = tspcoe.legajoid
LEFT JOIN tmp_SacSegundaCuotaOtrosEmpleos tsscoe ON tl.legajoid = tsscoe.legajoid
LEFT JOIN tmp_HorasExtrasGravadasOtrosEmpleos thegoe ON l.id = thegoe.liquidacionid
LEFT JOIN tmp_MovilidadYViaticosGravadaOtrosEmpleos tmvgoe ON l.id = tmvgoe.liquidacionid
LEFT JOIN tmp_PersonalDocenteGravadaOtrosEmpleos tpdgoe ON l.id = tpdgoe.liquidacionid
LEFT JOIN tmp_RemuneracionNoAlcanzadaOExentaOtrosEmpleos trnaeoe ON l.id = trnaeoe.liquidacionid
LEFT JOIN tmp_HorasExtrasExentasOtrosEmpleos theeoe ON l.id = theeoe.liquidacionid
LEFT JOIN tmp_MovilidadYViaticosExentaOtrosEmpleos tmveoe ON l.id = tmveoe.liquidacionid
LEFT JOIN tmp_PersonalDocenteExentaOtrosEmpleos tpdeoe ON l.id = tpdeoe.liquidacionid
LEFT JOIN tmp_SubtotalRemuneracionGravada tsrg ON l.id = tsrg.liquidacionid
LEFT JOIN tmp_SubtotalRemuneracionNoGravadaNoAlcanzadaExenta tsrngnae ON l.id = tsrngnae.liquidacionid
LEFT JOIN tmp_TotalRemuneraciones ttr ON l.id = ttr.liquidacionid
LEFT JOIN tmp_AportesJubilatorios taj ON l.id = taj.liquidacionid
LEFT JOIN tmp_AportesJubilatoriosOtrosEmpleos tajoe ON l.id = tajoe.liquidacionid
LEFT JOIN tmp_AportesObraSocial taos ON l.id = taos.liquidacionid
LEFT JOIN tmp_AportesObraSocialOtrosEmpleos taosoe ON l.id = taosoe.liquidacionid
LEFT JOIN tmp_CuotaSindical tcs ON l.id = tcs.liquidacionid
LEFT JOIN tmp_CuotaSindicalOtrosEmpleos tcsoe ON l.id = tcsoe.liquidacionid
LEFT JOIN tmp_CuotaMedicaAsistencial tcma ON l.id = tcma.liquidacionid
LEFT JOIN tmp_PrimasSeguroCasoMuerte tpscm ON l.id = tpscm.liquidacionid
LEFT JOIN tmp_PrimasSeguroAhorroOMixto tpsam ON l.id = tpsam.liquidacionid
LEFT JOIN tmp_AportesPlanesSeguroRetiroPrivado tapsrp ON l.id = tapsrp.liquidacionid
LEFT JOIN tmp_AdquisicionCuotapartesFCI tacf ON l.id = tacf.liquidacionid
LEFT JOIN tmp_GastosSepelio tgs ON l.id = tgs.liquidacionid
LEFT JOIN tmp_GastosRepresentacionCorredores tgrc ON l.id = tgrc.liquidacionid
LEFT JOIN tmp_DonacionFisicosNacProvMunArt20 tdfnpm ON l.id = tdfnpm.liquidacionid
LEFT JOIN tmp_DescuentosObligatoriosLeyNacionalProvincialMunicipal tdolnpm ON l.id = tdolnpm.liquidacionid
LEFT JOIN tmp_HonorariosServSanitaria thss ON l.id = thss.liquidacionid
LEFT JOIN tmp_InteresesCreditosHipotecarios tich ON l.id = tich.liquidacionid
LEFT JOIN tmp_AportesCapSocFondoRiesgoSGR tacsfr ON l.id = tacsfr.liquidacionid
LEFT JOIN tmp_AportesCajasComplementarias tacc ON l.id = tacc.liquidacionid
LEFT JOIN tmp_AlquilerInmbuebles tai ON l.id = tai.liquidacionid
LEFT JOIN tmp_EmpleadosServicioDomestico tesd ON l.id = tesd.liquidacionid
LEFT JOIN tmp_GastosMovilidadViaticos tgmv ON l.id = tgmv.liquidacionid
LEFT JOIN tmp_IndumentariaEquipamientoObligatorio tieo ON l.id = tieo.liquidacionid
LEFT JOIN tmp_OtrasDeducciones tod ON l.id = tod.liquidacionid
LEFT JOIN tmp_SubtotalDeduccionesGenerales tsdg ON l.id = tsdg.liquidacionid
LEFT JOIN tmp_MinimoNoImponible tmni ON l.id = tmni.liquidacionid
LEFT JOIN tmp_DeduccionEspecial tde ON l.id = tde.liquidacionid
LEFT JOIN tmp_Conyuge tc ON l.id = tc.liquidacionid
LEFT JOIN tmp_CantidadHijos tch ON l.id = tch.liquidacionid
LEFT JOIN tmp_Hijos th ON l.id = th.liquidacionid
LEFT JOIN tmp_SubtotalCargasFamilia tscf ON l.id = tscf.liquidacionid
LEFT JOIN tmp_RemuneracionSujetaImpuesto trsi ON l.id = trsi.liquidacionid
LEFT JOIN tmp_AlicuotaArt90LeyGanancias taa90lg ON l.id = taa90lg.liquidacionid
LEFT JOIN tmp_AlicuotaAplicableSinHorasExtras taashe ON l.id = taashe.liquidacionid
LEFT JOIN tmp_ImpuestoDeterminado tid ON l.id = tid.liquidacionid
LEFT JOIN tmp_ImpuestoRetenido tir ON l.id = tir.liquidacionid
LEFT JOIN tmp_PagosACuenta tpc ON l.id = tpc.liquidacionid
LEFT JOIN tmp_SaldoAPagar tsp ON l.id = tsp.liquidacionid
WHERE to_char(l.fechaperiodoliquidacion, 'YYYY') = anio AND l.tipoid != C_SAC AND ((esfinal AND  to_char(l.fechaperiodoliquidacion, 'MM') = mes) OR (not esfinal AND to_char(l.fechaperiodoliquidacion, 'MM') = mes))
GROUP BY tl.legajoid,le.cuil,tfdh.fechadesde,tfdh.FechaHasta,tls.beneficioLegajo,trb.importe,trnh.importe,tspc.importe,tssc.importe,theg.importe,tmvg.importe,tpdg.importe,trnae.importe,thee.importe,tmve.importe,tpde.importe,trboe.importe,trnhoe.importe,tspcoe.importe,tsscoe.importe,thegoe.importe,tmvgoe.importe,tpdgoe.importe,trnaeoe.importe,theeoe.importe,tmveoe.importe,tpdeoe.importe,tsrg.importe,tsrngnae.importe,ttr.importe,taj.importe,tajoe.importe,taos.importe,taosoe.importe,tcs.importe,tcsoe.importe,tcma.importe,tpscm.importe,tpsam.importe,tapsrp.importe,tacf.importe,tgs.importe,tgrc.importe,tdfnpm.importe,tdolnpm.importe,thss.importe,tich.importe,tacsfr.importe,tacc.importe,tai.importe,tesd.importe,tgmv.importe,tieo.importe,tod.importe,
tsdg.importe,tmni.importe,tde.importe,tc.importe,tch.importe,th.importe,tscf.importe,trsi.importe,taa90lg.importe,taashe.importe,tid.importe,tir.importe,tpc.importe,tsp.importe
ORDER BY tl.legajoid;

RETURN QUERY
SELECT (
  tt_Final.TipoRegistroTrabajador ||
  tt_Final.CuitTrabajador ||
  tt_Final.PeriodoTrabajadoDesde ||
  tt_Final.PeriodoTrabajadoHasta ||
  tt_Final.MesesTrabajador ||
  tt_Final.BeneficioTrabajador ||
  tt_Final.DesarrollaActividadTransporte||chr(10)||
  tt_Final.TipoRegistroRemuneracion ||
  tt_Final.CuitRemuneracion ||
  tt_Final.RemuneracionBruta ||
  tt_Final.RemuneracionNoHabitual ||
  tt_Final.SacPrimerCuota ||
  tt_Final.SacSegundaCuota ||
  tt_Final.HorasExtrasGravadas ||
  tt_Final.MovilidadYViaticosGravada ||
  tt_Final.PersonalDocenteGravada ||
  tt_Final.RemuneracionNoAlcanzadaOExenta ||
  tt_Final.HorasExtrasExenta ||
  tt_Final.MovilidadYViaticosExenta ||
  tt_Final.PersonalDocenteExenta ||
  tt_Final.RemuneracionBrutaOtrosEmpleos ||
  tt_Final.RemuneracionNoHabitualOtrosEmpleos ||
  tt_Final.SacPrimerCuotaOtrosEmpleos ||
  tt_Final.SacSegundaCuotaOtrosEmpleos ||
  tt_Final.HorasExtrasGravadasOtrosEmpleos ||
  tt_Final.MovilidadYViaticosGravadaOtrosEmpleos ||
  tt_Final.PersonalDocenteGravadaOtrosEmpleos ||
  tt_Final.RemuneracionNoAlcanzadaOExentaOtrosEmpleos ||
  tt_Final.HorasExtrasExentaOtrosEmpleos ||
  tt_Final.MovilidadYViaticosExentaOtrosEmpleos ||
  tt_Final.PersonalDocenteExentaOtrosEmpleos ||
  tt_Final.RemuneracionGravada ||
  tt_Final.RemuneracionNoGravadaNoAlcanzadaExenta ||
  tt_Final.TotalRemuneraciones||chr(10)||
  tt_Final.TipoRegistroDeduccion ||
  tt_Final.CuitDeduccion ||
  tt_Final.AportesJubilatorios ||
  tt_Final.TotalRemuneracionesOtrosEmpleos ||
  tt_Final.AporteObraSocial ||
  tt_Final.AporteObraSocialOtrosEmpleos ||
  tt_Final.CuotaSindical ||
  tt_Final.CuotaSindicalOtrosEmpleos ||
  tt_Final.CuotaMedicaAsistencial ||
  tt_Final.PrimasSeguroParaCasoDeMuerte ||
  tt_Final.PrimasSeguroDeAhorroOMixto ||
  tt_Final.AportesPlanesDeSeguroDeRetiroPrivado ||
  tt_Final.AdquisicionDeCuotapartesDeFCIConFinesDeRetiro ||
  tt_Final.GastosSepelio ||
  tt_Final.GastosRepresentacionEIntereses ||
  tt_Final.DonacionFisicosNacProvMunArt20 ||
  tt_Final.DescuentosObligatoriosPorLey ||
  tt_Final.HonorariosServAsistenciaSanitaria ||
  tt_Final.InteresesCreditosHipotecarios ||
  tt_Final.AportesCapSocFondoRiesgo ||
  tt_Final.AportesCajasComplementarias ||
  tt_Final.AlquilerInmuebles ||
  tt_Final.EmpleadoServicioDomestico ||
  tt_Final.GastosMovilidadViaticosAbonadosPorElEmpleador ||
  tt_Final.IndumentariaEquipamiento ||
  tt_Final.OtrasDeducciones ||
  tt_Final.TotalDeduccionesGenerales ||chr(10)||
  tt_Final.TipoRegistroDeduccionArt23 ||
  tt_Final.CuitDeduccionArt23 ||
  tt_Final.MinimoNoImponible ||
  tt_Final.DeduccionEspecial ||
  tt_Final.DeduccionEspecifica ||
  tt_Final.Conyuge ||
  tt_Final.CantidadHijos ||
  tt_Final.Hijos ||
  tt_Final.TotalCargasFamilia ||
  tt_Final.DeduccionesArt23 ||
  tt_Final.RemuneracionSujetaAImpuesto ||chr(10)||
  tt_Final.TipoRegistroCalculoDelImpuesto ||
  tt_Final.CuitCalculoDelImpuesto ||
  tt_Final.AlicuotaArt90 ||
  tt_Final.AlicuotaAplicableSinHorasExtras ||
  tt_Final.ImpuestoDeterminado ||
  tt_Final.ImpuestoRetenido ||
  tt_Final.PagosACuenta ||
  tt_Final.SaldoAPagar) AS data
  FROM tt_Final;

END; $function$;
