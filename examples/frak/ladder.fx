# Prog 2: a ladder hanging from (A,B), L pixels long.
# Two rails, and rungs that stick out either side.
Plot A-1,B:Plot A-1,B-L:Line:Plot A+1,B:Plot A+1,B-L:Line
Lbl 1
Plot A-2,B-1:Plot A+2,B-1:Line
B-2.3→B:L-2.3→L
L>1⇒Goto 1
