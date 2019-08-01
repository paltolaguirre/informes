package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"

	"github.com/jinzhu/gorm"
	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD/apiclientconexionbd"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/framework/configuracion"
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

type strEmpresa struct {
	ID                     int    `json:"id"`
	Nombre                 string `json:"nombre"`
	Codigo                 string `json:"codigo"`
	Descripcion            string `json:"descripcion"`
	Domicilio              string `json:"domicilio"`
	Localidad              string `json:"localidad"`
	Cuit                   string `json:"cuit"`
	Tipodeempresa          int    `json:"tipodeempresa"`
	Actividad              int    `json:"actividad"`
	Zona                   int    `json:"zona"`
	Zonanombre             string `json:"zonanombre"`
	Obrasocial             int    `json:"obrasocial"`
	Artcontratada          int    `json:"artcontratada"`
	Domiciliodeexplotacion string `json:"domiciliodeexplotacion"`
	Reducevalor            int    `json:"reducevalor"`
}

type Exportartxtcargasocialesf931 struct {
	Data string `json:"data"`
}

// Sirve para controlar si el server esta OK
func Healthy(writer http.ResponseWriter, request *http.Request) {
	writer.Write([]byte("Healthy."))
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

func InformeF931ExportarTxt(w http.ResponseWriter, r *http.Request) {

	var exportartxtcargasocialesf931 []Exportartxtcargasocialesf931
	var datosaexportartxtcargassocialesf931 Exportartxtcargasocialesf931

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		var p_fechadesde string = r.URL.Query()["fechadesde"][0]
		var p_fechahasta string = r.URL.Query()["fechahasta"][0]
		var p_importeretraccion string = r.URL.Query()["importeretraccion"][0]

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := apiclientconexionbd.ObtenerDB(tenant, nombreMicroservicio, 1, AutomigrateTablasPrivadas)

		defer apiclientconexionbd.CerrarDB(db)

		strempresa := obtenerDatosEmpleador(db, r)

		actividad := strconv.Itoa(strempresa.Actividad)
		tipodeempresa := strconv.Itoa(strempresa.Tipodeempresa)
		zona := strconv.Itoa(strempresa.Zona)
		reducevalor := strconv.Itoa(strempresa.Reducevalor)
		zonanombre := strempresa.Zonanombre

		db.Raw("SELECT * FROM SP_EXPORTARTXTCARGASSOCIALESF931('" + p_fechadesde + "','" + p_fechahasta + "','" + actividad + "','" + tipodeempresa + "','" + zona + "','" + zonanombre + "','" + reducevalor + "','" + p_importeretraccion + "')").Scan(&exportartxtcargasocialesf931)

		for i := 0; i < len(exportartxtcargasocialesf931); i++ {

			datosaexportartxtcargassocialesf931.Data = datosaexportartxtcargassocialesf931.Data + exportartxtcargasocialesf931[i].Data + "\n"

		}
		fmt.Println(datosaexportartxtcargassocialesf931)
		framework.RespondJSON(w, http.StatusOK, datosaexportartxtcargassocialesf931)
	}

}

func obtenerDatosEmpleador(db *gorm.DB, r *http.Request) *strEmpresa {
	var strempresa strEmpresa

	config := configuracion.GetInstance()

	url := configuracion.GetUrlMicroservicio(config.Puertomicroserviciohelpers) + "empresa/empresas"
	req, err := http.NewRequest("GET", url, nil)

	if err != nil {
		fmt.Println("Error: ", err)
	}

	header := r.Header.Get("Authorization")

	req.Header.Add("Authorization", header)

	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	res, err := http.DefaultClient.Do(req)

	if err != nil {
		fmt.Println("Error: ", err)
	}

	fmt.Println("URL:", url)

	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)

	if err != nil {
		fmt.Println("Error: ", err)
	}

	str := string(body)

	json.Unmarshal([]byte(str), &strempresa)

	return &strempresa

}

func AutomigrateTablasPrivadas(db *gorm.DB) {

}
