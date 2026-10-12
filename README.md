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

## Requirements

- CrossOver 26.3.0 (build 26.3.0.39832), activated.
- The patches from
  [crossover-rosetta-patches](https://github.com/LuidgiAlt/crossover-rosetta-patches.git),
  built with the steps in their README. This produces the `build/` folder
  that `setup.sh` needs.
- The games through Steam. Plutonium requires owning them.

## Setup

1. Clone the patches next to this folder:
   ```bash
   git clone https://github.com/LuidgiAlt/crossover-rosetta-patches.git ../crossover-rosetta-patches
   ```
2. Build them with the steps in their README.
3. Create the runner and prefix:
   ```bash
   ./setup.sh ../crossover-rosetta-patches/build
   ```

This creates:
- `runner/CrossOver`: an APFS copy of CrossOver's runtime with the patched
  files. The originals are kept as `*.orig`. CrossOver.app is not modified.
- `prefix/`: the Wine prefix.

Install Plutonium into the prefix with the installer from plutonium.pw:

```bash
./run.sh install ~/Downloads/plutonium.exe
```

If Plutonium is installed somewhere else, set `PLUTONIUM_DIR` to its folder,
the one that contains `bin/plutonium-launcher-win32.exe`.

## Playing

```bash
./run.sh            # start the Plutonium launcher
./run.sh kill       # stop everything in the prefix
```

In the launcher, point each game at its Steam folder, for example
`~/Library/Application Support/Steam/steamapps/common/Call of Duty Black Ops II`.

| Option | Effect |
|---|---|
| `PLUTONIUM_DIR=…` | Plutonium folder (default `%LOCALAPPDATA%\Plutonium` in the prefix) |
| `RENDERER=dxmt` | CrossOver's DXMT instead of wined3d |
| `LAZY_EXEC=0` | Turn the stall fix off, for comparison |
| `WINDOWED=1` | Force BO2's Windowed mode |

## Notes

- **MSAA.** Apple GPUs support at most 4x MSAA. A fresh BO2 config can ask
  for 8x and crash with `sample count 8 is not supported`. `run.sh` clamps
  the text configs to 4x. If it still crashes, the binary
  `players/hardware_*.chp` also asks for 8x: lower anti-aliasing in the game
  settings, or restore a working copy of that file.
- **Controllers.** The games read XInput only. `setup.sh` makes Wine present
  PlayStation pads (DualSense, DualShock 4) as XInput gamepads through SDL.
  Connect the pad before starting.
- **Pipeline cache.** The first launch hitches in menus while wined3d fills
  its pipeline cache. Later launches don't.

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
- `RENDERER=dxmt`. CrossOver's bundled DXMT is v0.72; BO2 was tested with
  DXMT v0.80 installed separately.
- World at War, Black Ops and MW3. Their Plutonium executables also lack
  `NX_COMPAT` and use the same client, so they likely need the same fixes.

## License

The scripts are under the MIT license (`LICENSE`).

Plutonium, Call of Duty and CrossOver belong to their owners. This project is
not affiliated with them.
