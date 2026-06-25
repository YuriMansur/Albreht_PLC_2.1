@echo off
rem Установка перераспространяемых библиотек из libs/ в Library Repository CODESYS.
rem Разовый шаг при настройке новой машины (см. SETUP.md / libs/README.md).
rem Аргумент "nopause" - не ждать клавишу в конце (для автоматики).
rem ВЫВОД в echo - латиницей (кириллица в консоли .bat = кракозябры).
setlocal

if /i "%~1"=="nopause" set "NOPAUSE=1"

echo ==========================================================
echo  [run_install_libs] INSTALL LIBRARIES from libs/
echo ==========================================================

rem CODESYS.exe и PROFILE определяет _find_codesys.bat (автопоиск + env.local.bat).
call "%~dp0_find_codesys.bat" called
if not defined CODESYS (
  echo [run_install_libs] ERROR: CODESYS not found - cannot install.
  if not defined NOPAUSE pause
  endlocal & exit /b 1
)
set "LIBSDIR=libs"

rem Перейти в корень репо (родитель папки scripts)
cd /d "%~dp0.."

echo [run_install_libs] libs dir: %LIBSDIR%
echo [run_install_libs] installing (CODESYS headless)...
echo.

"%CODESYS%" --profile="%PROFILE%" --noUI ^
  --runscript="scripts\install_libs.py" ^
  --scriptargs:"%LIBSDIR%"

set "RC=%ERRORLEVEL%"
echo.
echo [run_install_libs] exit code: %RC%
if not defined NOPAUSE pause
endlocal & exit /b %RC%
