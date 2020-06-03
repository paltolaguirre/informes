package librosueldosdigital

import (
	"fmt"
	"net/http"
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

		db.Raw("SELECT * FROM SP_LIBROSUELDOSDIGITAL('" + p_tipoliquidacion + "','" + p_periodomensual + "')").Scan(&librossueldosdigitales)

		framework.RespondJSON(w, http.StatusOK, librossueldosdigitales)
	}
}
