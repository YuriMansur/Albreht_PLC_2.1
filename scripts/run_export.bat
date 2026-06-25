@echo off
rem Экспорт кода CODESYS (POU/DUT/GVL) -> PLCopen XML в src_xml/.
rem Запускать из корня репозитория или двойным кликом.
rem Аргумент "nopause" - не ждать клавишу в конце (передаёт pre-commit хук).
rem ВЫВОД в echo - латиницей (кириллица в консоли .bat = кракозябры).
setlocal

if /i "%~1"=="nopause" set "NOPAUSE=1"

echo ==========================================================
echo  [run_export] EXPORT CODE  CODESYS -^> src_xml/
echo ==========================================================

rem CODESYS.exe и PROFILE определяет _find_codesys.bat (автопоиск + env.local.bat).
call "%~dp0_find_codesys.bat" called
if not defined CODESYS (
  echo [run_export] ERROR: CODESYS not found - cannot export.
  if not defined NOPAUSE pause
  endlocal & exit /b 1
)
set "PROJECT=project\liner_cyclic.project"
set "OUTDIR=src_xml"

rem Перейти в корень репо (родитель папки scripts)
cd /d "%~dp0.."

echo [run_export] project: %PROJECT%
echo [run_export] out dir: %OUTDIR%
echo [run_export] exporting (CODESYS headless, ~30s)...
echo.

"%CODESYS%" --profile="%PROFILE%" --noUI ^
  --runscript="scripts\export_xml.py" ^
  --scriptargs:"%PROJECT% %OUTDIR%"

set "RC=%ERRORLEVEL%"
echo.
echo [run_export] exit code: %RC%
if not defined NOPAUSE pause
endlocal & exit /b %RC%
