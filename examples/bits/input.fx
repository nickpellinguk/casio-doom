# Prog 5: type numbers and see them as columns of dots, left to right.
# Each answer to ? becomes the next column (lowest binary digit at the
# bottom). After each column the picture is shown: press EXE to enter
# the next number. Press AC to stop.
Range 1,95,0,1,63,0
Cls
1→A:2→C:0→M
Lbl 1
?→N:Prog 4
Graph Y=0◢Goto 1
