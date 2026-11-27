# Frak! front screen (level 1), as outline art for the Casio FX-8000G.
# Prog 0 draws the screen using three subroutines:
#   Prog 1  ledge run: A,B = left end and top, N = 16-pixel segments
#   Prog 2  ladder:    A,B = centre and top, L = length
#   Prog 3  Scrubbly:  A,B = feet
# Positions come from room_A_1 in steamfrak, scaled down about 3 times.
# (The ladder behind the Trogg stops above his head so the outlines
# don't merge.)
# Range 1..95 x 1..63 is one unit per pixel, with the axes off-screen.
Range 1,95,0,1,63,0
Cls
# ledges
11→A:48→B:6→N:Prog 1
53→A:48→B:6→N:Prog 1
11→A:29→B:5→N:Prog 1
53→A:29→B:1→N:Prog 1
78→A:29→B:1→N:Prog 1
59→A:27→B:1→N:Prog 1
66→A:25→B:1→N:Prog 1
72→A:22→B:1→N:Prog 1
78→A:20→B:1→N:Prog 1
10→A:5→B:1→N:Prog 1
53→A:5→B:1→N:Prog 1
77→A:5→B:2→N:Prog 1
# ladders (hanging under the ledges)
14→A:44→B:9→L:Prog 2
14→A:25→B:4→L:Prog 2
55→A:44→B:9→L:Prog 2
55→A:25→B:17→L:Prog 2
81→A:44→B:9→L:Prog 2
81→A:16→B:4→L:Prog 2
# Scrubblies
29→A:49→B:Prog 3
68→A:49→B:Prog 3
68→A:25→B:Prog 3
# the Trogg, facing right: legs, belly, long snout, hair, hunched back
Plot 17,6:Plot 15,6:Line:Plot 14,9:Line:Plot 16,11:Line:Plot 16,14:Line:Plot 15,16:Line:Plot 15,17:Line:Plot 19,18:Line:Plot 16,19:Line
Plot 16,19:Plot 13,19:Line:Plot 11,18:Line:Plot 9,16:Line:Plot 8,13:Line:Plot 9,10:Line:Plot 11,9:Line:Plot 11,6:Line:Plot 13,6:Line
Plot 14,18:Plot 12,18:Plot 10,15:Line:Plot 12,16:Plot 11,13:Line:Plot 13,11:Line
