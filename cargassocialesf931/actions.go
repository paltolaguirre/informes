package cargassocialesf931

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/monoliticComunication"
)

type Informef931 struct {
	Nombre  string  `json:"nombre"`
	Importe float32 `json:"importe"`
}

type Exportartxtcargasocialesf931 struct {
	Data string `json:"data"`
}

func InformeF931(w http.ResponseWriter, r *http.Request) {

	fmt.Println("La URL accedida: " + r.URL.String())
	var informesf931 []Informef931
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)
		defer conexionBD.CerrarDB(db)

		db.Raw("SELECT * FROM SP_INFORMEF931('" + p_fechadesde + "','" + p_fechahasta + "')").Scan(&informesf931)

		framework.RespondJSON(w, http.StatusOK, informesf931)
	}

}

func InformeF931ExportarTxt(w http.ResponseWriter, r *http.Request) {
	fmt.Println("La URL accedida: " + r.URL.String())
	var exportartxtcargasocialesf931 []Exportartxtcargasocialesf931
	var datosaexportartxtcargassocialesf931 Exportartxtcargasocialesf931

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]
		var p_importedetraccion string = r.URL.Query()["importedetraccion"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)
		defer conexionBD.CerrarDB(db)

		strempresa := monoliticComunication.Obtenerdatosempresa(w, r, tokenAutenticacion)

		actividad := strempresa.Actividad
		tipodeempresa := strconv.Itoa(strempresa.Tipodeempresa)
		zona := strempresa.Zona
		reducevalor := strconv.Itoa(strempresa.Reducevalor)
		zonanombre := strempresa.Zonanombre

		db.Raw("SELECT * FROM SP_EXPORTARTXTCARGASSOCIALESF931('" + p_fechadesde + "','" + p_fechahasta + "','" + actividad + "','" + tipodeempresa + "','" + zona + "','" + zonanombre + "','" + reducevalor + "','" + p_importedetraccion + "')").Scan(&exportartxtcargasocialesf931)

		for i := 0; i < len(exportartxtcargasocialesf931); i++ {

			datosaexportartxtcargassocialesf931.Data = datosaexportartxtcargassocialesf931.Data + exportartxtcargasocialesf931[i].Data + "\n"

		}

		framework.RespondJSON(w, http.StatusOK, datosaexportartxtcargassocialesf931)
	}

}
