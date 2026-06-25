@echo off
rem ============================================================================
rem _find_codesys.bat - определяет путь к CODESYS.exe и имя профиля.
rem Результат кладёт в переменные окружения CODESYS и PROFILE.
rem Подключается из run_build.bat / run_export.bat через CALL.
rem
rem Приоритет источников (сверху вниз, первый сработавший побеждает):
rem   1. scripts\env.local.bat  - per-machine оверрайд (НЕ в git), если есть;
rem   2. уже заданные CODESYS/PROFILE в окружении;
rem   3. автопоиск: CODESYS.exe (Program Files -> все диски), а PROFILE -
rem      из той же установки (...\CODESYS\Profiles\*.profile.xml); дефолт - fallback.
rem
rem PROFILE определяется автоматически из найденной установки, поэтому на машине
rem с другим патчем/разрядностью имя профиля подхватится само. Дефолт ниже -
rem только запасной вариант, если в установке профиль не нашёлся. Жёстко задать
rem можно через scripts\env.local.bat.
rem
rem Весь видимый вывод (echo) - латиницей: кириллица в консоли .bat зависит от
rem кодовой страницы и превращается в кракозябры. Комментарии rem не выводятся.
rem ============================================================================

rem Профиль, под который сделан проект (на стандартной машине менять не нужно):
set "PROFILE_DEFAULT=CODESYS V3.5 SP17 Patch 3"
rem Версия установки под этот профиль (SP17 = 3.5.17). Из всех найденных
rem установок ПРЕДПОЧИТАЕТСЯ именно она, иначе берётся новейшая.
set "CODESYS_VER_HINT=3.5.17"

rem Пауза в конце - только при ПРЯМОМ запуске (двойной клик). Обёртки
rem (run_build/run_export/run_install_libs) зовут этот хелпер с аргументом
rem "called" - тогда паузы НЕТ (иначе подвисли бы сборка/экспорт и pre-commit).
set "_CALLED="
if /i "%~1"=="called" set "_CALLED=1"

echo [find_codesys] === resolving CODESYS.exe and profile ===

rem --- 1. Локальный оверрайд (не версионируется) ---
if exist "%~dp0env.local.bat" (
  echo [find_codesys] applying override: scripts\env.local.bat
  call "%~dp0env.local.bat"
) else (
  echo [find_codesys] no scripts\env.local.bat - using autodetect
)

rem --- 2. Автопоиск CODESYS.exe, если не задан или путь не существует ---
if defined CODESYS (
  if exist "%CODESYS%" (
    echo [find_codesys] preset CODESYS exists, keeping: "%CODESYS%"
  ) else (
    echo [find_codesys] preset CODESYS path missing, will search: "%CODESYS%"
    set "CODESYS="
  )
)
if not defined CODESYS call :autodetect

rem --- 3. Профиль: оверрайд > автоопределение из установки > дефолт ---
if defined PROFILE echo [find_codesys] PROFILE preset/override: "%PROFILE%"
if not defined PROFILE if defined CODESYS call :detect_profile
if not defined PROFILE (
  echo [find_codesys] profile not detected - using default
  set "PROFILE=%PROFILE_DEFAULT%"
)

rem --- Итог ---
if not defined CODESYS (
  echo [find_codesys] ERROR: CODESYS.exe not found in Program Files or on any drive.
  echo [find_codesys] Set the path manually in scripts\env.local.bat ^(see env.local.bat.example^).
)
echo [find_codesys] --------------------------------------------------
if defined CODESYS echo [find_codesys] CODESYS = "%CODESYS%"
echo [find_codesys] PROFILE = "%PROFILE%"
echo [find_codesys] --------------------------------------------------
rem Пауза только при прямом запуске (без аргумента "called" от обёрток).
if not defined _CALLED pause
goto :eof

rem ============================================================================
rem :autodetect - наполняет CODESYS_FALLBACK (новейшая) и CODESYS_HINTED
rem (совпадающая с профилем), затем выбирает. Сначала быстрый проход по
rem Program Files; если там пусто - полный обход всех дисков (медленно).
rem ============================================================================
:autodetect
set "CODESYS_FALLBACK="
set "CODESYS_HINTED="
echo [find_codesys] searching in: %ProgramFiles%
call :scan "%ProgramFiles%"
echo [find_codesys] searching in: %ProgramFiles(x86)%
call :scan "%ProgramFiles(x86)%"
if not defined CODESYS_FALLBACK (
  echo [find_codesys] nothing in Program Files - scanning ALL drives ^(may take a while^)...
  call :scan_all_drives
)
if defined CODESYS_HINTED (
  echo [find_codesys] selected version-matched install ^(hint %CODESYS_VER_HINT%^)
  set "CODESYS=%CODESYS_HINTED%"
) else if defined CODESYS_FALLBACK (
  echo [find_codesys] no %CODESYS_VER_HINT% install found - selected newest available
  set "CODESYS=%CODESYS_FALLBACK%"
) else (
  echo [find_codesys] no CODESYS.exe found anywhere
)
goto :eof

rem :scan_all_drives - перебрать буквы дисков и просканировать корень каждого.
:scan_all_drives
for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do if exist "%%D:\" (
  echo [find_codesys]   scanning drive %%D:\ ...
  call :scan "%%D:"
)
goto :eof

rem :scan <база> - найти ...\Common\CODESYS.exe под <база> (рекурсивно), отдать
rem каждого кандидата в :consider. Список идёт от новейшей версии к старой.
rem ВАЖНО: sort по полному пути - иначе из Git Bash (pre-commit зовёт cmd //c)
rem подхватывается Unix-sort и пайплайн падает. dir/findstr - встроенные/Windows.
:scan
if not exist "%~1" goto :eof
for /f "delims=" %%F in ('dir /b /s "%~1\CODESYS.exe" 2^>nul ^| findstr /i /l /e "\Common\CODESYS.exe" ^| "%SystemRoot%\System32\sort.exe" /r') do call :consider "%%F"
goto :eof

rem :consider <путь> - запомнить новейшего кандидата и (если совпал с хинтом) хинтового.
:consider
echo [find_codesys]   candidate: %~1
if not defined CODESYS_FALLBACK set "CODESYS_FALLBACK=%~1"
if defined CODESYS_HINTED goto :eof
if not defined CODESYS_VER_HINT goto :eof
echo %~1 | findstr /i /l /c:"%CODESYS_VER_HINT%" >nul || goto :eof
echo [find_codesys]     matches version hint %CODESYS_VER_HINT%
set "CODESYS_HINTED=%~1"
goto :eof

rem ============================================================================
rem :detect_profile - имя профиля из найденной установки.
rem  %CODESYS% = ...\CODESYS 3.5.x\CODESYS\Common\CODESYS.exe
rem  профили  = ...\CODESYS 3.5.x\CODESYS\Profiles\*.profile.xml  (рядом с Common)
rem Имя для --profile = имя файла без ".profile.xml".
rem ============================================================================
:detect_profile
rem _common = каталог exe (...\CODESYS\Common\)
for %%I in ("%CODESYS%") do set "_common=%%~dpI"
rem убрать хвостовой "\" и взять родителя Common -> ...\CODESYS\, далее Profiles
for %%I in ("%_common:~0,-1%") do set "_profiles=%%~dpIProfiles"
echo [find_codesys] looking for profile in: %_profiles%
if not exist "%_profiles%" (
  echo [find_codesys] profiles dir not found
  goto :eof
)
for /f "delims=" %%F in ('dir /b "%_profiles%\*.profile.xml" 2^>nul ^| "%SystemRoot%\System32\sort.exe" /r') do call :set_profile "%%~nF" "%%~nxF"
goto :eof

rem :set_profile <имя_без_xml> <полное_имя> - напр. "...Patch 3.profile" "...Patch 3.profile.xml"
:set_profile
if defined PROFILE goto :eof
echo [find_codesys]   profile file: %~2
set "_pn=%~1"
set "PROFILE=%_pn:.profile=%"
goto :eof
