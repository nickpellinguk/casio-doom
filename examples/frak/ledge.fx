# Prog 1: a run of N ledge segments, left end A, top B.
# A top strip, then a tapered rock basket under each segment.
Plot A,B:Plot A+5.2N,B:Line
Lbl 1
Plot A,B-1:Plot A+1,B-3:Line:Plot A+4,B-3:Line:Plot A+5,B-1:Line
A+5.2→A
Dsz N
Goto 1
