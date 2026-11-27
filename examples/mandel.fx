# The world's slowest Mandelbrot generator, for the Casio fx-7000G / FX-8000G.
#
# For every pixel, iterate z -> z² + c up to 15 times and plot the pixel if
# z hasn't escaped. The set is symmetric about the real axis, so each column
# only computes the top half and plots each point twice.
#
# A, B: pixel column and row (B counts up from the middle)
# C, D: c, the point being tested     R, I: z     T: scratch
# N: iteration count
#
# The calculator shows its text screen whenever a non-graph statement runs,
# so on its own you'd watch "Prog 2" for half an hour. Plot A,0 at the end of
# each column (on the bottom axis, which is already dark) flips to the graph
# so you can see progress, and Graph Y=0 (also just the axis) ends the
# program on the picture.
#
# Range 0..94 x 0..62 is one unit per pixel; the axes frame the bottom and
# left edges. Each pixel is .034 wide, so the picture spans -2.2 to 1 on the
# real axis and about -1.05 to 1.05 on the imaginary axis, with square pixels.
Range 0,94,0,0,62,0
Cls
0→A
Lbl 1
.034A-2.2→C
0→B
Lbl 2
.034B→D
0→R:0→I:0→N
Lbl 3
R²-I²+C→T:2RI+D→I:T→R:N+1→N
R²+I²<4⇒N<15⇒Goto 3
N=15⇒Plot A,31+B
N=15⇒Plot A,31-B
B+1→B
B<32⇒Goto 2
Plot A,0
A+1→A
A<95⇒Goto 1
Graph Y=0
