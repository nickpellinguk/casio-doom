# Builds the fake Linux boot (linux.fx, Prog 0): a Tux splash drawn by the
# bit renderer (render.fx, Prog 1, from the compact Frak! screen), then a
# boot log and a login prompt that refuses everyone.
#
# Usage:  python3 examples/linux/generate.py
import os
HERE = os.path.dirname(os.path.abspath(__file__))

TUX = """
....#####....
...#######...
...#######...
...#..#..#...
...#.#.#.#...
...#######...
...##...##...
..###.#.###..
.###.....###.
.##.......##.
###.......###
###.......###
.##.......##.
..##.....##..
.##.#####.##.
####.....####
"""
rows = TUX.strip('\n').split('\n')
H, W = len(rows), len(rows[0])
assert all(r == r[::-1] for r in rows), 'Tux must be symmetric'
centre = W // 2
# columns past the centre are left empty: the renderer's mirror draws them
cols = [sum(1 << k for k in range(H) if rows[k][x] == '#') if x <= centre else 0 for x in range(W)]
PER = 2                                   # 2 x 16 = 32 binary digits, 10 typed digits
nums = [sum(c << (H * j) for j, c in enumerate(cols[i:i + PER])) for i in range(0, centre + 1, PER)]
assert all(len(str(n)) <= 10 for n in nums)

LEFT, TOP = 42, 40                        # centred on the 95x63 screen
lines = [
    '# Fake Linux for the Casio fx-7000G / FX-8000G.',
    '# A Tux boot splash, then a boot log and a login prompt that says',
    '# PERMISSION DENIED to everyone, forever. Prog 1 is the bit renderer.',
    'Range 1,95,0,1,63,0',
    f'# Tux: {W}x{H}, symmetric, so only columns 0-{centre} are stored, two per',
    f'# number; E (twice the centre column) mirrors the rest',
    f'{PER}→W:{H}→H:{LEFT}→A:{TOP}→C:{2 * (LEFT + centre)}→E',
    ':'.join(f'{n}→D:Prog 1' for n in nums),
    '# keep the splash up for about 4.5 seconds: each Graph Y=0 takes about',
    '# 1.1 s and draws nothing (y=0 is off-screen), and graph commands keep',
    '# the graph screen showing, where a counting loop would switch to text',
    'Graph Y=0:Graph Y=0:Graph Y=0:Graph Y=0',
    '# the boot log (16 characters a line)',
    '"[0.00] LINUX"',
    '"[0.01] UPD1007"',
    '"[0.02] 910KHZ"',
    '"[0.03] 422 STEPS"',
    '"[0.08] ROOT OK"',
    '"[0.31] INIT"',
    '# a pause of about 3 seconds (Dsz counts Z down), then an empty line',
    '60→Z',
    'Lbl 2',
    'Dsz Z:Goto 2',
    '" "',
    '# the login prompt only takes numbers, and refuses them all',
    'Lbl 1',
    '"FX7000G LOGIN"',
    '?→A',
    '"PERMISSION"',
    '"DENIED"',
    'Goto 1',
]
open(os.path.join(HERE, 'linux.fx'), 'w').write('\n'.join(lines) + '\n')
print('\n'.join(l for l in lines if not l.startswith('#')))
