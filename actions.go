package main

import (
	"net/http"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD/apiclientconexionbd"
	"github.com/xubiosueldos/framework"
)

var nombreMicroservicio string = "informes"

type Informef931 struct {
	Nombre  string  `json:"nombre"`
	Importe float32 `json:"importe"`
}

type InformeLibroSueldos struct {
	Legajo                  string    `json:"legajo"`
	Fechaperiodoliquidacion time.Time `json:"fechaperiodoliquidacion"`
	Concepto                string    `json:"concepto"`
	Importe                 float32   `json:"importe"`
}

func InformeF931(w http.ResponseWriter, r *http.Request) {
	var informesf931 []Informef931
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := apiclientconexionbd.ObtenerDB(tenant, nombreMicroservicio, 1, AutomigrateTablasPrivadas)

		defer apiclientconexionbd.CerrarDB(db)

		db.Raw("SELECT * FROM SP_INFORMEF931('" + p_fechadesde + "','" + p_fechahasta + "')").Scan(&informesf931)

		framework.RespondJSON(w, http.StatusOK, informesf931)
	}

}

func LibroSueldos(w http.ResponseWriter, r *http.Request) {

	var informeslibrossueldos []InformeLibroSueldos

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := apiclientconexionbd.ObtenerDB(tenant, nombreMicroservicio, 1, AutomigrateTablasPrivadas)

		defer apiclientconexionbd.CerrarDB(db)

		db.Raw("SELECT * FROM SP_INFORMELIBROSUELDOS('" + p_fechadesde + "','" + p_fechahasta + "')").Scan(&informeslibrossueldos)

		framework.RespondJSON(w, http.StatusOK, informeslibrossueldos)
	}

}

func AutomigrateTablasPrivadas(db *gorm.DB) {

}
