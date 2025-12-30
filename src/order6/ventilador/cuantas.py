#! /usr/bin/env python3

# TODO: add error handling

# Some internal variables
__author__ = 'Alvaro Lozano Rojo'

import os
import sys


# Global variables (arg!)
if getattr(sys, 'frozen', False):
    # The application is frozen
    BASEPATH = os.path.dirname(sys.executable)
else:
    # The application is not frozen
    # Change this bit to match where you store your data files:
    BASEPATH = os.path.dirname(__file__)

OUTPUT = os.path.join(BASEPATH, 'global_output.txt')

IDs = [17317767192, 17585156104, 17585156098, 17585676292, 17584629770, 17584624656,17585679384]
degsBin = [145,142,137,131,133,125,119]

xx = []
y = []
for k in range(10, 100):
    xx.append((k, 100))
    y.append((k, 10))
xx.extend(y)
del y
rvals = xx
del xx
rvals.append((10, 1))

Tasks = [(ID, tipo, deg, r, fixation) for ID, deg in zip(IDs, degsBin) for tipo in ["ber", "bin"] for r in rvals for fixation in [False, True]]

# Delete already done tasks
with open(OUTPUT, "rt") as infile:
    DONE = []
    for line in infile.readlines():
        id, tipo, deg, r1, r2, fixation, _, _ = line.split()
        id = int(id[:-1])
        tipo = tipo[:-1]
        deg = int(deg[:-1])
        r = (int(r1[1:-1]), int(r2[:-2]))
        fixation = (fixation == "True,")
        DONE.append((id, tipo, deg, r, fixation))
Tasks = list(set(Tasks) - set(DONE))


######################################################
##
## Entry point
##
#####################################################
def main():
    print(f"There are {len(Tasks)} remaining!")

if __name__ == '__main__':
    main()
