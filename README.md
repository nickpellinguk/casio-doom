# casio-doom

Can a 1985 Casio graphing calculator run Doom? No. Can it draw something that
looks like Doom from across the room? Yes.

![Fake Doom being typed in and drawn](media/doom-fast.gif)

This repository has:

- **`fxrun`**, a command-line, scriptable build of Piotr Piatek's
  [Casio FX-8000G emulator](https://pisi.com.pl/piotr433/fx8000ee.htm). It
  needs no window, Wine or virtual display. It runs the real ROM in emulated
  time, much faster than real time, and saves screenshots or animation frames.
- **`examples/doom.txt`**, a key script that types in and draws a
  first-person corridor, a gun and an enemy.

The FX-8000G is the fx-7000G's sibling: same 96×64 screen, keyboard and
programming language, but with more program memory. Anything drawn here works
the same way on an fx-7000G, as long as it fits in that model's 422 steps.

## Build and run

Needs Free Pascal 3.2 (`apt-get install fp-compiler`), plus `curl` and
`unzip`. Optionally ImageMagick, to turn screenshots into PNGs and GIFs.

```bash
./build.sh
```

```bash
./build/fxrun examples/doom.txt
```

```bash
convert out/doom.pgm out/doom.png
```

`build.sh` runs `fetch.sh` the first time. That downloads the emulator's
Lazarus port (version 13) from Piotr Piatek's site and copies its core units
into `src/` and its ROM images into `rom/`. Neither is stored in this
repository: the core is Piotr Piatek's code and the ROMs are Casio's firmware.

To rebuild the animation from the recorded frames:

```bash
convert -delay 10 -loop 0 out/frames/frame*.pgm -resize 50% -colors 2 -layers Optimize out/doom.gif
```

## How it works

The emulator separates its CPU, display and keyboard code from its window,
so `fxrun` uses these units unchanged:
`def cpu decode exec lcd keyboard fa80`.

The repository's own code is:

- `src/fxrun.pas`: the driver. Its main loop is copied from `OnRunTimer` in
  the emulator's `main.pas`, without the debugger hooks.
- `src/comm.pas`: a stub that replaces the window-based cassette and printer
  unit. No tape or printer is attached.

## Script commands

Usage: `fxrun [-d romdir] [-s] script.txt` (use `-` to read the script from
stdin). `-s` saves the RAM back to `romdir` on exit, as the GUI does. Lines
starting with `#` are comments.

| Command | Meaning |
|---|---|
| `wait MS` | run for MS milliseconds of calculator time |
| `press KEY ...` | press keys in turn; `KEY*N` repeats a key |
| `type TEXT` | type digits, operators, `,` `:` and letters (via ALPHA) |
| `shot FILE.pgm` | save the 96×64 display |
| `ascii` | print the display as text |
| `record DIR [MS]` / `record off` | save a frame every MS ms (default 100) |
| `scale N` | screenshot pixel size (default 4) |
| `hold MS` / `gap MS` | key-down time and gap after release (default 60 each) |
| `init` | memory-initialisation button |

Key names: `SHIFT ALPHA PROG LEFT RIGHT UP DOWN MODE MDISP GRAPH RANGE GT : ENG
SQRT X2 LOG LN RECIP DMS HYP SIN COS TAN NEG STO ( ) POW XROOT 0-9 DEL AC * / +
- . EXP ANS EXE OFF INIT HD`.

SHIFT functions, which press SHIFT for you: `PLOT LINE CLS ABS COMMA THEN GOTO
LBL ISZ DSZ FACTOR INT FRAC PI RAN# MCL ? DISP = <> >= <= > < PRINT ASIN ACOS
ATAN`. The map came from pressing SHIFT with every key:
[media/shift-sheet.png](media/shift-sheet.png).

## Tips for drawing on the calculator

- Set the Range to `1, 96, 0, 1, 64, 0`. That makes one unit one pixel and
  moves the axes off the screen.
- Enter negative Range values with the (-) key (`NEG`), not minus.
- Six `EXE`s on the Range screen leave it. Pressing `RANGE` again reopens it,
  and `AC` doesn't close it.
- `Line` joins the last two plotted points, so `Plot A:Plot B:Line:Plot C:Line`
  draws two connected lines.
- A statement line that ends in `Plot` leaves the flashing pointer and an
  `X=` readout over the bottom of the screen. End it with `Line` instead.
- Graphs draw at real-calculator speed: `Graph Y=.67Abs X` takes about 3
  seconds of calculator time.

## Credits

The emulator is by Piotr Piatek: https://pisi.com.pl/piotr433/
