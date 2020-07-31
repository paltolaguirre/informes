package librosueldosdigital

import (
	"fmt"
	"net/http"
	"strconv"
	s "strings"
	"time"

	"github.com/schigh/str"
	"github.com/xubiosueldos/autenticacion/apiclientautenticacion"
	"github.com/xubiosueldos/conexionBD"
	"github.com/xubiosueldos/framework"
	"github.com/xubiosueldos/monoliticComunication"
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

func LibroSueldosDigitalExportarTxtLiquidacionesPeriodo(w http.ResponseWriter, r *http.Request) {

	var exportartxtliquidacionesperiodoregistrodos []Exportartxtlibrosueldosdigital
	var exportartxtliquidacionesperiodoregistrotres []Exportartxtlibrosueldosdigital
	var exportartxtliquidacionesperiodoregistrocuatro []Exportartxtlibrosueldosdigital
	var datosexportartxtliquidacionesperiodo Exportartxtlibrosueldosdigital

	fmt.Println("La URL accedida: " + r.URL.String())

	tokenValido, tokenAutenticacion := apiclientautenticacion.CheckTokenValido(w, r)
	if tokenValido {

		queries := r.URL.Query()

		tenant := apiclientautenticacion.ObtenerTenant(tokenAutenticacion)
		db := conexionBD.ObtenerDB(tenant)

		defer conexionBD.CerrarDB(db)

		p_tipoliquidacion := queries["tipoliquidacion"][0]
		p_periodomensual := queries["periodomensual"][0]
		p_importedetraccion := queries["importedetraccion"][0]

		periodomensual := s.Split(p_periodomensual, "-")
		liquidaciontipo := "H"
		if p_tipoliquidacion == "MENSUAL" {
			liquidaciontipo = "M"
		} else {
			if p_tipoliquidacion == "QUINCENAL" {
				liquidaciontipo = "D"
			}
		}

		strempresa := monoliticComunication.Obtenerdatosempresa(w, r, tokenAutenticacion, true)
		cuitempresa := strempresa.Cuit
		correspondereduccionempresa := strempresa.Reducevalor
		tipoempresa := strempresa.Tipodeempresa
		actividadempresa := strempresa.Actividad
		zonaempresa := strempresa.Zona

		if cuitempresa == "" {
			framework.RespondError(w, http.StatusNotFound, "Debe completar el CUIT del Agente de Retención ")
			return
		}
		esmensual := true

		if p_tipoliquidacion != "MENSUAL" {
			esmensual = false
		}

		db.Raw("SELECT * FROM SP_EXPORTARTXTLIBROSUELDOSDIGITALLIQUIDACIONESPERIODOREGISTRODOS(" + strconv.FormatBool(esmensual) + ",'" + p_periodomensual + "')").Scan(&exportartxtliquidacionesperiodoregistrodos)
		db.Raw("SELECT * FROM SP_EXPORTARTXTLIBROSUELDOSDIGITALLIQUIDACIONESPERIODOREGISTROTRES(" + strconv.FormatBool(esmensual) + ",'" + p_periodomensual + "')").Scan(&exportartxtliquidacionesperiodoregistrotres)
		db.Raw("SELECT * FROM SP_EXPORTARTXTLIBROSUELDOSDIGITALLIQUIDACIONESPERIODOREGISTROCUATRO('" + strconv.Itoa(correspondereduccionempresa) + "','" + strconv.Itoa(tipoempresa) + "','" + actividadempresa + "','" + zonaempresa + "'," + strconv.FormatBool(esmensual) + ",'" + p_periodomensual + "'," + p_importedetraccion + ")").Scan(&exportartxtliquidacionesperiodoregistrocuatro)

		cantidad := str.Pad(strconv.Itoa(len(exportartxtliquidacionesperiodoregistrocuatro)), "0", 6, str.PadLeft)
		numeroliquidacion := str.Pad(periodomensual[0][2:4]+periodomensual[1], "0", 5, str.PadLeft)

		datosexportartxtliquidacionesperiodo.Data = "01" + s.ReplaceAll(cuitempresa, "-", "") + "SJ" + periodomensual[0] + periodomensual[1] + liquidaciontipo + numeroliquidacion + "30" + cantidad + "\n"
		fmt.Println(datosexportartxtliquidacionesperiodo.Data)
		for i := 0; i < len(exportartxtliquidacionesperiodoregistrodos); i++ {

			datosexportartxtliquidacionesperiodo.Data = datosexportartxtliquidacionesperiodo.Data + exportartxtliquidacionesperiodoregistrodos[i].Data + "\n"

		}
		for i := 0; i < len(exportartxtliquidacionesperiodoregistrotres); i++ {

			datosexportartxtliquidacionesperiodo.Data = datosexportartxtliquidacionesperiodo.Data + exportartxtliquidacionesperiodoregistrotres[i].Data + "\n"

		}
		for i := 0; i < len(exportartxtliquidacionesperiodoregistrocuatro); i++ {

			datosexportartxtliquidacionesperiodo.Data = datosexportartxtliquidacionesperiodo.Data + exportartxtliquidacionesperiodoregistrocuatro[i].Data + "\n"

		}
		framework.RespondJSON(w, http.StatusOK, datosexportartxtliquidacionesperiodo)
	}
}
