# -*- coding: utf-8 -*-
"""
install_libs.py — CODESYS ScriptEngine (IronPython 2.7).

Ставит в Library Repository все библиотеки (*.library / *.compiled-library) из
папки libs/ репозитория, чтобы на новой машине не искать перераспространяемые
библиотеки руками. Системные/вендорские сюда не кладём (см. libs/README.md).

Запуск (через обёртку, путь к CODESYS определит _find_codesys.bat):
  scripts\\run_install_libs.bat
или напрямую:
  "<...>\\CODESYS.exe" --profile="CODESYS V3.5 SP17 Patch 3" --noUI ^
      --runscript="scripts\\install_libs.py" --scriptargs:"libs"

ВАЖНО: точный метод установки в репозиторий зависит от версии ScriptEngine —
помечен [VERIFY] и должен быть подтверждён первым прогоном под SP17 (так же,
как build.py/export_xml.py). Если API недоступен — скрипт подскажет ручной путь.
"""

import os
import sys


def _exit(code):
    try:
        sys.stdout.flush()
    except Exception:
        pass
    try:
        import System
        System.Environment.Exit(code)
    except Exception:
        sys.exit(code)


def _libs_dir():
    args = [a for a in sys.argv if a and not a.lower().endswith("install_libs.py")]
    d = args[-1] if args else "libs"
    return os.path.abspath(d)


def _collect(libs_dir):
    exts = (".library", ".compiled-library")
    found = []
    for root, _dirs, files in os.walk(libs_dir):
        for f in files:
            if f.lower().endswith(exts):
                found.append(os.path.join(root, f))
    found.sort()
    return found


def _install_one(path):
    """Поставить один файл библиотеки в репозиторий. [VERIFY] — сигнатура зависит
    от версии ScriptEngine. Пробуем известные точки входа, иначе бросаем."""
    # [VERIFY] вариант 1: глобальный объект librarymanager / repository
    try:
        repository.install_library(path)          # noqa: F821
        return True
    except Exception:
        pass
    # [VERIFY] вариант 2: через system
    try:
        system.install_library(path)              # noqa: F821
        return True
    except Exception:
        pass
    return False


def main():
    libs_dir = _libs_dir()
    print("libs dir: " + libs_dir)
    if not os.path.isdir(libs_dir):
        print("папки libs нет — нечего ставить")
        _exit(0)

    files = _collect(libs_dir)
    if not files:
        print("в libs/ нет *.library / *.compiled-library — нечего ставить")
        _exit(0)

    print("найдено библиотек: %d" % len(files))
    ok = fail = 0
    for p in files:
        name = os.path.basename(p)
        try:
            if _install_one(p):
                ok += 1
                print("  установлено: " + name)
            else:
                fail += 1
                print("  НЕ УСТАНОВЛЕНО (API недоступен): " + name)
        except Exception as e:
            fail += 1
            print("  ОШИБКА %s: %s" % (name, e))

    print("итог: установлено %d, не удалось %d" % (ok, fail))
    if fail:
        print("Не установленные библиотеки поставь вручную: CODESYS -> Tools ->")
        print("Library Repository -> Install... -> выбери файл из libs/")
    _exit(0 if fail == 0 else 1)


main()
