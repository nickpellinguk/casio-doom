# Fake Linux for the Casio fx-7000G / FX-8000G.
# A Tux boot splash (press EXE to see the boot messages, as on a real
# splash screen), then a boot log and a login prompt that says
# PERMISSION DENIED to everyone, forever. Prog 1 is the bit renderer.
Range 1,95,0,1,63,0
# Tux: 13x16, symmetric, so only columns 0-6 are stored, two per
# number; E (twice the centre column) mirrors the rest
2→W:16→H:42→A:40→C:96→E
3741355008→D:Prog 1:2717843328→D:Prog 1:1077362919→D:Prog 1:16559→D:Prog 1
# show the splash and wait for EXE, then the boot log (16 characters a line)
Graph Y=0◢"[0.00] LINUX"
"[0.01] UPD1007"
"[0.02] 910KHZ"
"[0.03] 422 STEPS"
"[0.08] ROOT OK"
"[0.31] INIT"
# the login prompt only takes numbers, and refuses them all
Lbl 1
"FX7000G LOGIN"
?→A
"PERMISSION"
"DENIED"
Goto 1
