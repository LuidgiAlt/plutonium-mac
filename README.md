# Plutonium on Apple Silicon

Scripts to run [Plutonium](https://plutonium.pw) on an Apple Silicon Mac with
CrossOver 26.3 and the
[CrossOver Rosetta patches](https://github.com/LuidgiAlt/crossover-rosetta-patches.git). Tested with Black
Ops II (Zombies and Multiplayer with bots) on an M1 Pro.

Stock CrossOver cannot run it:
- Plutonium arms x86 hardware breakpoints that Rosetta cannot deliver, so the
  game hangs at `Loading fastfile code_pre_gfx_zm`.
- The bootstrapper has no `NX_COMPAT` flag, so Wine turns DEP off and the game
  stalls for seconds at a time.

The patches from
[crossover-rosetta-patches](https://github.com/LuidgiAlt/crossover-rosetta-patches.git)
are required: without them, neither Plutonium nor the games run correctly.
Their patch 0005 also removed Black Ops II's multiplayer slowdowns: the main
game thread spent about half its time in Wine's `PulseEvent`.

## Results (Black Ops II, M1 Pro)

| | |
|---|---|
| Renderer | DXMT v0.80 (`RENDERER=dxmt`); it played better than wined3d on Vulkan |
| Multiplayer, 1080p | Median 97 FPS, lowest second 38 FPS (median 68 and lowest 20 before patch 0005) |
| Zombies and Multiplayer with bots | No stalls since patch 0004 |

## Requirements

- CrossOver 26.3.0 (build 26.3.0.39832), activated.
- The patches from
  [crossover-rosetta-patches](https://github.com/LuidgiAlt/crossover-rosetta-patches.git),
  built with the steps in their README. This produces the `build/` folder
  that `setup.sh` needs.
- The games through Steam. Plutonium requires owning them.
- For Black Ops II, recommended: DXMT v0.80, `dxmt-v0.80-builtin.tar.gz` from
  [DXMT's releases](https://github.com/3Shain/dxmt/releases/tag/v0.80)
  (SHA-256 `8f260e36b5739e68f3bad613381441385c4dc7b85b78ba8de653d5a6a264529d`).
  CrossOver 26.3 bundles v0.72.

## Setup

1. Clone the patches next to this folder:
   ```bash
   git clone https://github.com/LuidgiAlt/crossover-rosetta-patches.git ../crossover-rosetta-patches
   ```
2. Build them with the steps in their README.
3. Create the runner and prefix, with DXMT v0.80 if you downloaded it:
   ```bash
   DXMT_ARCHIVE=~/Downloads/dxmt-v0.80-builtin.tar.gz ./setup.sh ../crossover-rosetta-patches/build
   ```
   Without `DXMT_ARCHIVE`, the runner keeps CrossOver's DXMT v0.72.

This creates:
- `runner/CrossOver`: an APFS copy of CrossOver's runtime with the patched
  files. The originals are kept as `*.orig`, and CrossOver's DXMT as
  `lib/dxmt.cx` when v0.80 replaces it. CrossOver.app is not modified.
- `prefix/`: the Wine prefix.

Install Plutonium into the prefix with the installer from plutonium.pw:

```bash
./run.sh install ~/Downloads/plutonium.exe
```

If Plutonium is installed somewhere else, set `PLUTONIUM_DIR` to its folder,
the one that contains `bin/plutonium-launcher-win32.exe`. Plutonium keeps its
settings and logs in the prefix's `AppData/Local/Plutonium` even when it runs
from another folder, so `run.sh` makes that a link to `PLUTONIUM_DIR`; if a
real folder is already there, it stops and asks you to move it.

## Playing

```bash
RENDERER=dxmt ./run.sh   # start the Plutonium launcher, BO2 on DXMT (recommended)
./run.sh                 # the same with wined3d on Vulkan
./run.sh kill            # stop everything in the prefix
```

In the launcher, point each game at its Steam folder, for example
`~/Library/Application Support/Steam/steamapps/common/Call of Duty Black Ops II`.

| Option | Effect |
|---|---|
| `PLUTONIUM_DIR=…` | Plutonium folder (default `%LOCALAPPDATA%\Plutonium` in the prefix) |
| `RENDERER=dxmt` | DXMT instead of wined3d for Direct3D 10/11 (BO2): installs DXMT as Wine's `d3d11` and `dxgi` |
| `MAXFPS=<n>` | With DXMT, cap the frame rate with Metal's frame pacing (e.g. 60) |
| `LAZY_EXEC=0` | Turn the stall fix off, for comparison |
| `WINDOWED=1` | Force BO2's Windowed mode |
| `D3D9=vulkan` | wined3d's Vulkan renderer for Direct3D 9 games instead of OpenGL. Black Ops needs further wined3d patches for it (a separate project, not published yet); without them its world stays black |

## Notes

- **MSAA.** Apple GPUs support at most 4x MSAA. A fresh BO2 config can ask
  for 8x and crash with `sample count 8 is not supported`. `run.sh` clamps
  the text configs to 4x. If it still crashes, the binary
  `players/hardware_*.chp` also asks for 8x: lower anti-aliasing in the game
  settings, or restore a working copy of that file.
- **Controllers.** The games read XInput only. `setup.sh` makes Wine present
  PlayStation pads (DualSense, DualShock 4) as XInput gamepads through SDL.
  Connect the pad before starting.
- **Pipeline cache.** With wined3d, the first launch hitches in menus while
  wined3d fills its pipeline cache (patch 0003, saved in the background).
  Later launches don't. DXMT keeps its own cache in
  `$(getconf DARWIN_USER_CACHE_DIR)dxmt/`; a shader it has not seen yet still
  costs a short hitch the first time.

## Tools

- `tools/hitches.sh [zm|mp]` lists BO2's own `Hitch warning` lines, each with
  the log line before it, so loading hitches can be told apart from in-match
  ones.
- `tools/xinput-test.c` shows what a game sees through XInput. The build and
  run commands are in the file.

## Not tested

- `./run.sh install`, with Plutonium's installer in a fresh prefix. The
  tested install was an existing Plutonium folder used through
  `PLUTONIUM_DIR`.
- `RENDERER=dxmt` through these scripts. BO2 was tested with DXMT v0.80
  installed the same way (as Wine's `d3d11`/`dxgi`) in the author's own setup;
  `setup.sh DXMT_ARCHIVE=...` and this `run.sh` path have not been run on a
  fresh machine. CrossOver's bundled v0.72 is untested.
- World at War, Black Ops and MW3. Their Plutonium executables also lack
  `NX_COMPAT` and use the same client, so they likely need the same fixes.

## License

The scripts are under the MIT license (`LICENSE`).

Plutonium, Call of Duty and CrossOver belong to their owners. This project is
not affiliated with them.
