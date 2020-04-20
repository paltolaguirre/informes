package liquidacionfinalanual

import (
	"net/http"
	"strconv"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
)

type Liquidacionfinalanualf1357 struct {
	Legajo                     string  `json:"legajo"`
	Totalremuneraciones        float64 `json:"totalremuneraciones"`
	Totaldeduccionesgenerales  float64 `json:"totaldeduccionesgenerales"`
	Totaldeduccionespersonales float64 `json:"totaldeduccionespersonales"`
	Totalimpuestodeterminado   float64 `json:"totalimpuestodeterminado"`
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

		if p_tipopresentacion == "FINAL" {
			esfinal = true
		}

		db.Raw("SELECT * FROM SP_LIQUIDACIONFINALANUALF1357(" + strconv.FormatBool(esfinal) + ",'" + p_anio + "','" + p_mes + "')").Scan(&liquidacionfinalanualf1357)
		framework.RespondJSON(w, http.StatusOK, liquidacionfinalanualf1357)

	}
}
