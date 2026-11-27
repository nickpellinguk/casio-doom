# Prog 3: a Scrubbly (9x9 pixels), top row C. It is placed by E, twice
# its centre column (E = 2 x left column + 8), which is also the mirror
# axis: it is left-right symmetric, so only columns 0-4 are stored
# (three per number, the columns past the centre left empty) and the
# renderer mirrors them. E is left unchanged,
# so two Scrubblies in the same column only need a new C. Its two numbers
# are stored in M and Z beforehand (setup.fx).
# W=3 and H=9 are already set by the ladders.
E÷2-4→A:M→D:Prog 4:Z→D:Prog 4
