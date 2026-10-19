# Ролики (катсцены) «Август и ягодки»

Живые ролики на движке: 3D-сцена, `Tween`-таймлайн, частицы и звуки, синтезированные в коде.
Видеофайлов нет — значит, работают смена света дня и любые правки моделей.

## Как посмотреть

```bash
# все ролики, выбор клавишами 1–4 (Esc — выход, пробел/клик — пропуск)
godot --path . cutscenes/preview.tscn

# один ролик: запускается сам и после конца играет заново
godot --path . cutscenes/intro.tscn
```

Скриншоты и проверки:

```bash
# кадры intro в SHOT_DIR (раскадровка для проверки глазами)
SHOT_DIR=$PWD/cutscenes/tests/shots godot --path . --fixed-fps 60 \
    -s cutscenes/tests/shots.gd

# то же, но через автолоад (SubViewport поверх «игры») + проверка пропуска
SHOT_DIR=$PWD/cutscenes/tests/shots godot --path . --fixed-fps 60 \
    -s cutscenes/tests/shots_managed.gd

# полный просмотр, пропуск, повторный запуск, заморозка/разморозка игры
godot --headless --path . --fixed-fps 60 -s cutscenes/tests/smoke.gd
```

## Устройство

| Файл | Что делает |
|---|---|
| `cutscene_player.gd` | автолоад `Cutscenes`: `play(name, params)`, `skip()`, сигнал `finished(name)` |
| `cutscene.gd` | базовый ролик: таймлайн `at(секунда, метод)`, твины, пропуск, финальное состояние |
| `cut_actors.gd` | Август и Астра из существующих сцен: физика выключена, ролик задаёт позицию/поворот/клип |
| `cut_set.gd` | примитивы-заглушки: коробка, сфера, цилиндр, матовый/светящийся материал |
| `cut_audio.gd` | синтез звуков: «пиф», звон, мерцание, колокольчик, стук, мурчание, мелодия |
| `props/` | заглушки, которые легко заменить моделью: `berry_stub.tscn`, `bush_stub.tscn`, `sparkles.tscn` |
| `preview.tscn/.gd` | просмотрщик для ПК (не часть игры) |
| `intro.tscn/.gd` | ролик intro |
| `tests/` | скрипты проверки и кадры |

### Скелет сцены ролика

```
<Ролик> (Node3D, скрипт — наследник cutscene.gd)
├── WorldEnvironment      свой свет и туман — мир ролика изолирован
├── Sun, Fill             лампы сцены
├── CamRig                цель взгляда камеры
│   └── Camera3D          расстояние по Z, current = true
├── Set                   комната и мебель; масштабируется при «уменьшении» героев
├── Heroes                Август и Астра (их создаёт _prepare())
├── Props                 ягодки, вспышки, блёстки (не масштабируются вместе с Set)
├── Fade/Rect             чёрная шторка для входа и выхода
└── CutAudio              звуки (cut_audio.gd)
```

Новый ролик: скопировать `intro.tscn`, поменять скрипт, добавить имя в `SCENES`
(`cutscene_player.gd`) и в `NAMES` (`preview.gd`).

### Как описывается ролик

Всё время и позиции — в одном файле ролика: экспорт-переменные сверху и константы декораций.
Таймлайн — список реплик на абсолютных временах:

```gdscript
func _build() -> void:
    at(0.0, _open)              # затемнение, камера, музыка
    at(t_pif, _pif)             # «пиф»
    at(t_shrink, _shrink)       # уменьшение
    at(t_run, _run)             # убегают

func _shrink() -> void:
    scale_to(_set_root, Vector3.ONE * world_scale, d_shrink)
    scale_to(_avgust, Vector3.ONE / hero_shrink, d_shrink)
    cam_to(shot_wide_target, shot_wide_dist, d_shrink + 0.4)
```

Внутри бита можно запускать ещё твины (`new_tween()`), они регистрируются у ролика.

### Пропуск

`_apply_final_state()` — обязательная часть контракта: к моменту `finished` мир должен быть
таким же, как после полного просмотра (масштабы, позы, камера, глобальные флаги).
`skip()` убивает все твины ролика, вызывает `_apply_final_state()` и шлёт `finished`.

Касание в любом месте экрана (на ПК — клик, пробел, Enter) пропускает ролик. Иконок и текста нет.

## Точки интеграции для основной сессии

1. Автолоад уже добавлен в `project.godot`:

   ```
   [autoload]
   Game="*res://scripts/game.gd"
   Cutscenes="*res://cutscenes/cutscene_player.gd"
   ```

2. Intro — один раз за запуск, перед первым уровнем:

   ```gdscript
   if not Cutscenes.was_played(&"intro"):
       Cutscenes.play(&"intro")
       await Cutscenes.finished
   # дальше — загрузка уровня как обычно
   ```

   `play()` возвращает `false`, если ролика нет в `SCENES`.

3. Переходы между комнатами (появятся на шаге 2):

   ```gdscript
   Cutscenes.play(&"transition", {"room": &"bathroom"})
   await Cutscenes.finished
   ```

4. Финал и второй круг (шаг 3): `Cutscenes.play(&"finale")`, после него — смена света дня и
   `Cutscenes.play(&"second_round_start")`.

Во время ролика текущая сцена игры получает `process_mode = DISABLED` (физика, ввод и таймеры
сцены стоят), после `finished` или пропуска режим возвращается. Дерево не ставится на паузу,
поэтому `await Cutscenes.finished` работает как обычно.

Ролик рисуется в отдельном `SubViewport` со своим `World3D`: свет, фон и камера уровня на него
не влияют, а сам ролик не виден за пределами оверлея.
