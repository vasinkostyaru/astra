extends Node
## Автолоад Game: список уровней, переходы, сохранение прогресса и общие звуки.

const LEVELS: Array[String] = [
	"res://levels/level_01_kids_room.tscn",
	"res://levels/level_02_bathroom.tscn",
	"res://levels/level_03_kitchen.tscn",
	"res://levels/level_04_living_room.tscn",
]
const START_SCENE := "res://scenes/ui/start_screen.tscn"
const ROOMS_SCENE := "res://scenes/ui/room_select.tscn"
## Сколько комнат в доме всего (на экране выбора); построены пока только первые LEVELS.size().
const ROOM_COUNT := 4
const SAVE_PATH := "user://save.cfg"

## Пентатоника: каждая следующая ягодка звенит чуть выше.
const CHIME_NOTES: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98, 1760.0]
const CHIME_BASE := 523.25
const VOICES := 4

var current_level: int = 0
var completed_levels: Array[int] = []

var _chime: AudioStreamWAV
var _boing: AudioStreamWAV
var _thud: AudioStreamWAV
var _purr: AudioStreamWAV
var _splash: AudioStreamWAV
var _pop: AudioStreamWAV
var _gurgle: AudioStreamWAV
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	_load_progress()
	_chime = _make_chime(CHIME_BASE)
	_boing = _make_boing()
	_thud = _make_thud()
	_purr = _make_purr()
	_splash = _make_splash()
	_pop = _make_pop()
	_gurgle = _make_gurgle()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.stream = _chime
		p.volume_db = -6.0
		add_child(p)
		_voices.append(p)


func complete_level() -> void:
	if not completed_levels.has(current_level):
		completed_levels.append(current_level)
		_save_progress()


func go_to_level(index: int) -> void:
	if index < 0 or index >= LEVELS.size():
		return
	current_level = index
	get_tree().change_scene_to_file(LEVELS[index])


## После уровня — следующий; если дальше комнат ещё нет, возвращаемся к выбору комнаты.
func go_to_next_level() -> void:
	if current_level + 1 < LEVELS.size():
		go_to_level(current_level + 1)
	else:
		go_to_rooms()


func go_to_start() -> void:
	get_tree().change_scene_to_file(START_SCENE)


func go_to_rooms() -> void:
	get_tree().change_scene_to_file(ROOMS_SCENE)


func is_room_built(index: int) -> bool:
	return index >= 0 and index < LEVELS.size()


func is_room_completed(index: int) -> bool:
	return completed_levels.has(index)


## Звон ягодки; step — порядковый номер собранной ягодки (с 1).
func play_chime(step: int) -> void:
	var note := CHIME_NOTES[posmod(step - 1, CHIME_NOTES.size())]
	_play_note(note)


## Короткое радостное арпеджио, когда загорается главный светильник.
func play_fanfare() -> void:
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	for i in notes.size():
		get_tree().create_timer(0.13 * i).timeout.connect(_play_note.bind(notes[i]))


## Пружинистый «боинг» подушки-батута.
func play_boing() -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = _boing
	p.pitch_scale = 1.0
	p.play()


## Нота клавиши пианино-коврика (частота в герцах).
func play_note(freq: float) -> void:
	_play_note(freq)


## Глухой «бух» рассыпавшейся пирамиды.
func play_thud() -> void:
	_play_sample(_thud, 1.0)


## Всплеск воды.
func play_splash() -> void:
	_play_sample(_splash, 1.0)


## Вода уходит в слив: бульканье со скольжением тона вниз.
func play_gurgle() -> void:
	_play_sample(_gurgle, 1.0)


## Лопнул мыльный пузырь (тон чуть разный — пузыри не звучат одинаково).
func play_pop() -> void:
	_play_sample(_pop, randf_range(0.85, 1.25))


## Мурчание Астры.
func play_purr() -> void:
	_play_sample(_purr, 1.0)


func _play_sample(stream: AudioStreamWAV, pitch: float) -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


func _play_note(freq: float) -> void:
	var p := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	p.stream = _chime
	p.pitch_scale = freq / CHIME_BASE
	p.play()


## Колокольчик синтезируется в коде, чтобы не зависеть от аудиофайлов до появления ассетов.
func _make_chime(freq: float) -> AudioStreamWAV:
	var rate := 22050
	var length := 0.7
	var count := int(rate * length)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var env := minf(t / 0.005, 1.0) * exp(-t * 6.0)
		var s := sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 2.0 * t) + 0.15 * sin(TAU * freq * 3.01 * t)
		data.encode_s16(i * 2, int(clampf(s * env * 0.35, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


## Мягкий «пуф-боинг»: шорох ткани и короткий плавный подъём тона.
func _make_boing() -> AudioStreamWAV:
	var rate := 22050
	var length := 0.5
	var count := int(rate * length)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / rate
		var freq := lerpf(196.0, 294.0, smoothstep(0.0, 0.2, t))
		phase += TAU * freq / rate
		var tone := sin(phase) * minf(t / 0.02, 1.0) * exp(-t * 7.0)
		# Мягкий шум (сглаженный) — «пуф» подушки.
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.08)
		var puff := noise * exp(-t * 25.0) * 1.5
		data.encode_s16(i * 2, int(clampf((tone + puff) * 0.3, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


## «Бух»: низкий затухающий тон и шорох.
func _make_thud() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.45)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / rate
		phase += TAU * lerpf(110.0, 55.0, minf(t * 4.0, 1.0)) / rate
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.25)
		var s := sin(phase) * exp(-t * 9.0) + noise * exp(-t * 18.0) * 0.6
		data.encode_s16(i * 2, int(clampf(s * 0.5, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


## Мурчание: низкий тон с быстрой дрожью громкости.
func _make_purr() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 1.6)
	var data := PackedByteArray()
	data.resize(count * 2)
	var noise := 0.0
	for i in count:
		var t := float(i) / rate
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.06)
		var rumble := 0.5 + 0.5 * sin(TAU * 24.0 * t)
		var env := minf(t / 0.2, 1.0) * minf((1.6 - t) / 0.4, 1.0)
		var s := (sin(TAU * 62.0 * t) * 0.5 + noise * 0.8) * rumble * env
		data.encode_s16(i * 2, int(clampf(s * 0.45, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


## Всплеск: плавный шум с быстрым спадом.
func _make_splash() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.7)
	var data := PackedByteArray()
	data.resize(count * 2)
	var noise := 0.0
	for i in count:
		var t := float(i) / rate
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.35 - 0.25 * minf(t * 2.0, 1.0))
		var s := noise * minf(t / 0.02, 1.0) * exp(-t * 5.5)
		data.encode_s16(i * 2, int(clampf(s * 0.8, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


## Пузырь: короткий высокий «пик» со скольжением вниз.
func _make_pop() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 0.18)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / rate
		phase += TAU * lerpf(1400.0, 500.0, minf(t * 8.0, 1.0)) / rate
		var s := sin(phase) * exp(-t * 28.0)
		data.encode_s16(i * 2, int(clampf(s * 0.5, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _make_gurgle() -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * 2.2)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / rate
		var freq := lerpf(330.0, 120.0, t / 2.2) + sin(t * 31.0) * 60.0
		phase += TAU * freq / rate
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.2)
		var wob := 0.5 + 0.5 * sin(t * 24.0)
		var env := minf(t / 0.1, 1.0) * minf((2.2 - t) / 0.5, 1.0)
		var s := (sin(phase) * 0.45 + noise * 0.35) * wob * env
		data.encode_s16(i * 2, int(clampf(s * 0.7, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i: int in cfg.get_value("progress", "completed", []):
		completed_levels.append(i)


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "completed", completed_levels)
	cfg.save(SAVE_PATH)
