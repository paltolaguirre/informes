package librosueldos

import (
	"fmt"
	"net/http"
	"time"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/monoliticComunication"
)

type InformeLibroSueldos struct {
	Legajo                  string    `json:"legajo"`
	Fechaperiodoliquidacion time.Time `json:"fechaperiodoliquidacion"`
	Concepto                string    `json:"concepto"`
	Importe                 float32   `json:"importe"`
}
type strLiquidacion struct {
	Fechaliquidacion time.Time `json:"fechaliquidacion"`
	Legajo           string    `json:"legajo"`
	Nombre           string    `json:"nombre"`
	Apellido         string    `json:"apellido"`
	Periodo          time.Time `json:"periodo"`
	Tipo             string    `json:"tipo"`
	Total            float32   `json:"total"`
}

type strImpresionEncabezado struct {
	Descripcion      string `json:"descripcion"`
	Nombreempresa    string `json:"nombreempresa"`
	Domicilioempresa string `json:"domicilioempresa"`
	Actividadempresa string `json:"actividadempresa"`
	Cuitempresa      string `json:"cuitempresa"`
}

type strImpresionLiquidaciones struct {
	Liquidacionid   int       `json:"liquidacionid"`
	Legajo          string    `json:"legajo"`
	Apellidonombre  string    `json:"apellidonombre"`
	Cuil            string    `json:"cuil"`
	Direccion       string    `json:"direccion"`
	Fechaalta       time.Time `json:"fechaalta"`
	Fechabaja       time.Time `json:"fechabaja"`
	Categoria       string    `json:"categoria"`
	Sueldojornal    float32   `json:"sueldojornal"`
	Sueldoperiodo   time.Time `json:"sueldoperiodo"`
	Contratacion    string    `json:"contratacion"`
	Conceptonombre  string    `json:"conceptonombre"`
	Conceptoimporte float32   `json:"conceptoimporte"`
	Tipogrilla      string    `json:"tipogrilla"`
}

func LibroSueldos(w http.ResponseWriter, r *http.Request) {
	fmt.Println("La URL accedida: " + r.URL.String())

	var strLiquidaciones []strLiquidacion
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)

		db.Raw("SELECT * FROM SP_INFORMELIBROSUELDOS('" + p_fechadesde + "','" + p_fechahasta + "')").Scan(&strLiquidaciones)
		framework.RespondJSON(w, http.StatusOK, strLiquidaciones)
	}

}

func ImpresionEncabezado(w http.ResponseWriter, r *http.Request) {
	fmt.Println("La URL accedida: " + r.URL.String())

	var strImpresionEncabezado strImpresionEncabezado
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)
		defer conexionBD.CerrarDB(db)

		strempresa := monoliticComunication.Obtenerdatosempresa(w, r, tokenAutenticacion, true)
		cuitEmpresa := strempresa.Cuit
		nombreEmpresa := strempresa.Nombre
		domicilioEmpresa := strempresa.Domicilio
		actividadEmpresa := strempresa.Actividadnombre

		strImpresionEncabezado.Descripcion = "Habilitación del registro de hojas móviles en reemplazo del libro especial Art. 52 LEY 20.744 (T.O.)"
		strImpresionEncabezado.Nombreempresa = nombreEmpresa
		strImpresionEncabezado.Domicilioempresa = domicilioEmpresa
		strImpresionEncabezado.Actividadempresa = actividadEmpresa
		strImpresionEncabezado.Cuitempresa = cuitEmpresa

		framework.RespondJSON(w, http.StatusOK, strImpresionEncabezado)
	}
}

func ImpresionLiquidaciones(w http.ResponseWriter, r *http.Request) {
	fmt.Println("La URL accedida: " + r.URL.String())
	var strImpresionLiquidaciones []strImpresionLiquidaciones
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)
		defer conexionBD.CerrarDB(db)

		db.Raw("SELECT * FROM SP_IMPRESIONLIBROSUELDOSLIQUIDACIONES('" + p_fechadesde + "','" + p_fechahasta + "')").Scan(&strImpresionLiquidaciones)

		framework.RespondJSON(w, http.StatusOK, strImpresionLiquidaciones)

	}
}
