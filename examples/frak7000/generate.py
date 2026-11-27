# Builds the compact Frak! front screen (aimed at the fx-7000G's 422 steps):
# pixel-art sprites drawn by the bit renderer, packed two columns per number.
# Writes screen.fx (Prog 0), repeat.fx (Prog 1), pair.fx (Prog 2),
# scrubbly.fx (Prog 3) and render.fx (Prog 4).
#
# Usage:  python3 examples/frak7000/generate.py
import os
HERE = os.path.dirname(os.path.abspath(__file__))

TROGG = """
...####..
..#..####
.#..##...
#..#..#..
#...#.#..
.##...#..
..#..#...
..#..#...
..###.##.
"""
SCRUBBLY = """
.#.....#.
..#####..
.#.....#.
#.##.##.#
#.##.##.#
.#.....#.
#.#####.#
.#.#.#.#.
..##.##..
"""
LEDGE = """
#####
#...#
.#.#.
..#..
"""
LADDER = """
###
.#.
.#.
###
.#.
.#.
###
.#.
.#.
"""

def grid(art):
    rows = art.strip('\n').split('\n')
    w = max(len(r) for r in rows)
    return [r.ljust(w, '.') for r in rows]

def numbers(art, per):
    """One number per `per` columns: each column's dots in binary, lowest
    digit = top row, the next column's digits following on."""
    g = grid(art); h = len(g); w = len(g[0])
    cols = [sum(1 << k for k in range(h) if g[k][x] == '#') for x in range(w)]
    out = []
    for i in range(0, w, per):
        out.append(sum(c << (h * j) for j, c in enumerate(cols[i:i + per])))
    return out, w, h

def write(name, lines):
    open(os.path.join(HERE, name), 'w').write('\n'.join(lines) + '\n')

# Prog 4: the renderer
write('render.fx', [
    '# Prog 4: bit renderer. Draws W columns of H dots from the number D,',
    '# starting at column A with the top row at C. Each column is H binary',
    '# digits of D, lowest at the top: 1 = dot. Leaves A on the next column.',
    '# Each dot is also plotted mirrored, at column E-A: E is the mirror axis',
    '# times two for symmetric sprites, and 0 or negative (off-screen, so',
    '# nothing shows) otherwise.',
    'W→V',
    'Lbl 1',
    'C→B:H→U',
    'Lbl 2',
    'D÷2→D:Frac D≠0⇒Plot A,B:Frac D≠0⇒Plot E-A,B:Int D→D:B-1→B',
    'Dsz U:Goto 2',
    'A+1→A',
    'Dsz V:Goto 1'])

# Prog 1: repeat a bitmap. Draws the W x H pattern P N times, moving by
# (E, F) after each copy on top of the W columns the renderer moves on.
(seg,), lw, lh = numbers(LEDGE, 5)
(rung,), rw, rh = numbers(LADDER, 3)
write('repeat.fx', [
    '# Prog 1: draws the bitmap P (W columns of H dots) N times, starting at',
    '# column A with the top row at C. After each copy it moves on W',
    '# columns plus E, and F rows (negative = down). N and C are left unchanged.',
    'N→K:C→J',
    'Lbl 1',
    'P→D:Prog 4:A+E→A:C+F→C',
    'Dsz K:Goto 1',
    'J→C'])

# Prog 2: a pair. Many objects come in pairs 42 columns apart (the left and
# right halves of the screen), so this draws Prog 1 at A and at A+42.
write('pair.fx', [
    '# Prog 2: draws Prog 1 twice: at column A and 42 columns to the right.',
    '# Many objects on this screen come in pairs that far apart.',
    'A→Q:Prog 1:Q+42→A:Prog 1'])

# Prog 3: Scrubbly. It's symmetric, so only the left half and the centre
# column are stored, and the renderer mirrors them about the centre.
nums, w, h = numbers(SCRUBBLY, 3)
half = nums[:(w // 2 + 1 + 2) // 3]          # numbers covering columns 0..5
write('scrubbly.fx', [
    f'# Prog 3: a Scrubbly ({w}x{h} pixels), top row C. It is placed by E, twice',
    f'# its centre column (E = 2 x left column + {w - 1}), which is also the mirror',
    f'# axis: it is left-right symmetric, so only columns 0-{w // 2} are stored',
    '# (three per number) and the renderer mirrors them. E is left unchanged,',
    '# so two Scrubblies in the same column only need a new C.',
    f'# W=3 and H={h} are already set by the ladders.',
    f'E÷2-{(w - 1) // 2}→A:' + ':'.join(f'{n}→D:Prog 4' for n in half)])

# Prog 0: the screen
tnums, tw, th = numbers(TROGG, 3)
write('screen.fx', [
    '# Frak! front screen (level 1) for the Casio fx-7000G / FX-8000G.',
    '# Layout from room_A_1 in steamfrak; sprites are pixel art drawn by the',
    '# bit renderer (Prog 4). Prog 1 repeats a bitmap (ledges, ladders), Prog 2',
    '# draws a pair 42 columns apart, Prog 3 draws a Scrubbly. Values shared',
    '# between calls are set once.',
    'Range 1,95,0,1,63,0',
    'Cls',
    f'# ledges: a {lw}x{lh} segment (strip and rock basket) repeated to the right.',
    '# A = left end, C = top row, N = segments',
    f'{seg}→P:{lw}→W:{lh}→H:0→E:0→F',
    '48→C:6→N:11→A:Prog 2',
    '# the middle-left platform is 6 blocks too (5 in the original), so N is shared',
    '29→C:11→A:Prog 1:1→N:78→A:Prog 1',
    '# bottom row: just the pair (the original also has a 2-block platform',
    '# at the bottom right, left out here to save bytes)',
    '5→C:11→A:Prog 2',
    '# the staircase: five single ledges, each 20 room pixels right and 7 down',
    '# from the last. Prog 1 draws it directly: E=1.4 on top of the 5 columns',
    '# it already moves, F=-2.1. Drawn last, as the ladders reset E and F.',
    '29→C:5→N:1.4→E:(-)2.1→F:53→A:Prog 1',
    f'# ladders: a {rw}x{rh} segment (a pole with three rungs) hung below a ledge;',
    '# each ladder is one segment (the long one is two calls; they may overlap).',
    '# A = left column, C = top row, N = segments',
    f'{rung}→P:{rw}→W:{rh}→H:(-){rw}→E:(-){rh}→F',
    '44→C:1→N:13→A:Prog 2:80→A:Prog 1',
    '# the long ladder is two single segments, so its top half pairs with the left one',
    '26→C:13→A:Prog 2:17→C:55→A:Prog 1:80→A:Prog 1',
    f'# sprites: {th} rows tall like the ladder segment, so W=3 and H={th} carry over',
    f'# the Trogg ({tw}x{th} pixels), standing on the bottom-left ledge; drawn',
    '# before the Scrubblies, while E is still -3 so his mirror image is off-screen',
    '14→C:8→A:' + ':'.join(f'{n}→D:Prog 4' for n in tnums),
    '# Scrubblies: E = twice the centre column, C = top row',
    '57→C:58→E:Prog 3:136→E:Prog 3:34→C:Prog 3',
    '# show the finished screen (y=0 is off-screen, so nothing is drawn)',
    'Graph Y=0'])
print('Trogg', tnums, '\nScrubbly', nums, '\nledge', seg, '\nladder', rung)
