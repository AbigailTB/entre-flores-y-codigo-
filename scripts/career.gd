extends Node
## La carrera de TI por cuatrimestres: qué maestro va en cada uno, cuánto daño hace
## fallar en su materia, qué se desbloquea y qué premios se ganan.

const START_HEARTS := 5

## Cuatrimestres en orden. "final" es el examen con el profe Efrén.
const CUATRIS := [
	{"id": 1, "nombre": "1er cuatrimestre", "dificultad": "Fácil", "teachers": ["hermes", "juvencio", "gladis"], "premio_ropa": "camisa_verde"},
	{"id": 2, "nombre": "2do cuatrimestre", "dificultad": "Fácil - media", "teachers": ["heidy", "bety", "richi"], "premio_ropa": "camisa_roja"},
	{"id": 3, "nombre": "3er cuatrimestre", "dificultad": "Media", "teachers": ["ana", "jose", "carlos"], "premio_ropa": "camisa_morada"},
	{"id": 4, "nombre": "4to cuatrimestre", "dificultad": "Difícil", "teachers": ["yuls", "gadiel", "luis"], "premio_ropa": "camisa_turquesa"},
	{"id": 5, "nombre": "Examen final", "dificultad": "Experto", "teachers": ["efren"], "premio_ropa": "camisa_amarilla"},
]

## dano: corazones que quita cada respuesta incorrecta. preguntas: tamaño del reto.
const TEACHERS := {
	"hermes":   {"nombre": "Prof. Hermes", "materia": "Metodología de la Investigación", "room": "metodologia_apa", "dano": 1, "preguntas": 4},
	"juvencio": {"nombre": "Prof. Juvencio", "materia": "Análisis y Documentación", "room": "documentacion", "dano": 1, "preguntas": 4},
	"gladis":   {"nombre": "Profa. Gladis", "materia": "Metodologías Ágiles", "room": "metodologias_agiles", "dano": 1, "preguntas": 4},
	"heidy":    {"nombre": "Profa. Heidy", "materia": "Matemáticas", "room": "matematicas", "dano": 1, "preguntas": 5},
	"bety":     {"nombre": "Profa. Bety", "materia": "Administración de Proyectos", "room": "proyectos", "dano": 1, "preguntas": 5},
	"richi":    {"nombre": "Prof. Richi", "materia": "Bases de Datos", "room": "richi", "dano": 2, "preguntas": 5},
	"ana":      {"nombre": "Profa. Ana", "materia": "Seguridad Informática", "room": "seguridad", "dano": 2, "preguntas": 5},
	"jose":     {"nombre": "Prof. José", "materia": "Redes de Computadoras", "room": "redes", "dano": 2, "preguntas": 5},
	"carlos":   {"nombre": "Prof. Carlos", "materia": "Programación Web", "room": "web_pwa", "dano": 2, "preguntas": 5},
	"yuls":     {"nombre": "Profa. Yuls", "materia": "Cálculo", "room": "calculo", "dano": 3, "preguntas": 6},
	"gadiel":   {"nombre": "Prof. Gadiel", "materia": "Programación Móvil", "room": "prog_movil", "dano": 3, "preguntas": 6},
	"luis":     {"nombre": "Prof. Luis", "materia": "Programación", "room": "programacion", "dano": 3, "preguntas": 6},
	"efren":    {"nombre": "Profesor Efrén", "materia": "*", "room": "", "dano": 3, "preguntas": 8},
}

## Rangos según el AURA acumulada.
const RANKS := [
	[0, "Nuevo ingreso"],
	[1500, "Estudiante"],
	[4500, "Estudiante avanzado"],
	[9000, "Experto"],
	[14000, "Leyenda TI"],
]

func teacher(id: String) -> Dictionary:
	return TEACHERS.get(id, {})

func cuatri_of(teacher_id: String) -> Dictionary:
	for c in CUATRIS:
		if teacher_id in c["teachers"]:
			return c
	return {}

func teacher_for_room(room: String) -> String:
	for id in TEACHERS:
		if TEACHERS[id]["room"] == room:
			return id
	return ""

func is_cuatri_passed(cuatri_id: int) -> bool:
	for c in CUATRIS:
		if c["id"] == cuatri_id:
			for t in c["teachers"]:
				if not GameManager.is_teacher_defeated(t):
					return false
			return true
	return false

func is_cuatri_unlocked(cuatri_id: int) -> bool:
	return cuatri_id <= 1 or is_cuatri_passed(cuatri_id - 1)

func is_teacher_unlocked(teacher_id: String) -> bool:
	var c := cuatri_of(teacher_id)
	return not c.is_empty() and is_cuatri_unlocked(c["id"])

## Cuatrimestre que el jugador está cursando ahora (el primero sin aprobar).
func current_cuatri() -> Dictionary:
	for c in CUATRIS:
		if not is_cuatri_passed(c["id"]):
			return c
	return CUATRIS[-1]

func career_finished() -> bool:
	return is_cuatri_passed(CUATRIS[-1]["id"])

func rank_name(xp: int = -1) -> String:
	if xp < 0:
		xp = GameManager.xp
	var result: String = RANKS[0][1]
	for r in RANKS:
		if xp >= r[0]:
			result = r[1]
	return result

func next_rank_xp() -> int:
	for r in RANKS:
		if GameManager.xp < r[0]:
			return r[0]
	return -1

## AURA que da un acierto y la que quita un error (según la dificultad).
func aura_per_correct(teacher_id: String) -> int:
	return 100 * int(teacher(teacher_id).get("dano", 1))

func aura_per_wrong(teacher_id: String) -> int:
	return -25 * int(teacher(teacher_id).get("dano", 1))

func badge_name(badge_id: String) -> String:
	if badge_id.begins_with("cuatri_"):
		var n := int(badge_id.trim_prefix("cuatri_"))
		for c in CUATRIS:
			if c["id"] == n:
				return "🎓 " + c["nombre"]
	if badge_id.begins_with("maestro_"):
		var t := teacher(badge_id.trim_prefix("maestro_"))
		if not t.is_empty():
			return "🏅 " + t["nombre"]
	if badge_id == "sin_danio":
		return "💖 Reto perfecto"
	return badge_id

## Registra que se aprobó a un maestro y devuelve las líneas de premio para mostrar.
func on_teacher_beaten(teacher_id: String, hearts_left: int) -> Array:
	var lines: Array = []
	var first_time := not GameManager.is_teacher_defeated(teacher_id)
	var t := teacher(teacher_id)
	var c := cuatri_of(teacher_id)
	var bonus_xp := 500 * int(t.get("dano", 1)) if first_time else 150
	var bonus_money := 30 * int(c.get("id", 1)) if first_time else 0
	GameManager.add_xp(bonus_xp)
	if bonus_money > 0:
		GameManager.add_money(bonus_money)
	if not first_time:
		lines.append("Repaso completado: +%d AURA." % bonus_xp)
		return lines
	GameManager.mark_teacher_defeated(teacher_id)
	lines.append("¡Aprobaste %s! +%d AURA y +$%d." % [t["materia"] if t["materia"] != "*" else "el examen final", bonus_xp, bonus_money])
	GameManager.add_badge("maestro_" + teacher_id)
	if hearts_left >= START_HEARTS and GameManager.add_badge("sin_danio"):
		lines.append("Nueva insignia: 💖 Reto perfecto (sin perder corazones).")
	if not c.is_empty() and is_cuatri_passed(c["id"]):
		GameManager.add_badge("cuatri_%d" % c["id"])
		lines.append("🎓 ¡Terminaste el %s! Ganaste su insignia." % c["nombre"])
		var outfit: String = c.get("premio_ropa", "")
		if outfit != "" and not OutfitManager.is_unlocked(outfit):
			GameManager.unlock_outfit(outfit)
			lines.append("👕 Desbloqueaste ropa nueva en el ropero: %s." % OutfitManager.find_outfit(outfit).get("nombre", outfit))
		var idx := CUATRIS.find(c)
		if idx >= 0 and idx + 1 < CUATRIS.size():
			lines.append("🔓 Se abrió el %s. ¡Ve al campus!" % CUATRIS[idx + 1]["nombre"])
		else:
			lines.append("🏆 ¡Terminaste la carrera de TI! Eres %s." % rank_name())
	lines.append("Rango actual: %s (%d AURA)." % [rank_name(), GameManager.xp])
	return lines
