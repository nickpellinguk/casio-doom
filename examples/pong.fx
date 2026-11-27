# PONG for the Casio fx-7000G / FX-8000G.
#
# The calculator can't read a key while a program runs, so this is turn
# based. The computer serves from the right at a random height and angle,
# and the ball bounces towards you, leaving a trail. At the halfway line the
# game stops with a flashing pointer on your side: move it up or down with the
# arrow keys to where you think the ball will arrive, then press EXE. Within
# 5 pixels scores a point and the next serve starts; a miss ends the game and
# shows your score. The ruler on the left edge has a tick every 10 pixels.
#
# How it works:
# - "Plot x,y◢" stops with a movable pointer, and Plot leaves the pointer's
#   position in X and Y, so Y becomes your paddle position.
# - Because of that, the ball uses P and Q, never X and Y.
# - V is the ball's height "unfolded" so it never bounces, and
#   Q = 61-Abs(60-(V mod 120)) folds it back between the walls (1 to 61),
#   so bouncing needs no branches.
# - M: ball slope per pixel    H: your paddle    S: score
#
# Range 0..94 x 0..62 is exactly one unit per pixel. The x axis is the bottom
# wall, and the y axis on the left edge, with Yscl 10, is the ruler.
Range 0,94,0,0,62,10
0→S
Lbl 0
Cls
Plot 0,62:Plot 94,62:Line
88→P:Int (40*Ran#)+11→Q:3*Ran#-1.5→M:Q+1199→V
Plot 91,Q-4:Plot 91,Q+4:Line:Plot P,Q
Lbl 1
P-4→P:V+4M→V:61-Abs (60-120Frac (V÷120))→Q:Plot P,Q:Line
P>48⇒Goto 1
Plot 3,31◢Y→H
Plot 3,H-5:Plot 3,H+5:Line:Plot P,Q
Lbl 2
P-4→P:V+4M→V:61-Abs (60-120Frac (V÷120))→Q:Plot P,Q:Line
P>4⇒Goto 2
Abs (Q-H)>5⇒Goto 3
S+1→S
Goto 0
Lbl 3
S
