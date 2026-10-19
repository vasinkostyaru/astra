extends MenuScreen
## Выбор комнаты картинками. Построенные комнаты открываются, остальные приглушены.
## Пройденная комната — золотая рамка и горящая лампочка.

const CARD := 0.5   # высота карточки в долях высоты экрана
const GAP := 0.05

var _cards: Array[RoomCard] = []
var _back: PictureButton
var _restart: RestartButton


func _ready() -> void:
	build_ui()
	for i in Game.ROOM_COUNT:
		var card := RoomCard.new()
		card.room = i
		card.built = Game.is_room_built(i)
		card.completed = Game.is_room_completed(i)
		card.pressed.connect(_on_card.bind(card))
		ui.add_child(card)
		_cards.append(card)
	_back = PictureButton.new()
	_back.kind = PictureButton.Kind.BACK
	_back.pressed.connect(func() -> void: leave(Game.go_to_start))
	ui.add_child(_back)
	_restart = RestartButton.new()
	_restart.held.connect(_on_restart)
	ui.add_child(_restart)
	ui.get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vs := ui.get_viewport().get_visible_rect().size
	var h := vs.y * CARD
	var w := h * 0.9
	var gap := vs.y * GAP
	var total := _cards.size() * w + (_cards.size() - 1) * gap
	# На узком экране сжимаем карточки, чтобы все четыре поместились.
	var k := minf(1.0, (vs.x * 0.94) / total)
	h *= k
	w *= k
	gap *= k
	total = _cards.size() * w + (_cards.size() - 1) * gap
	for i in _cards.size():
		_cards[i].size = Vector2(w, h)
		_cards[i].position = Vector2((vs.x - total) * 0.5 + i * (w + gap), vs.y * 0.5 - h * 0.5)
	var b := vs.y * 0.16
	_back.size = Vector2(b, b)
	_back.position = Vector2(vs.y * 0.04, vs.y * 0.04)
	_restart.size = Vector2(b, b)
	_restart.position = Vector2(vs.x - b - vs.y * 0.04, vs.y * 0.04)


func _on_card(card: RoomCard) -> void:
	if card.built:
		leave(Game.go_to_level.bind(card.room))
	else:
		card.wobble()


## «Сначала»: пройденные комнаты забываются, снова показывается интро, потом — выбор комнаты заново.
func _on_restart() -> void:
	Game.reset_progress()
	Cutscenes.reset_played()
	Cutscenes.play(&"intro")
	await Cutscenes.finished
	leave(Game.go_to_rooms)
