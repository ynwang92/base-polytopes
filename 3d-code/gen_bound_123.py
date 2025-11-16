import numpy as np
from math import gcd
import matplotlib.pyplot as plt

#generate list of first three vertices in a cubic box
def gen_v123(bound1, bound2):
    v123list_list = []
    v1 = np.array([1, 0, 0], dtype = object)
    for q in range(bound1, bound2 + 1):
        for p in range(q):
            #(p, q, 0) here DO NOT need to be primitive since we are checking dual polytope
            v2 = np.array([p, q, 0], dtype = object)
            for t in range(bound1, bound2 + 1):
                for r in range(t):
                    for s in range(t):
                        v3 = np.array([r, s, t], dtype = object)
                        v123list_list.append([v1, v2, v3])
    return v123list_list

#write the bounded vertices in a file
def gen_bound_v123(bound1, bound2):
    filename = 'v123_bound_%d_to_%d.txt' % (bound1, bound2)
    with open(filename, 'w') as file:
        v123list_list = gen_v123(bound1, bound2)
        for v123list in v123list_list:
            for v in v123list:
                file.write('(%d,%d,%d) ' % (v[0], v[1], v[2]))
            file.write('\n')
        file.close()

#Convert string_type vlist to list_type
def StringToList(s):
    s = s[:-1]
    vlist_str = s.split(' ')
    vlist = []
    for temp in vlist_str:
        v_str = temp[1: -1]
        print(v_str)
        v1, v2, v3 = int(v_str.split(',')[0]), int(v_str.split(',')[1]), int(v_str.split(',')[2])
        vlist.append(np.array([v1, v2, v3], dtype = object))
    return vlist

if __name__ == '__main__':
    gen_bound_v123(1, 6)
