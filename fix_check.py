import numpy as np
import math
import random
from scipy.spatial import ConvexHull
from check import checkn
from new_gauge import gen_rays

def reduce(x):
    if abs(x - math.floor(x)) < 10**(-10):
        return math.floor(x)
    elif abs(x - math.ceil(x)) < 10**(-10):
        return math.ceil(x)
    return x

#Randomly choose a point in the polytope
def gen_point(primative_rays):
    # p_range = number of primitive rays in the given polytope - 1
    p_range = 35400
    i = random.randint(0, p_range)
    return primative_rays[i]

#Compute the primitive rays in the polytope in advance to increase the efficiency
def run(totN: int, npoints: int):
    if npoints <= 3:
        print('Number of points should be greater than 3!')
        return 0
    v2 = np.array([-6, -6, 1],dtype = object)
    v4 = np.array([-6, 19, -6],dtype = object)
    goodn = 0
    primative_rays = np.loadtxt('primitive rays_(42,132).txt')
    for times in range(totN):
        raw_vlist = [v2, v4]
        for i in range(npoints - 2):
            v = gen_point(primative_rays)
            raw_vlist.append(v)
        hull = ConvexHull(raw_vlist)
        indexlist = hull.vertices
        vlist = [raw_vlist[i] for i in indexlist]
        if checkn(vlist):
            print('%d:' % (times + 1), end = ' ')
            for v in vlist:
                print('(' + str(int(v[0])) + ',' + str(int(v[1])) + ','+str(int(v[2])) + ')', end = '')
            print(' ', end = '')
            l = len(vlist)
            print(l, end = ' ')
            rays = gen_rays(vlist)
            print('h11=%d' % (len(rays) - 3))
            goodn += 1
    print(goodn)

if __name__ == '__main__':
    print('----------fix check.py----------')
    #test codes
    totN,npoints = 10**7, 100
    print('para:totN=%d,npoints=%d,type=(42,132)' % (totN,npoints))
    run(totN,npoints)
    print('----------fix check.py end----------')