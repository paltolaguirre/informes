package main

import (
	"net/http"
)

var nombreMicroservicio string = "informes"

// Sirve para controlar si el server esta OK
func Healthy(writer http.ResponseWriter, request *http.Request) {
	writer.Write([]byte("Healthy."))
}
