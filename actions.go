package main

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/monoliticComunication"
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

type Exportartxtcargasocialesf931 struct {
	Data string `json:"data"`
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
	Descripcion       string `json:"descripcion"`
	Razonsocialnombre string `json:"razonsocialnombre"`
	Domicilioempresa  string `json:"domicilioempresa"`
	Actividadempresa  string `json:"actividadempresa"`
	Cuitempresa       string `json:"cuitempresa"`
	Desdehojanumero   string `json:"desdehojanumero"`
	Hastahojanumero   string `json:"hastahojanumero"`
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

// Sirve para controlar si el server esta OK
func Healthy(writer http.ResponseWriter, request *http.Request) {
	writer.Write([]byte("Healthy."))
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

func ImpresionEncabezado(w http.ResponseWriter, r *http.Request) {
	fmt.Println("La URL accedida: " + r.URL.String())

	var strImpresionEncabezado strImpresionEncabezado
	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		//var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		//var p_fechahasta string = r.URL.Query()["fechahasta"][0]
		var p_hojadesde string = r.URL.Query()["hojadesde"][0]
		var p_hojahasta string = r.URL.Query()["hojahasta"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)

		db := conexionBD.ObtenerDB(tenant)
		defer conexionBD.CerrarDB(db)

		strempresa := monoliticComunication.Obtenerdatosempresa(w, r, tokenAutenticacion)
		cuitEmpresa := strempresa.Cuit
		nombreEmpresa := strempresa.Nombre
		domicilioEmpresa := strempresa.Domicilio
		actividadEmpresa := strempresa.Actividadnombre

		strImpresionEncabezado.Descripcion = "HABILITACION DEL REGISTRO DE HOJAS MOVILES EN REEMPLAZO DEL LIBRO ESPECIAL ART. 52 LEY 20.744 (T.O.)"
		strImpresionEncabezado.Razonsocialnombre = nombreEmpresa
		strImpresionEncabezado.Domicilioempresa = domicilioEmpresa
		strImpresionEncabezado.Actividadempresa = actividadEmpresa
		strImpresionEncabezado.Cuitempresa = cuitEmpresa
		strImpresionEncabezado.Desdehojanumero = p_hojadesde
		strImpresionEncabezado.Hastahojanumero = p_hojahasta

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
