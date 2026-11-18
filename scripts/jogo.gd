extends Node2D
# Matheus Lucas Gonçalves - 802.387 | Defesa: 180 segundos, 5 toques
const LARGURA := 1152.0
const ALTURA := 648.0
const CENTRO := Vector2(576, 324)
const TEMPO_MAX := 180.0
const MAX_TOQUES := 5
const VELOCIDADE := 280.0
const ALCANCE := 95.0
var jogador := Vector2(576, 495)
var tempo := TEMPO_MAX
var toques := 0
var abates := 0
var inimigos: Array[Dictionary] = []
var particulas: Array[Dictionary] = []
var surgimento := 1.8
var ataque_cooldown := 0.0
var invulneravel := 0.0
var estado := "inicio"
var rng := RandomNumberGenerator.new()
var hud: Label
var aviso: Label

func _ready() -> void:
	rng.randomize()
	hud = Label.new()
	hud.position = Vector2(22, 15)
	hud.add_theme_font_size_override("font_size", 23)
	hud.add_theme_color_override("font_color", Color(1, 0.92, 0.76))
	add_child(hud)
	aviso = Label.new()
	aviso.position = Vector2(165, 215)
	aviso.size = Vector2(820, 240)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	aviso.add_theme_font_size_override("font_size", 31)
	aviso.add_theme_color_override("font_color", Color(1, 0.92, 0.72))
	add_child(aviso)
	atualizar_texto()

func _process(delta: float) -> void:
	if estado == "inicio":
		if Input.is_key_pressed(KEY_ENTER):
			reiniciar()
	elif estado == "jogando":
		atualizar_jogo(delta)
	else:
		if Input.is_key_pressed(KEY_ENTER):
			reiniciar()
	atualizar_texto()
	queue_redraw()

func reiniciar() -> void:
	jogador = Vector2(576, 495)
	tempo = TEMPO_MAX
	toques = 0
	abates = 0
	inimigos.clear()
	particulas.clear()
	surgimento = 1.8
	ataque_cooldown = 0.0
	invulneravel = 0.0
	estado = "jogando"

func atualizar_jogo(delta: float) -> void:
	tempo -= delta
	if tempo <= 0.0:
		tempo = 0.0
		estado = "vitoria"
		return
	var direcao := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direcao.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direcao.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direcao.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direcao.y += 1
	jogador += direcao.normalized() * VELOCIDADE * delta
	jogador.x = clampf(jogador.x, 75, LARGURA - 75)
	jogador.y = clampf(jogador.y, 85, ALTURA - 65)
	ataque_cooldown = maxf(0, ataque_cooldown - delta)
	invulneravel = maxf(0, invulneravel - delta)
	if Input.is_key_pressed(KEY_SPACE) and ataque_cooldown <= 0:
		ataque_cooldown = 0.34
		var restantes: Array[Dictionary] = []
		for inimigo in inimigos:
			if jogador.distance_to(inimigo["pos"]) <= ALCANCE:
				abates += 1
				criar_particulas(inimigo["pos"])
			else:
				restantes.append(inimigo)
		inimigos = restantes
	surgimento -= delta
	if surgimento <= 0:
		criar_inimigo()
		surgimento = maxf(0.48, 2.15 - (TEMPO_MAX - tempo) * 0.008)
	var vivos: Array[Dictionary] = []
	for inimigo in inimigos:
		var pos: Vector2 = inimigo["pos"]
		var dir := pos.direction_to(CENTRO)
		pos += dir * float(inimigo["vel"]) * delta
		inimigo["pos"] = pos
		if pos.distance_to(CENTRO) < 37:
			toques += 1
			criar_particulas(pos)
			if toques >= MAX_TOQUES:
				estado = "derrota"
				break
		else:
			vivos.append(inimigo)
	inimigos = vivos
	for i in range(particulas.size() - 1, -1, -1):
		particulas[i]["vida"] -= delta
		if particulas[i]["vida"] <= 0:
			particulas.remove_at(i)

func criar_inimigo() -> void:
	var angulo := rng.randf_range(0, TAU)
	var pos := CENTRO + Vector2(cos(angulo) * 610, sin(angulo) * 390)
	pos.x = clampf(pos.x, 25, LARGURA - 25)
	pos.y = clampf(pos.y, 75, ALTURA - 25)
	inimigos.append({"pos": pos, "vel": rng.randf_range(48, 78), "fase": rng.randf_range(0, TAU)})

func criar_particulas(pos: Vector2) -> void:
	for i in 8:
		particulas.append({"pos": pos + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30)), "vida": 0.45})

func atualizar_texto() -> void:
	hud.text = "CRATERA DE VULCÃO     |     Tempo: %02d:%02d     |     Cristal: %d/5     |     Abates: %d" % [int(tempo / 60.0), int(tempo) % 60, MAX_TOQUES - toques, abates]
	if estado == "inicio":
		aviso.text = "CRATERA DE VULCÃO\nDEFENDA O CRISTAL POR 3 MINUTOS\nWASD / SETAS: mover  |  ESPAÇO: atacar\nENTER PARA COMEÇAR"
	elif estado == "vitoria":
		aviso.text = "VOCÊ VENCEU!\nO cristal resistiu aos 3 minutos!\nInimigos derrotados: %d\nENTER PARA RECOMEÇAR" % abates
	elif estado == "derrota":
		aviso.text = "VOCÊ PERDEU!\nO cristal recebeu 5 ataques.\nInimigos derrotados: %d\nENTER PARA TENTAR NOVAMENTE" % abates
	else:
		aviso.text = ""

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(LARGURA, ALTURA)), Color("1c101b"))
	# Rochas concêntricas e rios de lava
	draw_circle(CENTRO, 280, Color("39232a"))
	draw_circle(CENTRO, 240, Color("56302b"))
	draw_circle(CENTRO, 202, Color("2b1d25"))
	for i in 18:
		var a := float(i) * TAU / 18.0
		var start := CENTRO + Vector2(cos(a), sin(a)) * 245
		var end := CENTRO + Vector2(cos(a + 0.1), sin(a + 0.1)) * 380
		draw_line(start, end, Color("e94a1d"), 9)
		draw_line(start, end, Color("ffae32"), 3)
	for i in 26:
		var a := float(i) * 2.4
		var r := 125.0 + float(i % 5) * 42.0
		var rock := CENTRO + Vector2(cos(a), sin(a)) * r
		draw_circle(rock, 10 + (i % 3) * 3, Color("6a4940"))
		draw_circle(rock + Vector2(-3, -4), 4, Color("987064"))
	# Pedestal e cristal central
	draw_circle(CENTRO + Vector2(0, 8), 49, Color("110e1b"))
	draw_circle(CENTRO, 37, Color("70616d"))
	draw_circle(CENTRO, 29, Color("a88676"))
	var cristal := PackedVector2Array([CENTRO + Vector2(0, -29), CENTRO + Vector2(23, 0), CENTRO + Vector2(0, 30), CENTRO + Vector2(-23, 0)])
	draw_colored_polygon(cristal, Color("55e5e1") if toques < 4 else Color("ff5447"))
	draw_line(CENTRO + Vector2(0, -25), CENTRO, Color("d7ffff"), 3)
	draw_line(CENTRO, CENTRO + Vector2(0, 25), Color("187e9b"), 3)
	# Jogador com armadura
	draw_circle(jogador + Vector2(0, 10), 17, Color(0, 0, 0, 0.4))
	draw_circle(jogador, 16, Color("4389c5"))
	draw_circle(jogador + Vector2(0, -6), 11, Color("bfeaff"))
	draw_rect(Rect2(jogador + Vector2(-5, -10), Vector2(10, 5)), Color("1e385d"))
	if ataque_cooldown > 0.19:
		draw_arc(jogador, ALCANCE, 0, TAU, 48, Color("ffe27a"), 6)
	# Criaturas de lava
	for inimigo in inimigos:
		var pos: Vector2 = inimigo["pos"]
		draw_circle(pos + Vector2(0, 6), 18, Color(0, 0, 0, 0.35))
		draw_circle(pos, 16, Color("b52a1e"))
		draw_circle(pos + Vector2(0, -5), 11, Color("fa5b1f"))
		draw_circle(pos + Vector2(-5, -6), 3, Color("ffe46a"))
		draw_circle(pos + Vector2(5, -6), 3, Color("ffe46a"))
		draw_line(pos + Vector2(-7, 7), pos + Vector2(7, 7), Color("ffb72b"), 3)
	for particula in particulas:
		draw_circle(particula["pos"], 4, Color("ffbd48", float(particula["vida"]) / 0.45))
	if estado != "jogando":
		draw_rect(Rect2(Vector2(125, 185), Vector2(900, 275)), Color(0.05, 0.035, 0.08, 0.89))
