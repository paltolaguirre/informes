package main

import (
	"net/http"

	"github.com/gorilla/mux"
	"github.com/xubiosueldos/informes/cargassocialesf931"
	"github.com/xubiosueldos/informes/librosueldos"
)

type Route struct {
	Name       string
	Method     string
	Pattern    string
	HandleFunc http.HandlerFunc
}

type Routes []Route

func newRouter() *mux.Router {
	router := mux.NewRouter().StrictSlash(true)

	for _, route := range routes {
		router.Methods(route.Method).
			Path(route.Pattern).
			Name(route.Name).
			Handler(route.HandleFunc)

	}

	return router
}

var routes = Routes{
	Route{
		"Healthy",
		"GET",
		"/api/informe/healthy",
		Healthy,
	},
	Route{
		"InformeF931",
		"GET",
		"/api/informe/informes/cargas-sociales-f931",
		cargassocialesf931.InformeF931,
	},
	Route{
		"LibroSueldos",
		"GET",
		"/api/informe/informes/libro-sueldos",
		librosueldos.LibroSueldos,
	},
	Route{
		"InformeF931ExportarTxt",
		"GET",
		"/api/informe/informes/cargas-sociales-f931-exportartxt",
		cargassocialesf931.InformeF931ExportarTxt,
	},
	Route{
		"ImpresionEncabezado",
		"GET",
		"/api/informe/informes/libro-sueldos/impresion-encabezado",
		librosueldos.ImpresionEncabezado,
	},
	Route{
		"ImpresionLiquidaciones",
		"GET",
		"/api/informe/informes/libro-sueldos/impresion-liquidaciones",
		librosueldos.ImpresionLiquidaciones,
	},
}
