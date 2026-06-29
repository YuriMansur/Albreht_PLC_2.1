# CODESYS ↔ Git: экспорт кода и сборка

Бинарный `.project` неудобно хранить в Git (не видно изменений в коде). Эти
скрипты экспортируют код в текстовый **PLCopen XML** (читаемые диффы) и собирают
проект обратно на сборщике.

## Что хранится в Git (вариант A)
```
project/liner_cyclic.project      # ШАБЛОН: «железо» (устройство, IO, task-config). Меняется редко.
src_xml/                          # КОД (POU/DUT/GVL) в PLCopen XML — по файлу на объект. Источник диффов.
.gitignore                        # выкидывает артефакты компиляции/кэш/.opt
```
«Железо» через PLCopen XML не переносится — поэтому device-конфиг живёт в
`.project`-шаблоне, а в `src_xml/` версионируется только код.

## Скрипты
| Файл | Назначение |
|---|---|
| `export_xml.py` | код проекта → `src_xml/*.xml` (для коммита) |
| `build.py` | `src_xml/` → шаблон → компиляция → `out/*.projectarchive` |
| `run_export.bat` / `run_build.bat` | обёртки: находят CODESYS и зовут скрипт |
| `run_sync.bat` | git-синхронизация: коммит → merge `origin/main` → push (с вердиктом) |
| `_find_codesys.bat` | автопоиск `CODESYS.exe` и профиля (общий для обёрток) |
| `install_libs.py` / `run_install_libs.bat` | установка библиотек из `libs/` в Library Repository |
| `git-hooks/pre-commit` | автоэкспорт перед каждым коммитом |

Настройка чистой машины (CODESYS, библиотеки, устройства, хук) — см. `../SETUP.md`.

## Настройка (один раз)
1. **CODESYS и профиль определяются автоматически** (`_find_codesys.bat`): ищет
   `CODESYS.exe` сначала в `%ProgramFiles%`/`%ProgramFiles(x86)%`, а если там нет —
   обходит **все диски** целиком (медленный fallback, ~десятки секунд). Из всех
   найденных установок предпочитает версию под проект (`3.5.17`), иначе берёт
   старшую. **Имя профиля** берётся из той же установки
   (`...\CODESYS\Profiles\*.profile.xml`), поэтому при другом патче/разрядности
   подхватится само; дефолт `CODESYS V3.5 SP17 Patch 3` — только запасной вариант.
   На стандартной установке править ничего не нужно — работает на любой машине.
2. **Если установка нестандартная** (другой диск, портативная версия) или нужно
   ускорить/зафиксировать выбор — скопируй `scripts/env.local.bat.example` →
   `scripts/env.local.bat` и пропиши свои `CODESYS` и `PROFILE`. Файл не
   версионируется (свой на каждой машине) и перекрывает автопоиск.
3. Включить автоэкспорт-хук:
   ```sh
   git config core.hooksPath scripts/git-hooks
   ```

## Рабочий цикл
1. Правишь логику в CODESYS, **сохраняешь** проект.
2. `git commit` → хук `pre-commit` запускает `run_export.bat` → обновляет `src_xml/` → добавляет в коммит.
3. На сборщике `run_build.bat` собирает `.projectarchive` и падает (exit≠0) при ошибках компиляции.

## ⚠️ Не проверено на железе
Скрипты написаны по докам ScriptEngine, но исполняются только на машине с CODESYS.
Строки с `[VERIFY]` (в `export_xml.py` / `build.py`) — методы/сигнатуры, которые
надо подтвердить первым прогоном под SP17:
- `proj.export_xml(objects, path, recursive)`
- `app.import_xml(path)` (vs `proj.import_xml(...)`)
- компиляция: `app.generate_code()` / `proj.check_all_pool_objects()`
- чтение ошибок: `system.get_message_objects()`
- `proj.close()`

Запусти `run_export.bat`, пришли вывод — доточим сигнатуры.
