# Frak! front screen (level 1) for the Casio fx-7000G / FX-8000G.
# Layout from room_A_1 in steamfrak; sprites are pixel art drawn by the
# bit renderer (Prog 4). Prog 1 repeats a bitmap (ledges, ladders),
# Prog 3 draws a Scrubbly. Values shared between calls are set once.
Range 1,95,0,1,63,0
Cls
# ledges: a 5x4 segment (strip and rock basket) repeated to the right.
# A = left end, C = bottom row, N = segments
829868→P:5→W:4→H:0→E:0→F
45→C:6→N:11→A:Prog 1:53→A:Prog 1
# the middle-left platform is 6 blocks too (5 in the original), so N is shared
26→C:11→A:Prog 1:1→N:78→A:Prog 1
# the staircase: five single ledges, each 20 room pixels right and 7 down
# from the last (about 6.4 and 2.1 here; Prog 1 already moves A on 5)
53→A:5→G
Lbl 1
Prog 1:A+1.4→A:C-2.1→C:Dsz G:Goto 1
2→C:10→A:Prog 1:53→A:Prog 1:2→N:77→A:Prog 1
# ladders: a 3x9 segment (a pole with three rungs) hung below a ledge;
# each ladder is one segment, or two for the long one (they may overlap).
# A = left column, C = bottom row, N = segments
76807972→P:3→W:9→H:(-)3→E:(-)9→F
36→C:1→N:13→A:Prog 1:54→A:Prog 1:80→A:Prog 1
8→C:80→A:Prog 1:18→C:13→A:Prog 1:2→N:54→A:Prog 1
# sprites: three 11-row columns per number (up to 10 digits); W is
# already 3 from the ladders
11→H
# Scrubblies: A = left column, C = feet
49→C:24→A:Prog 3:63→A:Prog 3:26→C:63→A:Prog 3
# the Trogg (12x11 pixels), standing on the bottom-left ledge
7→A:6→C:1678016608→D:Prog 4:4300540751→D:Prog 4:5778480652→D:Prog 4:2148533505→D:Prog 4
# show the finished screen (y=0 is off-screen, so nothing is drawn)
Graph Y=0
