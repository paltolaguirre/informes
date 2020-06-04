CREATE OR REPLACE FUNCTION public.sp_exportartxtlibrosueldosdigitalconceptosafip()
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
	
	SELECT
	RIGHT(C_ZEROS || coalesce(ca.Codigo,''), 6)::VARCHAR AS CodigoConceptoAfip,
    RIGHT(C_ZEROS || coalesce(c.Codigointerno,0), 10)::VARCHAR AS CodigoInterno,
    RIGHT(C_ESPACIOS || coalesce(c.nombre,''), 150)::VARCHAR AS ConceptoNombre,
    CASE WHEN c.marcarepeticion  THEN '1' ELSE '0' END AS Marcarepeticion,
    CASE WHEN c.aportesipa  THEN '1' ELSE '0' END AS AporteSipa,
    CASE WHEN c.contribucionsipa  THEN '1' ELSE '0' END AS ContribucionSipa,
    CASE WHEN c.aportesinssjyp  THEN '1' ELSE '0' END AS AportesINSSJyP,
    CASE WHEN c.contribucionesinssjyp  THEN '1' ELSE '0' END AS ContribucionesINSSJyP,
    CASE WHEN c.aportesobrasocial  THEN '1' ELSE '0' END AS AportesObraSocial,
    CASE WHEN c.contribucionesobrasocial  THEN '1' ELSE '0' END AS ContribucionesObraSocial,
    CASE WHEN c.aportesfondosolidario  THEN '1' ELSE '0' END AS AportesFondoSolidario,
    CASE WHEN c.contribucionesfondosolidario  THEN '1' ELSE '0' END AS ContribucionesFondoSolidario,
    CASE WHEN c.aportesrenatea  THEN '1' ELSE '0' END AS AportesRenatea,
    CASE WHEN c.contribucionesrenatea  THEN '1' ELSE '0' END AS ContribucionesRenatea,
    CASE WHEN c.asignacionesfamiliares  THEN '1' ELSE '0' END AS AsignacionesFamiliares,
    CASE WHEN c.contribucionesfondonacional  THEN '1' ELSE '0' END AS ContribucionesFondoNacional,
    CASE WHEN c.contribucionesleyriesgo  THEN '1' ELSE '0' END AS ContribucionesLeyRiesgo,
    CASE WHEN c.aportesregimenesdiferenciales  THEN '1' ELSE '0' END AS AportesRegimenesDiferenciales,
    CASE WHEN c.aportesregimenesespeciales  THEN '1' ELSE '0' END AS AportesRegimenesEspeciales

	FROM Concepto c
	LEFT JOIN Conceptoafip ca ON c.conceptoafipid = ca.id;

	RETURN QUERY
		SELECT (
            tt_FINAL.CodigoConceptoAfip ||
            tt_FINAL.CodigoInterno ||
            tt_FINAL.ConceptoNombre ||
            tt_FINAL.Marcarepeticion ||
            tt_FINAL.AporteSipa ||
            tt_FINAL.ContribucionSipa ||
            tt_FINAL.AportesINSSJyP ||
            tt_FINAL.ContribucionesINSSJyP ||
            tt_FINAL.AportesObraSocial ||
            tt_FINAL.ContribucionesObraSocial ||
            tt_FINAL.AportesFondoSolidario ||
            tt_FINAL.ContribucionesFondoSolidario ||
            tt_FINAL.AportesRenatea ||
            tt_FINAL.ContribucionesRenatea || ' ' ||
            tt_FINAL.AsignacionesFamiliares || ' ' ||
            tt_FINAL.ContribucionesFondoNacional || ' '||
            tt_FINAL.ContribucionesLeyRiesgo ||
            tt_FINAL.AportesRegimenesDiferenciales || ' ' ||
            tt_FINAL.AportesRegimenesEspeciales || ' '
		) AS data
		FROM tt_FINAL;
	

END; $function$
;
