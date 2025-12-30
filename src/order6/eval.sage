#! /usr/bin/env sage


import pickle
import numpy as np
import matplotlib.pyplot as plt

def id2el(Id):
    """Constructs the graph associated to the number Id.
    """
    el = []

    Id = int(Id)

    mask = int(1)
    u = int(0)
    v = int(1)
    while u < 10:
        if (Id & mask):
            el.append((u,v))
    
        mask = (mask << int(1))
        v += int(1)
    
        if v > 10:
            u += 1
            v = u+1
    return el
id2G  = lambda Id : Graph(id2el(np.uint64(Id)))


def G2id(G):
    for ID in Xber:
        if nx.is_isomorphic(G, id2G(ID)):
            return ID
    return None


with open("jobs.pickle", "rb") as infile:
    Xber = pickle.load(infile)
IDs = [ ID for ID in Xber.keys() if id2G(ID).order()==6]
Xber = {ID:Xber[ID] for ID in IDs}

remaining =  list((i,G) for i,G in enumerate(G for G in graphs(6) if G.is_connected()))
asig = {}
for ID in IDs:
    Gp = id2G(ID)
    for k,(i,G) in enumerate(remaining):
        if G.is_isomorphic(Gp):
            asig[ID] = (i,G)
            del remaining[k]
            break
    else:
        raise "Error"

r,p = var("r, p")
xx = []
y = []
for k in range(10,100):
    xx.append((k,100))
    y.append((k,10))
xx.extend(y)
del y
rvals = [ a[0]/a[1] for a in xx ]
del xx

import sys




for ID in IDs:
    i,G = asig[ID]

    if i == int(sys.argv[-1]):
        load(f"{i}.sage")

        line = [ n(moran_unconditional_mean_time_from1(r=vr)) for vr in rvals ]
        print(ID, "moran_unconditional_mean_time_from1", ", ".join(str(x) for x in line), sep=", ")
        line = [ n(moran_conditional_mean_time_from1(r=vr)) for vr in rvals ]
        print(ID, "moran_conditional_mean_time_from1", ", ".join(str(x) for x in line), sep=", ")
        line = [ n(bernoulli_unconditional_mean_time_from1(r=vr, p=Rational(vp))) for vr, vp in zip(rvals, Xber[ID]) ]
        print(ID, "bernoulli_unconditional_mean_time_from1", ", ".join(str(x) for x in line), sep=", ")
        line = [ n(bernoulli_conditional_mean_time_from1(r=vr, p=Rational(vp))) for vr, vp in zip(rvals, Xber[ID]) ]
        print(ID, "bernoulli_conditional_mean_time_from1", ", ".join(str(x) for x in line), sep=", ")

        quit()
