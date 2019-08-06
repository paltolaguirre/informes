package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/xubiosueldos/framework/configuracion"
)

func main() {
	configuracion := configuracion.GetInstance()
	router := newRouter()

	server := http.ListenAndServe(":"+configuracion.Puertomicroservicioinformes, router)
	fmt.Println("Microservicio de Informes escuchando en el puerto: " + configuracion.Puertomicroservicioinformes)

	log.Fatal(server)

}
