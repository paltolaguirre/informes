package main

import "github.com/gorilla/mux"
import "net/http"

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
		InformeF931,
	},
	Route{
		"LibroSueldos",
		"GET",
		"/api/informe/informes/libro-sueldos",
		LibroSueldos,
	},
	Route{
		"InformeF931ExportarTxt",
		"GET",
		"/api/informe/informes/cargas-sociales-f931-exportartxt",
		InformeF931ExportarTxt,
	},
	Route{
		"ImpresionEncabezado",
		"GET",
		"/api/informe/informes/libro-sueldos/impresion-encabezado",
		ImpresionEncabezado,
	},
	Route{
		"ImpresionLiquidaciones",
		"GET",
		"/api/informe/informes/libro-sueldos/impresion-liquidaciones",
		ImpresionLiquidaciones,
	},
}
