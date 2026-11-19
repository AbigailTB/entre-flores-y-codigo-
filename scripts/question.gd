class_name Question
extends Resource

@export var materia: String = "Desarrollo de Software"
## "Pregunta" o "Acertijo"
@export var tipo: String = "Pregunta"
@export var enunciado: String = ""
## Fragmento de código opcional que se muestra en un recuadro tipo editor.
@export_multiline var codigo: String = ""
@export var opciones: Array[String] = []
@export var respuesta_correcta: int = 0
@export var explicacion: String = ""
@export var puntos: int = 10
