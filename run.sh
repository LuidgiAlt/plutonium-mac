#!/bin/bash
# Run Plutonium with the runner and prefix made by setup.sh.
#   ./run.sh                       start the Plutonium launcher
#   ./run.sh install plutonium.exe run Plutonium's installer in the prefix
#   ./run.sh kill                  stop everything in the prefix
# Options:
#   PLUTONIUM_DIR=...  Plutonium folder (default: %LOCALAPPDATA%\Plutonium in the prefix)
#   RENDERER=dxmt      CrossOver's DXMT instead of wined3d (untested here)
#   LAZY_EXEC=0        turn the stall fix off
#   WINDOWED=1         force Windowed mode in BO2
#   D3D9=vulkan        wined3d's Vulkan renderer for Direct3D 9 games (BO1, WaW)
#                      instead of OpenGL; uses the persistent pipeline cache
set -euo pipefail
here=$(cd -- "$(dirname -- "$0")" && pwd)
runner="$here/runner/CrossOver"
[ -d "$runner" ] && [ -d "$here/prefix" ] || { echo "run ./setup.sh first" >&2; exit 1; }

export CX_ROOT="$runner" WINEPREFIX="$here/prefix" WINESERVER="$runner/bin/wineserver"
export CX_HOME="$HOME/Library/Application Support/CrossOver"
export WINEDLLPATH="$runner/lib/wine/x86_64-windows:$runner/lib/wine/x86_64-unix"
export WINEMSYNC=1 WINEDEBUG=-all
wine="$runner/lib/wine/x86_64-unix/wine"
plutonium=${PLUTONIUM_DIR:-$WINEPREFIX/drive_c/users/crossover/AppData/Local/Plutonium}

case "${1:-}" in
kill) "$WINESERVER" -k; exit 0 ;;
install) exec "$wine" "${2:?path to plutonium.exe}" ;;
esac

# Plutonium sets x86 hardware breakpoints, which Rosetta cannot deliver; the
# patched ntdll emulates them. Lazy exec removes the stalls caused by the
# bootstrapper turning off DEP (it has no NX_COMPAT flag).
vars=(WINE_ROSETTA_EXEC_BREAKPOINTS=1 WINE_ROSETTA_WOW64_BREAKPOINTS=1 WINE_ROSETTA_CALL_WORKAROUND=1
      "WINE_ROSETTA_LAZY_EXEC=${LAZY_EXEC:-1}" "CX_GRAPHICS_BACKEND=${RENDERER:-wined3d}")
"$WINESERVER" -k 2>/dev/null || true
"$WINESERVER" -w 2>/dev/null || true
# The launcher starts each game with a fresh Windows environment built from
# HKCU\Environment, so the variables are set there as well as here.
for v in "${vars[@]}"; do
  export "$v"
  "$wine" reg add 'HKCU\Environment' /v "${v%%=*}" /d "${v#*=}" /f > /dev/null 2>&1
done
# wined3d renders Direct3D 9 with OpenGL unless told otherwise.
if [ "${D3D9:-}" = vulkan ]; then
  "$wine" reg add 'HKCU\Software\Wine\Direct3D' /v renderer /d vulkan /f > /dev/null 2>&1
else
  "$wine" reg delete 'HKCU\Software\Wine\Direct3D' /v renderer /f > /dev/null 2>&1
fi
"$WINESERVER" -w 2>/dev/null || true

# Apple GPUs support at most 4x MSAA; BO2 crashes when its config asks for 8x.
for cfg in "$plutonium"/storage/t6/players/plutonium_{zm,mp}.cfg; do
  [ -f "$cfg" ] || continue
  sed -i '' -E 's/^seta r_aaSamples "(8|16|32)"/seta r_aaSamples "4"/' "$cfg"
  if [ "${WINDOWED:-0}" = 1 ]; then sed -i '' 's/^seta r_fullscreen "[0-9]*"/seta r_fullscreen "0"/' "$cfg"; fi
done

launcher="$plutonium/bin/plutonium-launcher-win32.exe"
[ -f "$launcher" ] || { echo "no Plutonium launcher at $launcher (set PLUTONIUM_DIR or ./run.sh install)" >&2; exit 1; }
cd "$plutonium/bin"
exec "$wine" "$launcher" > /dev/null 2>&1
