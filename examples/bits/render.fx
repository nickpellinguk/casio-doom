# Prog 4: the bit renderer. Draws the number N as a column of dots at
# column A, one row per binary digit, lowest digit at the bottom (row C):
# a 1 is a dot, a 0 is a gap. If M isn't 0, its digits carry on upwards
# from row C+H, so a column can be taller than one number can hold.
# Moves A on to the next column when done.
#
# Halving keeps N exact up to about 34 binary digits.
C→B
Lbl 1
Frac (N÷2)≠0⇒Plot A,B
Int (N÷2)→N:B+1→B
N>0⇒Goto 1
M=0⇒Goto 2
M→N:0→M:C+H→B:Goto 1
Lbl 2
A+1→A
