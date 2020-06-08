package librosueldosdigital

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
)

type Librosueldosdigital struct {
	Legajo                  string    `json:"legajo"`
	Apellido                string    `json:"apellido"`
	Nombre                  string    `json:"nombre"`
	Fechaperiodoliquidacion time.Time `json:"fechaperiodoliquidacion"`
}

type Exportartxtlibrosueldosdigital struct {
	Data string `json:"data"`
}

func LibroSueldosDigital(w http.ResponseWriter, r *http.Request) {

	fmt.Println("La URL accedida: " + r.URL.String())
	var librossueldosdigitales []Librosueldosdigital

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {
		queries := r.URL.Query()

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)

		p_tipoliquidacion := queries["tipoliquidacion"][0]
		p_periodomensual := queries["periodomensual"][0]
		esmensual := true

		if p_tipoliquidacion != "MENSUAL" {
			esmensual = false
		}

		db.Raw("SELECT * FROM SP_LIBROSUELDOSDIGITAL(" + strconv.FormatBool(esmensual) + ",'" + p_periodomensual + "')").Scan(&librossueldosdigitales)
		framework.RespondJSON(w, http.StatusOK, librossueldosdigitales)
	}
}

func LibroSueldosDigitalExportarTxtConceptosAFIP(w http.ResponseWriter, r *http.Request) {

	var exportartxtconceptosafip []Exportartxtlibrosueldosdigital
	var datosexportartxtconceptosafip Exportartxtlibrosueldosdigital
	fmt.Println("La URL accedida: " + r.URL.String())

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)

		db.Raw("SELECT * FROM SP_EXPORTARTXTLIBROSUELDOSDIGITALCONCEPTOSAFIP()").Scan(&exportartxtconceptosafip)

		for i := 0; i < len(exportartxtconceptosafip); i++ {

			datosexportartxtconceptosafip.Data = datosexportartxtconceptosafip.Data + exportartxtconceptosafip[i].Data + "\n"

		}

		framework.RespondJSON(w, http.StatusOK, datosexportartxtconceptosafip)

	}
}
