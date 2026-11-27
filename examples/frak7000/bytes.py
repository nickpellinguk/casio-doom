# Estimates how many bytes (steps) each program listing takes on the
# calculator: one per command or character, plus one per line end.
import sys, re
KW = ['Graph Y=', 'Range ', 'Plot ', 'Line', 'Cls', 'Lbl ', 'Goto ', 'Isz ', 'Dsz ', 'Prog ',
      'Abs ', 'Int ', 'Frac ', 'Ran#', '→', '⇒', '◢', '≠', '÷', '²', '->', '=>', '<=', '>=', '<>']
def size(path):
    total = 0
    for line in open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line.strip() or line.lstrip().startswith('#'): continue
        i = 0
        while i < len(line):
            for k in KW:
                if line.startswith(k, i): i += len(k); break
            else: i += 1
            total += 1
        total += 1
    return total
t = 0
for p in sys.argv[1:]:
    n = size(p); t += n; print(f'{n:5}  {p}')
print(f'{t:5}  total')
