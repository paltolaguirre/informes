package liquidacionfinalanual

import (
	"net/http"
	"strconv"
	s "strings"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/monoliticComunication"
)

type Liquidacionfinalanualf1357 struct {
	Legajo                     string  `json:"legajo"`
	Totalremuneraciones        float64 `json:"totalremuneraciones"`
	Totaldeduccionesgenerales  float64 `json:"totaldeduccionesgenerales"`
	Totaldeduccionespersonales float64 `json:"totaldeduccionespersonales"`
	Totalimpuestodeterminado   float64 `json:"totalimpuestodeterminado"`
}

type Exportartxtliquidacionfinalanualf1357 struct {
	Data string `json:"data"`
}

func LiquidacionFinalAnualF1357(w http.ResponseWriter, r *http.Request) {
	var liquidacionfinalanualf1357 []Liquidacionfinalanualf1357
	var esfinal bool = false

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {
		queries := r.URL.Query()

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)

		p_tipopresentacion := queries["tipopresentacion"][0]
		p_anio := queries["anio"][0]
		p_mes := queries["mes"][0]

		if p_tipopresentacion == "Final" {
			esfinal = true
		}

		db.Raw("SELECT * FROM SP_LIQUIDACIONFINALANUALF1357(" + strconv.FormatBool(esfinal) + ",'" + p_anio + "','" + p_mes + "')").Scan(&liquidacionfinalanualf1357)
		framework.RespondJSON(w, http.StatusOK, liquidacionfinalanualf1357)

	}
}

func LiquidacionFinalAnualF1357ExportarTxt(w http.ResponseWriter, r *http.Request) {
	var esfinal bool = false
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {
		queries := r.URL.Query()
		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)
		var periodoinformado string
		var tipopresentacionid string
		p_tipopresentacion := queries["tipopresentacion"][0]
		p_anio := queries["anio"][0]
		p_mes := queries["mes"][0]

		strempresa := monoliticComunication.Obtenerdatosempresa(w, r, tokenAutenticacion)
		cuitempresa := (strempresa.Cuit)
		if cuitempresa == "" {
			framework.RespondError(w, http.StatusNotFound, "Debe completar el CUIT del Agente de Retención ")
			return
		}

		var exportartxtliquidacionfinalanualf1375 []Exportartxtliquidacionfinalanualf1357
		var datosaexportartxtliquidacionfinalanualf1375 Exportartxtliquidacionfinalanualf1357

		if p_tipopresentacion == "Final" {
			esfinal = true
			periodoinformado = p_anio + p_mes
			tipopresentacionid = "2"
		} else {
			periodoinformado = p_anio + "00"
			tipopresentacionid = "1"
		}
		//"01"->tipo de registro || "00"->secuencia || "0103"->codigo de impuesto || "215" -->codigo de concepto || "1357"-->numero de formulario || "00100"-> version del sistema
		datosaexportartxtliquidacionfinalanualf1375.Data = "01" + s.ReplaceAll(cuitempresa, "-", "") + periodoinformado + "00" + "0103" + "215" + "1357" + tipopresentacionid + "00100" + "\n"

		db.Raw("SELECT * FROM SP_EXPORTARTXTLIQUIDACIONFINALANUALF1357(" + strconv.FormatBool(esfinal) + ",'" + p_anio + "','" + p_mes + "')").Scan(&exportartxtliquidacionfinalanualf1375)

		for i := 0; i < len(exportartxtliquidacionfinalanualf1375); i++ {

			datosaexportartxtliquidacionfinalanualf1375.Data = datosaexportartxtliquidacionfinalanualf1375.Data + exportartxtliquidacionfinalanualf1375[i].Data + "\n"

		}

		framework.RespondJSON(w, http.StatusOK, datosaexportartxtliquidacionfinalanualf1375)
	}
}
