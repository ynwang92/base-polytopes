import numpy as np
from scipy.spatial import ConvexHull
from basic import coplanar, interiorn, cross
from solve3 import solve_lattice
import math

def primitive(v):
    return math.gcd(int(v[0]), int(v[1]), int(v[2])) == 1

def checkn(vlist, open_out_flag = False):
    if len(vlist) <= 3:
        if open_out_flag:
            print('list too short')
        return False
    for v in vlist:
        if not primitive(v):
            if open_out_flag:
                print('None primitive ray', end=' ')
                print(v)
            return False
    flag1 = True
    i = 1
    while flag1 and i < len(vlist) - 1:
        i += 1
        if np.linalg.norm(cross(vlist[1] - vlist[0],vlist[i] - vlist[0])) > 10**(-7):
            flag1 = False
    if flag1:
        if open_out_flag:
            print('All vertices are colinear')
        return False
    flag2 = True
    j = 1
    while flag2 and j < len(vlist)-1:
        j += 1
        if j == i:
            continue
        if not coplanar(vlist[0], vlist[1], vlist[i], vlist[j]):
            flag2 = False
    if flag2:
        if open_out_flag:
            print('All vertices are coplanar')
        return False
    hull = ConvexHull(vlist)
    vertices = [hull.points[_] for _ in hull.vertices]
    skeleton_hull = ConvexHull(vertices)
    skeleton_hull_facets = skeleton_hull.simplices
    skeleton_hull_vertices = skeleton_hull.points
    if not interiorn(skeleton_hull_vertices, skeleton_hull_facets, np.array([0,0,0])):
        if open_out_flag:
            print('Origin not in the original interior')
        return False
    solutions = solve_lattice(vlist,6)
    if len(solutions) < 4:
        if open_out_flag:
            print('Solution list too short')
        return False
    k = 1
    flag3 = True
    while flag3 and k < len(solutions)-1:
        k += 1
        c = cross(solutions[1] - solutions[0], solutions[k] - solutions[0])
        if np.dot(c,c) > 10**(-14):
            flag3 = False
    if flag3:
        if open_out_flag:
            print('Solutions are colinear')
        return False
    l = 1
    flag4 = True
    while flag4 and l < len(solutions) - 1:
        l += 1
        if l == k:
            continue
        if not coplanar(np.array(solutions[0]), np.array(solutions[1]), np.array(solutions[k]), np.array(solutions[l])):
            flag4 = False
    if flag4:
        if open_out_flag:
            print('Solutions are coplanar')
        return False
    dual_hull = ConvexHull(solutions)
    dual_vertices = [dual_hull.points[_] for _ in dual_hull.vertices]
    skeleton_dual_hull = ConvexHull(dual_vertices)
    skeleton_dual_hull_facets = skeleton_dual_hull.simplices
    skeleton_dual_hull_vertices = skeleton_dual_hull.points
    if not interiorn(skeleton_dual_hull_vertices, skeleton_dual_hull_facets, np.array([0,0,0],dtype = object)):
        if open_out_flag:
            print('Origin not in the dual interior')
        return False
    return True

def checkn_non_primitive(vlist,open_out_flag=False):
    if len(vlist) <= 3:
        if open_out_flag:
            print('list too short')
        return False
    flag1 = True
    i = 1
    while flag1 and i < len(vlist)-1:
        i += 1
        if np.linalg.norm(cross(vlist[1] - vlist[0],vlist[i] - vlist[0])) > 10**(-7):
            flag1 = False
    if flag1:
        if open_out_flag:
            print('All vertices are colinear')
        return False
    flag2 = True
    j = 1
    while flag2 and j < len(vlist)-1:
        j += 1
        if j == i:
            continue
        if not coplanar(vlist[0],vlist[1],vlist[i],vlist[j]):
            flag2 = False
    if flag2:
        if open_out_flag:
            print('All vertices are coplanar')
        return False
    hull = ConvexHull(vlist)
    vertices = [hull.points[_] for _ in hull.vertices]
    skeleton_hull = ConvexHull(vertices)
    skeleton_hull_facets = skeleton_hull.simplices
    skeleton_hull_vertices = skeleton_hull.points
    if not interiorn(skeleton_hull_vertices, skeleton_hull_facets, np.array([0,0,0])):
        if open_out_flag:
            print('Origin not in the original interior')
        return False
    solutions = solve_lattice(vlist,6)
    if len(solutions) < 4:
        if open_out_flag:
            print('Solution list too short')
        return False
    k = 1
    flag3 = True
    while flag3 and k < len(solutions)-1:
        k += 1
        c = cross(solutions[1] - solutions[0], solutions[k] - solutions[0])
        if np.dot(c,c) > 10**(-14):
            flag3 = False
    if flag3:
        if open_out_flag:
            print('Solutions are colinear')
        return False
    l = 1
    flag4 = True
    while flag4 and l < len(solutions) - 1:
        l += 1
        if l == k:
            continue
        if not coplanar(np.array(solutions[0]), np.array(solutions[1]), np.array(solutions[k]), np.array(solutions[l])):
            flag4 = False
    if flag4:
        if open_out_flag:
            print('Solutions are coplanar')
        return False
    dual_hull = ConvexHull(solutions)
    dual_vertices = [dual_hull.points[_] for _ in dual_hull.vertices]
    skeleton_dual_hull = ConvexHull(dual_vertices)
    skeleton_dual_hull_facets = skeleton_dual_hull.simplices
    skeleton_dual_hull_vertices = skeleton_dual_hull.points
    if not interiorn(skeleton_dual_hull_vertices, skeleton_dual_hull_facets, np.array([0,0,0], dtype = object)):
        if open_out_flag:
            print('Origin not in the dual interior')
        return False
    return True
       
if __name__ == '__main__':
    print('----------test check.py----------')
    #test codes
    v1 = np.array([1,0,0], dtype = object)
    v2 = np.array([0,1,0], dtype = object)
    v3 = np.array([0,0,1], dtype = object)
    for k in range(516):
        v4 = np.array([-2,-3,-k], dtype = object)
        v=[v1, v2, v3, v4]
        print((k,checkn_non_primitive(v, open_out_flag = False)))
    print('----------test check.py end----------')