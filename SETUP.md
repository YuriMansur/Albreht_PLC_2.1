# Настройка новой машины под сборку проекта

Репозиторий самодостаточен по **коду** (`src_xml/`) и **шаблону** (`project/liner_cyclic.project`),
но НЕ по среде CODESYS. Сам CODESYS, библиотеки и описания устройств в git не лежат
(лицензии + привязка к версии). Ниже — что доустановить на чистой машине.

## 1. CODESYS
- Установить **CODESYS V3.5 SP17 Patch 3** (профиль `CODESYS V3.5 SP17 Patch 3`).
  Путь к `CODESYS.exe` искать не нужно — `scripts/_find_codesys.bat` находит его сам
  (Program Files → все диски). Нестандартная установка — см. `scripts/env.local.bat.example`.

## 2. Библиотеки (Library Repository)
Должны резолвиться при сборке, иначе будет ошибка вида
«Невозможно разрешить библиотеку плейсхолдера '<имя>'».

**Системные / вендорские** — ставятся вместе с CODESYS и вендорскими пакетами
(Package Manager), в git их нет:
- SoftMotion: `SM3_Basic`, `SM3_Basic_Visu`, `SM3_CNC`, `SM3_CamBuilder`,
  `SM3_Drive_ETC`, `SM3_Drive_ETC_DS402_CyclicSync`, `SM3_Robotics`,
  `SM3_Robotics_Visu`, `SM3_Transformation`
- Визуализация: `System_VisuElems*`, `System_VisuNativeControl`, `system_visuinputs`,
  `VisuSymbols`, `CmpVisuHandler`
- Прочее: `IoStandard`, `IODrvEtherCAT`, `IoDrvEthernet`, `IecVarAccess`,
  `BreakpointLogging`, `3SLicense`
- Xinje (вендорский пакет): `XJ_System`, `XJ_Modbus2`

**Идут с базовой установкой CODESYS:** `Standard`, `Util`, `Unit Conversion Interfaces`.

**Перераспространяемые (можно версионировать)** — кладём в `libs/` и ставим
скриптом (см. `libs/README.md`):
- `OSCAT BASIC 3.3.4.0`

## 3. Описания устройств (Device Repository)
Нужны для дерева устройств шаблона:
- EtherCAT-модули ICP DAS: `ECAT-2053` (DI), `ECAT-2016N` (тензо/AI),
  `ECAT-2057` (DQ) — поставить ESI/описания.
- Привод и шина SoftMotion/EtherCAT (из вендорского пакета).

## 4. Git-хук автоэкспорта (опционально, для коммита кода)
Настройка `core.hooksPath` **локальная** и не клонируется — включить заново:
```sh
git config core.hooksPath scripts/git-hooks
```
На сам билд не влияет; нужен только чтобы при `git commit` автоматически
обновлялся `src_xml/` из проекта.

## 5. Сборка
```bat
scripts\run_build.bat
```
Итог — `out\liner_cyclic.projectarchive`. Вердикт и лог — `build.log`
(`Компиляция завершена -- 0 ошибок` = успех). Подробности пайплайна — `scripts/README.md`.
