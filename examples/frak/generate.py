# Generates the Frak! front-screen listings (screen.fx, ledge.fx, ladder.fx,
# scrubbly.fx) from room_A_1 in a steamfrak checkout.
#
# Usage:  python3 examples/frak/generate.py [path/to/steamfrak]
# (default ../steamfrak, next to this repository)
import re, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
STEAMFRAK = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..', '..', 'steamfrak')
S = 3.1                      # room pixels per calculator pixel, across
SY = 3.25                    # and down (a little more, so it all fits)
X0, Y0 = 0, 20               # room point at the top-left of the calculator screen
VIEW_W = 94 * S              # room width that fits
def cx(rx): return round(1 + (rx - X0) / S)
def cy(ry): return round(63 - (ry - Y0) / SY)
def n(v):   # shortest text for a number
    v = round(v, 1); return str(int(v)) if v == int(v) else ('%g' % v).lstrip('0') if 0 < v < 1 else '%g' % v

src = open(os.path.join(STEAMFRAK, 'js', 'data', 'rooms.js')).read()
room = json.loads(re.search(r'^  "room_A_1": (\{.*\}),?$', src, re.M).group(1))
LEDGE_W = {'oLedge1': 16, 'oLedge2': 32, 'oLedge5': 80, 'oLedge6': 96}
LADDER_H = {'oLadder1': 14, 'oLadder2': 28, 'oLadder4': 56}

# merge ledges that touch end to end at the same height into runs of 16-pixel segments
segs = {}
for o, x, y, *_ in room['inst']:
    if o in LEDGE_W:
        for k in range(LEDGE_W[o] // 16):
            sx = x + 16 * k
            if sx + 16 <= VIEW_W * 1.0 + X0 + 1: segs.setdefault(y, []).append(sx)
runs = []
for y, xs in segs.items():
    xs.sort(); start = prev = xs[0]
    for sx in xs[1:] + [None]:
        if sx is not None and abs(sx - (prev + 16)) < 2: prev = sx; continue
        runs.append((start, y, int((prev + 16 - start) / 16)))
        if sx is not None: start = prev = sx
runs.sort(key=lambda r: (r[1], r[0]))
ladders = sorted((x, y, LADDER_H[o]) for o, x, y, *_ in room['inst'] if o in LADDER_H and x + 8 <= X0 + VIEW_W)
scrubblies = sorted((x, y) for o, x, y, *_ in room['inst'] if o == 'oScrubbly' and x + 17 <= X0 + VIEW_W)
trogg = next((x, y) for o, x, y, *_ in room['inst'] if o == 'oTrogg')

trogg = next((x, y) for o, x, y, *_ in room['inst'] if o == 'oTrogg')
main = ['# Frak! front screen (level 1), as outline art for the Casio FX-8000G.',
        '# Prog 0 draws the screen using three subroutines:',
        '#   Prog 1  ledge run: A,B = left end and top, N = 16-pixel segments',
        '#   Prog 2  ladder:    A,B = centre and top, L = length',
        '#   Prog 3  Scrubbly:  A,B = feet',
        '# Positions come from room_A_1 in steamfrak, scaled down about 3 times.',
        '# (The ladder behind the Trogg stops above his head so the outlines',
        "# don't merge.)",
        '# Range 1..95 x 1..63 is one unit per pixel, with the axes off-screen.',
        'Range 1,95,0,1,63,0', 'Cls', '# ledges']
for x, y, k in runs:
    main.append(f'{n(cx(x))}→A:{n(cy(y))}→B:{k}→N:Prog 1')
main.append('# ladders (hanging under the ledges)')
for x, y, h in ladders:
    if abs(x - trogg[0]) < 12 and y + h > trogg[1] - 40:
        h = trogg[1] - 52 - y      # stop above the Trogg's head so the outlines don't merge
    main.append(f'{n(cx(x + 2))}→A:{n(cy(y))}→B:{n(round(h / SY))}→L:Prog 2')
main.append('# Scrubblies')
for x, y in scrubblies:
    main.append(f'{n(cx(x))}→A:{n(cy(y))}→B:Prog 3')
# Trogg: outline facing right, feet at (tx, ty)
tx, ty = cx(trogg[0]), cy(trogg[1])
# outline from the front foot: front leg, belly, chin, long snout, head,
# hair sweeping back, hunched back, back leg and foot
ty += 1   # feet one pixel above the ledge so they don't vanish into it
pts = [(4,0),(2,0),(1,3),(3,5),(3,8),(2,10),(2,11),(6,12),(3,13),(0,13),(-2,12),(-4,10),(-5,7),(-4,4),(-2,3),(-2,0),(0,0)]
main.append('# the Trogg, facing right: legs, belly, long snout, hair, hunched back')
P = lambda px, py: f'Plot {n(tx + px)},{n(ty + py)}'
line = [P(*pts[0])] + [P(*q) + ':Line' for q in pts[1:]]
main.append(':'.join(line[:9]))
main.append(P(*pts[8]) + ':' + ':'.join(line[9:]))
# eye, hair strand, arm (ending on Line, not Plot, so no pointer is left on screen)
main.append(f'{P(1,12)}:{P(-1,12)}:{P(-3,9)}:Line:{P(-1,10)}:{P(-2,7)}:Line:{P(0,5)}:Line')
open(os.path.join(HERE, 'screen.fx'), 'w').write('\n'.join(main) + '\n')

ledge = ['# Prog 1: a run of N ledge segments, left end A, top B.',
         '# A top strip, then a tapered rock basket under each segment.',
         'Plot A,B:Plot A+5.2N,B:Line',
         'Lbl 1',
         'Plot A,B-1:Plot A+1,B-3:Line:Plot A+4,B-3:Line:Plot A+5,B-1:Line',
         'A+5.2→A',
         'Dsz N',
         'Goto 1']
open(os.path.join(HERE, 'ledge.fx'), 'w').write('\n'.join(ledge) + '\n')

ladder = ['# Prog 2: a ladder hanging from (A,B), L pixels long.',
          '# Two rails, and rungs that stick out either side.',
          'Plot A-1,B:Plot A-1,B-L:Line:Plot A+1,B:Plot A+1,B-L:Line',
          'Lbl 1',
          'Plot A-2,B-1:Plot A+2,B-1:Line',
          'B-2.3→B:L-2.3→L',
          'L>1⇒Goto 1']
open(os.path.join(HERE, 'ladder.fx'), 'w').write('\n'.join(ladder) + '\n')

scrub = ['# Prog 3: a Scrubbly standing at (A,B).',
         '# Spiky furry body on two short legs, antennae, square eyes, and a mouth with two fangs.',
         'Plot A-3,B:Plot A-3,B+2:Line:Plot A+3,B:Plot A+3,B+2:Line',
         'Plot A-3,B+2:Plot A+3,B+2:Line:Plot A+5,B+3:Line:Plot A+7,B+4:Line:Plot A+5,B+6:Line:Plot A+7,B+8:Line',
         'Plot A+4,B+9:Line:Plot A+5,B+11:Line:Plot A+2,B+11:Line:Plot A,B+12:Line:Plot A-2,B+11:Line:Plot A-5,B+11:Line',
         'Plot A-4,B+9:Line:Plot A-7,B+8:Line:Plot A-5,B+6:Line:Plot A-7,B+4:Line:Plot A-5,B+3:Line:Plot A-3,B+2:Line',
         'Plot A,B+12:Plot A-2,B+15:Line:Plot A-3,B+14:Line:Plot A,B+12:Plot A+2,B+15:Line:Plot A+3,B+14:Line',
         'Plot A-3,B+9:Plot A-1,B+9:Line:Plot A-1,B+7:Line:Plot A-3,B+7:Line:Plot A-3,B+9:Line',
         'Plot A+1,B+9:Plot A+3,B+9:Line:Plot A+3,B+7:Line:Plot A+1,B+7:Line:Plot A+1,B+9:Line',
         'Plot A-3,B+5:Plot A+3,B+5:Line:Plot A-2,B+4:Plot A-2,B+3:Line:Plot A+2,B+4:Plot A+2,B+3:Line']
open(os.path.join(HERE, 'scrubbly.fx'), 'w').write('\n'.join(scrub) + '\n')
print(open(os.path.join(HERE, 'screen.fx')).read())
