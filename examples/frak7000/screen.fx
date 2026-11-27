# Frak! front screen (level 1) for the Casio fx-7000G / FX-8000G.
# Layout from room_A_1 in steamfrak; sprites are pixel art drawn by the
# bit renderer (Prog 4). Prog 1 repeats a bitmap (ledges, ladders), Prog 2
# draws a pair S columns apart, Prog 3 draws a Scrubbly. Values shared
# between calls are set once.
Range 1,95,0,1,63,0
Cls
# ledges: a 5x4 segment (strip and rock basket) repeated to the right.
# A = left end, C = top row, N = segments
219475→P:5→W:4→H:0→E:0→F:42→S
48→C:6→N:11→A:Prog 2
# the middle-left platform is 6 blocks too (5 in the original), so N is shared
29→C:11→A:Prog 1:1→N:78→A:Prog 1
# bottom row: just the pair (the original also has a 2-block platform
# at the bottom right, left out here to save bytes)
5→C:11→A:Prog 2
# the staircase: five single ledges, each 20 room pixels right and 7 down
# from the last. Prog 1 draws it directly: E=1.4 on top of the 5 columns
# it already moves, F=-2.1. Drawn last, as the ladders reset E and F.
29→C:5→N:1.4→E:(-)2.1→F:53→A:Prog 1
# ladders: a 3x9 segment (a pole with three rungs) hung below a ledge;
# each ladder is one segment (the long one is two calls; they may overlap).
# A = left column, C = top row, N = segments
19398217→P:3→W:9→H:(-)3→E:(-)9→F
44→C:1→N:13→A:Prog 2:80→A:Prog 1
# the long ladder is two single segments, so its top half pairs with the left
# one; A is then 55 (a ladder call leaves A where it was), so its bottom half
# and the short ladder at 80 are a pair 25 apart with just a new C and S
26→C:13→A:Prog 2:17→C:25→S:Prog 2
# sprites: 9 rows tall like the ladder segment, so W=3 and H=9 carry over
# the Trogg (9x9 pixels), standing on the bottom-left ledge; drawn
# before the Scrubblies, while E is still -3 so his mirror image is off-screen
14→C:8→A:126371864→D:Prog 4:52308745→D:Prog 4:656699→D:Prog 4
# Scrubblies: E = twice the centre column, C = top row
57→C:58→E:Prog 3:136→E:Prog 3:34→C:Prog 3
# show the finished screen (y=0 is off-screen, so nothing is drawn)
Graph Y=0
