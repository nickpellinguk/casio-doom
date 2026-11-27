# Prog 1: draws the bitmap P (W columns of H dots) N times, starting at
# column A with the top row at C. After each copy it moves on W
# columns plus E, and F rows (negative = down). N and C are left unchanged.
N→K:C→J
Lbl 1
P→D:Prog 4:A+E→A:C+F→C
Dsz K:Goto 1
J→C
