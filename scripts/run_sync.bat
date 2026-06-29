@echo off
rem run_sync.bat - "синхронизация с сервером" одной кнопкой:
rem   1) КОММИТ твоих текущих изменений (если они есть);
rem   2) FETCH+MERGE: подтянуть и СЛИТЬ то, что появилось в main на сервере;
rem   3) PUSH: отправить main на сервер.
rem В конце - понятный вердикт: "SYNC OK" или "SYNC FAILED: <причина>".
rem
rem Зачем merge перед push: если кто-то (или ты с другой машины) уже залил
rem изменения в main, git НЕ даст запушить поверх ("fetch first"). Сначала
rem сливаем чужое к себе, потом пушим общий результат.
rem
rem Запуск: двойной клик  ИЛИ  run_sync.bat "сообщение коммита"
rem ВЫВОД в echo - латиницей: кириллица в консоли .bat = кракозябры.
rem Комментарии rem не выводятся - они русские.
setlocal EnableDelayedExpansion

rem сообщение коммита: аргумент %1 или дефолт с датой/временем
set "MSG=%~1"
if "%MSG%"=="" set "MSG=sync %DATE% %TIME%"

rem перейти в корень репо (родитель папки scripts)
cd /d "%~dp0.."

echo ==========================================================
echo  [run_sync] SYNC with remote (commit -^> merge -^> push)
echo ==========================================================

rem 0) это вообще git-репозиторий?
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo [run_sync] SYNC FAILED: this folder is not a git repository
  goto :fail
)

rem текущая ветка (обычно main) - её и синхронизируем
set "BRANCH="
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do set "BRANCH=%%b"
echo [run_sync] branch: !BRANCH!

rem 1) КОММИТ текущих изменений, если есть. git commit запустит pre-commit хук
rem    (экспорт кода CODESYS в src_xml) - это штатно.
set "DIRTY="
for /f "delims=" %%i in ('git status --porcelain') do set "DIRTY=1"
if defined DIRTY (
  echo [run_sync] local changes found - committing: "!MSG!"
  git add -A
  git commit -m "!MSG!"
  if errorlevel 1 (
    echo [run_sync] SYNC FAILED: commit failed ^(pre-commit hook / CODESYS error - see output above^)
    goto :fail
  )
) else (
  echo [run_sync] no local changes to commit
)

rem 2) FETCH + MERGE удалёнки
echo [run_sync] fetching remote...
git fetch origin
if errorlevel 1 (
  echo [run_sync] SYNC FAILED: cannot reach remote ^(network / auth?^)
  goto :fail
)

echo [run_sync] merging origin/!BRANCH! into local...
git merge --no-edit origin/!BRANCH!
if errorlevel 1 (
  echo.
  echo [run_sync] SYNC FAILED: MERGE CONFLICTS - these files need manual fix:
  git diff --name-only --diff-filter=U
  echo.
  echo [run_sync] what to do:
  echo [run_sync]   - open each file above, resolve the ^<^<^<^<^</=====/^>^>^>^>^> markers,
  echo [run_sync]     then:  git add .   and   git commit
  echo [run_sync]   - OR cancel the merge entirely:  git merge --abort
  echo [run_sync]   then run this script again.
  goto :fail
)

rem 3) PUSH
echo [run_sync] pushing !BRANCH! to origin...
git push origin !BRANCH!
if errorlevel 1 (
  echo [run_sync] SYNC FAILED: push rejected or auth error.
  echo [run_sync]   if remote moved again while we worked - just run the script once more.
  goto :fail
)

echo.
echo [run_sync] SYNC OK - local and remote !BRANCH! are now in sync.
echo.
pause
endlocal & exit /b 0

:fail
echo.
pause
endlocal & exit /b 1
