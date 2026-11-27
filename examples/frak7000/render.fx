# Prog 4: bit renderer. Draws W columns of H dots from the number D,
# starting at column A with the bottom row at C. Each column is H binary
# digits of D, lowest at the bottom: 1 = dot. Leaves A on the next column.
# Each dot is also plotted mirrored, at column E-A: E is the mirror axis
# times two for symmetric sprites, and 0 or negative (off-screen, so
# nothing shows) otherwise.
W→V
Lbl 1
C→B:H→U
Lbl 2
D÷2→D:Frac D≠0⇒Plot A,B:Frac D≠0⇒Plot E-A,B:Int D→D:B+1→B
Dsz U:Goto 2
A+1→A
Dsz V:Goto 1
