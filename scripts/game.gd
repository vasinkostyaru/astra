extends Node
## Автолоад Game: список уровней, переходы, сохранение прогресса и общие звуки.

const LEVELS: Array[String] = [
	"res://levels/level_01_kids_room.tscn",
]
const SAVE_PATH := "user://save.cfg"

## Пентатоника: каждая следующая искорка звенит чуть выше.
const CHIME_NOTES: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98, 1760.0]
const CHIME_BASE := 523.25
const VOICES := 4

var current_level: int = 0
var completed_levels: Array[int] = []

var _chime: AudioStreamWAV
var _boing: AudioStreamWAV
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	_load_progress()
	_chime = _make_chime(CHIME_BASE)
	_boing = _make_boing()
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


func go_to_next_level() -> void:
	go_to_level(current_level + 1)


## Звон искорки; step — порядковый номер собранной искорки (с 1).
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
