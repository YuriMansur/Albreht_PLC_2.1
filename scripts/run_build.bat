@echo off
rem Сборка: src_xml/ -> шаблон .project -> компиляция -> .projectarchive.
rem Для сборщика/CI. Код возврата != 0 при ошибках компиляции.
rem Аргумент "nopause" - не ждать клавишу в конце (для CI/автоматики).
rem ВЫВОД в echo - латиницей: кириллица в консоли .bat зависит от кодовой
rem страницы и превращается в кракозябры. Комментарии rem не выводятся - они русские.
setlocal EnableDelayedExpansion

if /i "%~1"=="nopause" set "NOPAUSE=1"

echo ==========================================================
echo  [run_build] BUILD (src_xml -^> template -^> archive)
echo ==========================================================

rem CODESYS.exe и PROFILE определяет _find_codesys.bat (автопоиск + env.local.bat).
call "%~dp0_find_codesys.bat" called
if not defined CODESYS (
  echo [run_build] ERROR: CODESYS not found - cannot build.
  if not defined NOPAUSE pause
  exit /b 1
)
rem Шаблон с настроенным "железом" (вариант A). Здесь — текущий проект как шаблон.
set "TEMPLATE=project\liner_cyclic.project"
set "SRCXML=src_xml"
set "ARCHIVE=out\liner_cyclic.projectarchive"

cd /d "%~dp0.."

echo [run_build] template: %TEMPLATE%
echo [run_build] src_xml : %SRCXML%
echo [run_build] archive : %ARCHIVE%
echo [run_build] compiling (CODESYS headless, ~30s)...
echo.

rem Полный вывод пишем в build.log И показываем в консоли (ниже через type).
"%CODESYS%" --profile="%PROFILE%" --noUI ^
  --runscript="scripts\build.py" ^
  --scriptargs:"%TEMPLATE% %SRCXML% %ARCHIVE%" > build.log 2>&1

set "RC=%ERRORLEVEL%"

echo ----------------------- build.log ------------------------
type build.log
echo ----------------------------------------------------------
echo.

rem --- ВЕРДИКТ ПО ЛОГУ ---
rem Метка severity 'Error:' в выводе ScriptEngine — ASCII и регистрозависима,
rem поэтому ожидаемые пропуски железа 'IMPORT ERROR:' (заглавными) НЕ считаются.
set "ERRCOUNT=0"
for /f %%C in ('findstr /C:"Error:" build.log ^| find /c /v ""') do set "ERRCOUNT=%%C"

rem Падение самого скрипта тоже = провал.
findstr /C:"BUILD FAILED" build.log >nul && set "RC=1"

if not "!ERRCOUNT!"=="0" (
  echo [run_build] BUILD FAILED: !ERRCOUNT! line^(s^) with Error ^(see build.log^)
  if exist "%ARCHIVE%" del /q "%ARCHIVE%"
  set "RC=1"
) else (
  echo [run_build] compiled without Error-level messages
  if exist "%ARCHIVE%" echo [run_build] archive ready: %ARCHIVE%
)

echo [run_build] exit code: !RC!  ^(full output in build.log^)
echo.
if not defined NOPAUSE pause
endlocal & exit /b %RC%
