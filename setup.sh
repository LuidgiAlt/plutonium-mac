#!/bin/bash
# Create the runner and prefix used by run.sh:
#   runner/CrossOver  APFS copy of CrossOver's runtime with the patched binaries
#   prefix/           Wine prefix
#   ./setup.sh [path to the crossover-rosetta-patches build folder]
set -euo pipefail
here=$(cd -- "$(dirname -- "$0")" && pwd)
build=${1:-$here/../crossover-rosetta-patches/build}
crossover=${CROSSOVER_APP:-/Applications/CrossOver.app}
want=26.3.0.39832

version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$crossover/Contents/Info.plist" 2>/dev/null || true)
[ "$version" = "$want" ] || { echo "need CrossOver $want, found '${version:-none}' at $crossover" >&2; exit 1; }

files=(
  "dlls/ntdll/ntdll.so|lib/wine/x86_64-unix/ntdll.so"
  "server/wineserver|bin/wineserver"
  "dlls/wined3d/i386-windows/wined3d.dll|lib/wine/i386-windows/wined3d.dll"
  "dlls/wined3d/x86_64-windows/wined3d.dll|lib/wine/x86_64-windows/wined3d.dll"
)
for entry in "${files[@]}"; do
  [ -f "$build/${entry%%|*}" ] || { echo "missing $build/${entry%%|*}: build crossover-rosetta-patches first" >&2; exit 1; }
done

runner="$here/runner/CrossOver"
if [ ! -d "$runner" ]; then
  mkdir -p "$here/runner"
  cp -c -R "$crossover/Contents/SharedSupport/CrossOver" "$runner" 2>/dev/null ||
    cp -R "$crossover/Contents/SharedSupport/CrossOver" "$runner"
fi
for entry in "${files[@]}"; do
  src=$build/${entry%%|*} dst=$runner/${entry#*|}
  [ -f "$dst.orig" ] || cp -p "$dst" "$dst.orig"
  cp "$src" "$dst.new" && mv -f "$dst.new" "$dst"
done
echo "runner: $runner"

export CX_ROOT="$runner" WINEPREFIX="$here/prefix" WINESERVER="$runner/bin/wineserver"
export WINEDLLPATH="$runner/lib/wine/x86_64-windows:$runner/lib/wine/x86_64-unix" WINEDEBUG=-all
wine="$runner/lib/wine/x86_64-unix/wine"
[ -f "$WINEPREFIX/system.reg" ] || "$wine" wineboot -i > /dev/null 2>&1
# PlayStation controllers through SDL as XInput gamepads (the games read XInput
# only; Wine otherwise exposes Sony pads as raw HID, which XInput ignores).
"$wine" reg add 'HKLM\System\CurrentControlSet\Services\WineBus\Devices\054c' /v Hidraw /t REG_DWORD /d 0 /f > /dev/null 2>&1
"$WINESERVER" -w
echo "prefix: $WINEPREFIX"
