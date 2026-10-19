class_name CutAudio
extends Node
## Звуки роликов: синтезируются в коде, пока нет файлов. Готовые CC0-звуки подставляются
## заменой потоков в _ready или переопределением методов — интерфейс для ролика не меняется.

const RATE := 22050

@export var volume_db: float = -9.0

var _pif: AudioStreamWAV
var _sparkle: AudioStreamWAV
var _shimmer: AudioStreamWAV
var _chime: AudioStreamWAV
var _tap: AudioStreamWAV
var _purr: AudioStreamWAV
var _melody: AudioStreamWAV
var _door: AudioStreamWAV


func _exit_tree() -> void:
	# Не оставляем играющие потоки при пропуске/выходе.
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()


func _ready() -> void:
	_pif = _make_pif()
	_sparkle = _make_sparkle()
	_shimmer = _make_shimmer()
	_chime = _make_chime()
	_tap = _make_tap()
	_purr = _make_purr()
	_melody = _make_melody()
	_door = _make_door()


## «Пиф» — ягодка лопается.
func pif() -> void:
	_play(_pif, randf_range(0.94, 1.06), -1.0)


## Звон рассыпающихся ягодок.
func sparkle() -> void:
	_play(_sparkle, randf_range(0.9, 1.1), -2.0)


## Тихое мерцание на время уменьшения.
func shimmer() -> void:
	_play(_shimmer, 1.0, -3.0)


## Колокольчик ягодки; step — порядковый номер (1, 2, 3...).
func chime(step: int = 1) -> void:
	var notes: Array[float] = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
	_play(_chime, notes[posmod(step - 1, notes.size())] / 523.25, -1.0)


## Тихий стук кирпичика.
func tap() -> void:
	_play(_tap, randf_range(0.95, 1.08), -2.0)


## Мурчание (финал): низкое, мягкое.
func purr() -> void:
	_play(_purr, 1.0, -1.0)


## Короткая тёплая мелодия на входе.
func melody() -> void:
	_play(_melody, 1.0, -3.0)


## Скрип двери в переходе: низкий тон с дрожанием и шорохом.
func door_creak() -> void:
	_play(_door, randf_range(0.96, 1.04), -1.0)


# --- воспроизведение -------------------------------------------------------

func _play(stream: AudioStream, pitch: float, db: float) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db + db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# --- синтез ----------------------------------------------------------------

func _wav(length: float) -> Array:
	var count := int(RATE * length)
	var data := PackedByteArray()
	data.resize(count * 2)
	return [data, count]


func _finish(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


func _write(data: PackedByteArray, i: int, sample: float) -> void:
	data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))


## Короткий «пиф»: мягкий шум и падающий тон.
func _make_pif() -> AudioStreamWAV:
	var parts := _wav(0.3)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / RATE
		var freq := lerpf(760.0, 170.0, minf(t / 0.16, 1.0))
		phase += TAU * freq / RATE
		var tone := sin(phase) * minf(t / 0.004, 1.0) * exp(-t * 16.0)
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.16)
		var puff := noise * exp(-t * 30.0) * 1.2
		_write(data, i, (tone * 0.6 + puff * 0.4) * 0.5)
	return _finish(data)


## Звон: три высокие ноты с быстрым затуханием.
func _make_sparkle() -> AudioStreamWAV:
	var parts := _wav(0.6)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	for i in count:
		var t := float(i) / RATE
		var s := sin(TAU * 1568.0 * t) + 0.6 * sin(TAU * 2093.0 * t) + 0.35 * sin(TAU * 2637.0 * t)
		var env := minf(t / 0.006, 1.0) * exp(-t * 7.0)
		_write(data, i, s * env * 0.22)
	return _finish(data)


## Мерцание: тихий подъём тона с лёгким дрожанием, плавно с обеих сторон.
func _make_shimmer() -> AudioStreamWAV:
	var parts := _wav(1.6)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var phase := 0.0
	var phase2 := 0.0
	for i in count:
		var t := float(i) / RATE
		var k := t / 1.6
		var freq := lerpf(220.0, 660.0, k)
		phase += TAU * freq / RATE
		phase2 += TAU * (freq * 1.5) / RATE
		var vibrato := 1.0 + 0.12 * sin(TAU * 6.0 * t)
		var env := sin(PI * k) * 0.5
		_write(data, i, (sin(phase) * 0.7 + sin(phase2) * 0.3) * env * vibrato * 0.28)
	return _finish(data)


## Колокольчик ягодки (как в игре): основной тон и два обертона.
func _make_chime() -> AudioStreamWAV:
	var parts := _wav(0.8)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var freq := 523.25
	for i in count:
		var t := float(i) / RATE
		var env := minf(t / 0.005, 1.0) * exp(-t * 6.0)
		var s := sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 2.0 * t) + 0.15 * sin(TAU * freq * 3.01 * t)
		_write(data, i, s * env * 0.3)
	return _finish(data)


## Деревянный стук кирпичика.
func _make_tap() -> AudioStreamWAV:
	var parts := _wav(0.09)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	for i in count:
		var t := float(i) / RATE
		var s := sin(TAU * 250.0 * t) * exp(-t * 45.0) + sin(TAU * 520.0 * t) * exp(-t * 70.0) * 0.5
		_write(data, i, s * 0.35)
	return _finish(data)


## Мурчание: низкий тон с амплитудной модуляцией и мягким шумом.
func _make_purr() -> AudioStreamWAV:
	var parts := _wav(1.8)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / RATE
		var k := t / 1.8
		var env := sin(PI * k)
		var am := 0.55 + 0.45 * sin(TAU * 26.0 * t)
		phase += TAU * 62.0 / RATE
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.05)
		var s := (sin(phase) * 0.8 + noise * 0.5) * am
		_write(data, i, s * env * 0.3)
	return _finish(data)


## Скрип двери: медленный низкий подъём тона и тихий шорох.
func _make_door() -> AudioStreamWAV:
	var length := 0.85
	var parts := _wav(length)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var phase := 0.0
	var noise := 0.0
	for i in count:
		var t := float(i) / RATE
		var k := t / length
		var freq := lerpf(92.0, 148.0, k)
		phase += TAU * freq / RATE
		var env := minf(t / 0.08, 1.0) * (1.0 - smoothstep(0.55, 1.0, k))
		var wobble := 1.0 + 0.25 * sin(TAU * 9.0 * t)
		noise = lerpf(noise, randf_range(-1.0, 1.0), 0.06)
		var s := (sin(phase) * 0.7 + noise * 0.25) * wobble
		_write(data, i, s * env * 0.3)
	return _finish(data)


## Тёплая мелодия: пентатоника вверх, каждая нота — колокольчик.
func _make_melody() -> AudioStreamWAV:
	var length := 2.2
	var parts := _wav(length)
	var data: PackedByteArray = parts[0]
	var count: int = parts[1]
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var starts: Array[float] = [0.0, 0.18, 0.36, 0.54]
	for i in count:
		var t := float(i) / RATE
		var s := 0.0
		for n in notes.size():
			var local := t - float(starts[n])
			if local < 0.0:
				continue
			var env := minf(local / 0.006, 1.0) * exp(-local * 3.2)
			s += (sin(TAU * notes[n] * local) + 0.3 * sin(TAU * notes[n] * 2.0 * local)) * env
		# Мягкое затухание всего арпеджио к концу.
		_write(data, i, s * 0.16 * (1.0 - smoothstep(length - 0.5, length, t)))
	return _finish(data)
