# DOOM for the Casio fx-7000G / FX-8000G, as a stored program.
# An enemy walks down the corridor towards you over four frames, then you fire.
#
# S is the enemy's size, B the height of its feet and C its centre (not X:
# Plot stores its coordinates in X and Y). It
# comes forward and to the left, so it never walks into the gun. Each frame is a full
# Cls and redraw, which is as fast as it gets: about 0.2 frames per second.
#
# Listing conventions (fxrun's "program" command types these as keys):
#   ->  is the STO arrow     =>  is the jump arrow (SHIFT 7)
#   /   is the divide key    lines starting with # are comments
#
# Range 1..96 x 1..64 with scales 0 makes one unit roughly one pixel and
# moves the axes off-screen. (Exactly one pixel is 0..94 x 0..62: the screen
# has 95 x 63 graph pixels.)
Range 1,96,0,1,64,0
2->S
Lbl 1
34-4S->B
52-4S->C
Cls
# corridor: ceiling edges, floor edges, back wall, status bar
Plot 1,64:Plot 36,44:Line:Plot 60,44:Line:Plot 96,64:Line
Plot 96,11:Plot 60,24:Line:Plot 36,24:Line:Plot 1,11:Line
Plot 36,24:Plot 36,44:Line:Plot 60,44:Plot 60,24:Line
Plot 1,11:Plot 96,11:Line
# enemy: legs, body, arms, head, all scaled by S
Plot C-S,B:Plot C,B+1.5S:Line:Plot C+S,B:Line
Plot C,B+1.5S:Plot C,B+3.5S:Line
Plot C-1.5S,B+3S:Plot C+1.5S,B+3S:Line
Plot C-S/2,B+4.5S:Plot C+S/2,B+4.5S:Line
# gun: grip, barrel (drawn last so it stays in front)
Plot 42,11:Plot 45,22:Line:Plot 51,22:Line:Plot 54,11:Line
Plot 47,22:Plot 47,27:Line:Plot 49,27:Line:Plot 49,22:Line
S+1->S
S<6=>Goto 1
# muzzle flash
Plot 46,28:Plot 48,32:Line:Plot 50,28:Line
